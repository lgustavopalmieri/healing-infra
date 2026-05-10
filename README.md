# healing-infra

Infrastructure-as-Code for the **Healing** platform on AWS — VPC, EKS, ECR, OpenSearch, RDS PostgreSQL (+ optional RDS Proxy), per-service SQS with IRSA, and an in-cluster observability stack (OpenTelemetry Collector + Prometheus + Grafana).

This repo provisions the cloud foundations only; application code lives elsewhere. The Kubernetes manifests under `k8s/` are applied to the cluster with `kubectl`/`bash` scripts — there is no ArgoCD or Flux reconciler wired up today.

---

## What gets provisioned

| Layer | Resources |
|---|---|
| Networking | VPC, 3 public / 3 private subnets, NAT Gateway (single in dev) |
| Compute | EKS managed node group + AWS Load Balancer Controller (via Helm) |
| Container registry | ECR with GitHub Actions OIDC (keyless `docker push`) |
| DNS (optional) | Route53 hosted zone + ALB alias records — only in the `shared` env |
| Search | OpenSearch domain (VPC-only, IAM auth, index-prefix isolation per service) |
| Messaging | Per-service SQS queues via IRSA, prefix-restricted IAM |
| Database | RDS PostgreSQL (VPC-private, not publicly accessible) |
| Connection pooling | RDS Proxy (optional, toggled per env) + Secrets Manager |
| State backend | S3 bucket + DynamoDB lock table per environment |

## Multi-tenant index isolation

OpenSearch uses IAM-based isolation, not the fine-grained access control (FGAC) plugin:

1. **Network** — the VPC Security Group only permits port 443 from inside the VPC CIDR.
2. **Domain policy** — permissive inside the VPC; the SG is the network boundary.
3. **Per-pod IAM** — each pod's IRSA role is restricted by resource ARN to a specific index prefix (e.g. `healing-*`).

New services are onboarded by adding another `module "sqs_<service>"` block with a unique `opensearch_index_prefix`; they inherit their own pod role, their own SQS prefix, and their own index prefix.

---

## Environments

Only two environments exist in the repo today. `staging` and `production` are intentional future slots — the layout supports them, but there's no code for them yet.

| Environment | Status | Purpose | DNS |
|---|---|---|---|
| `shared` | Implemented | Route53 hosted zone used by any env that wants a custom domain | Custom domain |
| `dev`    | Implemented | Full stack, lightweight config, fast spin-up / teardown | ALB hostname (no DNS) |
| `staging` | Not in repo | Planned — would enable RDS Proxy + custom subdomain | Custom subdomain |
| `production` | Not in repo | Planned — Multi-AZ, deletion protection, final snapshots | Custom domain |

---

## Repository structure

```
terraform/
├── bootstrap/              # Step 1: state backend (S3 + DynamoDB) — run once per env
│   ├── shared/
│   └── dev/
├── environments/           # Steps 2–3: actual infrastructure, composes modules
│   ├── shared/             # Step 2: DNS hosted zone (needed only for custom DNS)
│   └── dev/                # Step 3: EKS + OpenSearch + SQS IAM + RDS (no DNS)
└── modules/                # Reusable modules — never applied directly
    ├── backend/            # S3 state bucket + DynamoDB lock table
    ├── dns/                # Route53 hosted zone
    ├── eks/                # VPC + EKS + ECR + ALB Controller + GitHub OIDC
    ├── opensearch/         # OpenSearch domain (VPC-only) + IAM auth + SG
    ├── rds-postgres/       # RDS + optional RDS Proxy + Secrets Manager + IAM
    ├── sqs/                # IRSA pod role + per-service SQS IAM + OpenSearch IAM (index-restricted)
    ├── privatelink/        # Reusable VPC Interface Endpoint + SG + Private Hosted Zone (not wired into any env yet)
    └── service-irsa/       # Placeholder for a future shared IRSA helper (empty)

k8s/                        # Kubernetes manifests applied via kubectl + bash scripts
├── observability/          # OTel Collector, Prometheus, Grafana, kube-state-metrics
│   ├── dashboards/         # Grafana dashboards (one .json per dashboard)
│   ├── apply.sh
│   └── destroy.sh
└── specialist/             # Reference app (healing-specialist) manifest + apply/destroy/check-cluster scripts

k8s.example/                # Reference copies of k8s/ — copy from here when bootstrapping a new cluster

docs/                       # Deep-dive guides (deployment, destroy, observability, OTel wiring)
```

> `modules/privatelink/` and `modules/service-irsa/` exist in the tree but are not currently consumed by `environments/dev/` or `environments/shared/`. Keep them in mind when extending, but don't treat them as part of the live stack.

---

## How to deploy — step by step

The order matters. Read this section fully before running anything.

### Dependency order

```
Step 1: Bootstrap (creates S3 + DynamoDB for remote state)
   ↓
Step 2: Shared environment (creates the Route53 hosted zone — optional, only if you want custom DNS)
   ↓
Step 3: Service environment (dev today; staging/production would slot in here)
```

- Step 1 runs first — it's the state backend.
- Step 2 is only needed for custom DNS. `dev` doesn't use it and takes the ALB's AWS-generated hostname.
- Step 3 deploys the full service stack in a single `terraform apply` — no phases, no `-target`.

> **About the shared environment:** it only creates a Route53 hosted zone (e.g. `healing.com`). Consumers read `zone_id` from its remote state and create DNS records like `api.healing.com`. **Dev does not need shared at all.**

### Step 1 — Bootstrap the state backend

Each env has its own bootstrap. Run this once, never touch it again. It uses local state on purpose (no backend in a backend).

```bash
# Only dev and shared exist today
ENV=dev

cp terraform/bootstrap/$ENV/$ENV.tfvars.example terraform/bootstrap/$ENV/$ENV.tfvars
# Edit the .tfvars file with your values

terraform -chdir=terraform/bootstrap/$ENV init
terraform -chdir=terraform/bootstrap/$ENV apply -var-file=$ENV.tfvars
terraform -chdir=terraform/bootstrap/$ENV output
```

The `output` values (bucket name, region, DynamoDB table) must be pasted into the `backend "s3"` block of the matching `terraform/environments/$ENV/main.tf` — Terraform disallows variables inside `backend` blocks.

### Step 2 — Deploy the shared environment (only for custom DNS)

Skip this if you only need dev.

```bash
# Bootstrap shared first (Step 1 with ENV=shared), then:

cp terraform/environments/shared/shared.tfvars.example terraform/environments/shared/shared.tfvars
# Edit shared.tfvars with your domain name

# Update the backend block in terraform/environments/shared/main.tf
# with the outputs from Step 1 (bucket name, region, DynamoDB table)

terraform -chdir=terraform/environments/shared init
terraform -chdir=terraform/environments/shared apply -var-file=shared.tfvars
```

After this, point your domain's nameservers (at your registrar) to the Route53 NS records in the output.

### Step 3 — Deploy a service environment

Today that means `dev`.

```bash
ENV=dev

# Make sure you ran Step 1 (bootstrap) for this environment first

cp terraform/environments/$ENV/$ENV.tfvars.example terraform/environments/$ENV/terraform.tfvars
# Edit terraform.tfvars — fill in ECR repo, GitHub org, RDS password, etc.

# Update the backend block in terraform/environments/$ENV/main.tf
# with the outputs from Step 1

terraform -chdir=terraform/environments/$ENV init
terraform -chdir=terraform/environments/$ENV apply
```

> **Timing**: first apply takes ~25 minutes (EKS ~10 min and OpenSearch ~15 min, created in parallel). Subsequent applies are incremental.

### Get all outputs

```bash
terraform -chdir=terraform/environments/$ENV output -json
```

### Tearing down an environment

```bash
terraform -chdir=terraform/environments/$ENV destroy
```

`dev` is tuned for this — `skip_final_snapshot = true`, `ecr_force_delete = true`, single-AZ RDS, single NAT.

> **Before `terraform destroy`**, delete Kubernetes Ingress resources and tear down the observability stack. The ALBs that the Load Balancer Controller creates are **outside Terraform** and will block VPC deletion:
>
> ```bash
> kubectl delete ingress --all -n healing
> kubectl delete ingress --all -n observability
> bash k8s/observability/destroy.sh
> ```
>
> The RDS Proxy is fully Terraform-managed and needs no manual cleanup. See [docs/dev-destroy-guide.md](docs/dev-destroy-guide.md).

### What to run for each scenario

| Goal | Bootstrap | Shared | Environment |
|---|---|---|---|
| Bring up dev | dev | No | dev |
| Add custom DNS you can reuse later | shared | Yes | — |

---

## Connecting an application (IRSA)

After `terraform apply`, grab the pod role ARN and create a ServiceAccount:

```bash
POD_ROLE_ARN=$(terraform -chdir=terraform/environments/dev output -raw healing_specialist_role_arn)

kubectl create namespace healing --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: healing-specialist
  namespace: healing
  annotations:
    eks.amazonaws.com/role-arn: ${POD_ROLE_ARN}
EOF
```

Reference it in the pod spec (`serviceAccountName: healing-specialist`) and the AWS SDK picks up temporary credentials automatically.

**What the `healing-specialist` pod role can do:**
- **SQS** — create / manage / send / receive queues matching `specialist-*`
- **OpenSearch** — HTTP access restricted by ARN to `healing-*` indices
- **Cluster** — read-only (`_cluster/health`, `_cat`)

A reference deployment and scripts are under `k8s/specialist/`:

```bash
bash k8s/specialist/apply.sh          # kubectl apply of the manifest
bash k8s/specialist/check-cluster.sh  # sanity check
bash k8s/specialist/destroy.sh        # kubectl delete
```

### Connecting to the database

Use the `rds_connection_endpoint` output as the DB host. It resolves to the proxy endpoint when `rds_enable_proxy = true` and to the direct RDS address otherwise:

```bash
terraform -chdir=terraform/environments/dev output rds_connection_endpoint
```

TLS is required by default (`rds_proxy_require_tls = true`). Don't relax it outside dev.

---

## Observability

An in-cluster stack lives under `k8s/observability/`. It runs in its own `observability` namespace on its own ALB group (`healing-observability`), separate from application traffic.

| Component | Purpose |
|---|---|
| OpenTelemetry Collector | Receives OTLP metrics from apps, exports Prometheus format |
| Prometheus | Scrapes kube-state-metrics, cAdvisor, and the OTel Collector |
| Grafana | Dashboards for the cluster and the applications |
| kube-state-metrics | Pod count, deployment status, etc. |

### Deploy / destroy

```bash
# Deploy (after kubectl is pointed at the target cluster)
bash k8s/observability/apply.sh

# Tear down
bash k8s/observability/destroy.sh
```

Grafana is exposed at `http://<OBSERVABILITY_ALB>/grafana`.

### Add a Grafana dashboard

Drop a `.json` file into `k8s/observability/dashboards/` and re-run `apply.sh`. The `grafana-dashboards` ConfigMap is rebuilt from the whole folder on every apply.

### Wire an application up

Add to your app's ConfigMap:

```yaml
OTEL_EXPORTER_OTLP_ENDPOINT: "http://otel-collector.observability.svc.cluster.local:4318"
OTEL_EXPORTER_OTLP_PROTOCOL: "http/protobuf"
OTEL_SERVICE_NAME: "<your-service-name>"
OTEL_RESOURCE_ATTRIBUTES: "deployment.environment=dev"
```

Full details in [docs/app-otel-config.md](docs/app-otel-config.md).

---

## Tech stack

- Terraform `>= 1.5`
- AWS provider `~> 6.0`, Helm `~> 3.0`, Kubernetes `~> 2.0`
- Community modules: `terraform-aws-modules/eks/aws` (v21.x), `vpc/aws`, `iam/aws`
- EKS `1.35` by default, OpenSearch `2.17` by default

## Conventions

- **Naming**: `{project}-{environment}` (e.g. `healing-dev`), centralized in each module's `locals.tf` as `name_prefix`.
- **Required tags**: `Project`, `Environment`, `ManagedBy = "terraform"` — merged via `local.common_tags`.
- **Provider pinning**: `~>` minor constraints, no unpinned `latest`.
- **Validation**: prefer `validation { condition = ... }` blocks on variables (see `ecr_image_tag_mutability`).
- **Secrets**: `.tfvars` files are gitignored. RDS credentials live in Secrets Manager and are read by the proxy.
- **State**: remote S3 with SSE + DynamoDB locking, one backend per environment.
- **VPC-only data plane**: OpenSearch and RDS live in the same VPC as EKS for low-latency access — no public endpoints.

## Detailed guides

- [Dev environment deployment guide](docs/dev-deployment-guide.md)
- [Dev environment destroy guide](docs/dev-destroy-guide.md)
- [Observability action plan](docs/observability-action-plan.md)
- [Application OTel configuration](docs/app-otel-config.md)
