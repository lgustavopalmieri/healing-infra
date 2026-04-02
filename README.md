# healing-infra

Production-grade infrastructure for the Healing platform — built on AWS with Terraform, EKS, and GitOps.

## What gets provisioned

| Layer | Resources |
|---|---|
| Networking | VPC, public/private subnets, NAT Gateway |
| Compute | EKS (managed node groups) + ALB Ingress Controller |
| Container Registry | ECR with GitHub Actions OIDC (keyless push) |
| DNS | Route53 hosted zone + ALB alias records |
| Search | AWS OpenSearch (VPC-based, IAM auth, index-level isolation) |
| Messaging | SQS via IRSA (pods create their own queues, prefix-restricted IAM) |
| Database | RDS PostgreSQL (VPC private subnets, not publicly accessible) |
| Connection Pooling | RDS Proxy (optional per environment — reduces connection overhead under load) |
| Secrets | AWS Secrets Manager (stores RDS credentials for the proxy) |
| State backend | S3 + DynamoDB (locking) per environment |

## Multi-tenant index isolation

OpenSearch uses IAM-based index isolation — no FGAC provider needed:

1. **Network**: VPC Security Group allows only traffic from within the VPC on port 443
2. **Domain policy**: Open within VPC (SG is the network boundary)
3. **IAM policies**: Each pod's IAM role restricts access to specific index patterns via ARN (e.g. `healing-*`)

Each new service gets its own SQS module with a unique `opensearch_index_prefix`, guaranteeing it can only access its own indices.

## Environments

| Environment | Purpose | DNS | Designed for |
|---|---|---|---|
| shared | Route53 hosted zone shared by staging and production | Custom domain | Always running |
| dev | Full stack, lightweight config, no custom DNS | ALB hostname | Spin up / tear down quickly |
| staging | Pre-production, RDS Proxy enabled | Custom subdomain | Always running |
| production | Live workloads (Multi-AZ, RDS Proxy, deletion protection) | Custom domain | Always running |

## Repository structure

```
terraform/
├── bootstrap/          # Step 1: state backend (S3 + DynamoDB) — run once per env
│   ├── shared/
│   ├── dev/
│   ├── staging/
│   └── production/
├── environments/       # Step 2/3: actual infrastructure
│   ├── shared/         # Step 2: DNS hosted zone (needed by staging + production)
│   ├── dev/            # Step 3: EKS + OpenSearch + SQS IAM + RDS (no DNS dependency)
│   ├── staging/        # Step 3: EKS + OpenSearch + SQS IAM + RDS
│   └── production/     # Step 3: EKS + OpenSearch (Multi-AZ) + SQS IAM + RDS
└── modules/            # Reusable modules (never applied directly)
    ├── backend/        # S3 bucket + DynamoDB lock table
    ├── dns/            # Route53 hosted zone
    ├── eks/            # VPC + EKS + ECR + ALB Controller + GitHub OIDC
    ├── opensearch/     # AWS OpenSearch domain (VPC-based) + IAM auth + SG
    ├── sqs/            # IRSA pod role + SQS IAM policy + OpenSearch IAM policy (index-restricted)
    ├── rds-postgres/   # RDS PostgreSQL + optional RDS Proxy (connection pooling, Secrets Manager, IAM)
    └── privatelink/    # Generic VPC Interface Endpoint + SG + Private Hosted Zone

k8s/                    # Kubernetes manifests (GitOps)
```

---

## How to deploy — step by step

There are 3 steps, and the order matters. Read this section fully before running anything.

### Understanding the dependency order

```
Step 1: Bootstrap (creates S3 + DynamoDB for remote state)
   ↓
Step 2: Shared environment (creates the Route53 hosted zone)
   ↓
Step 3: Service environments (dev, staging, production)
```

- Step 1 must run before anything else — it creates the state backend.
- Step 2 (shared) is only needed if you want custom DNS (staging, production). Dev does not need it.
- Step 3 environments are independent of each other. You can deploy dev without staging or production.

> **About the shared environment (Step 2):**
> The shared environment only creates a Route53 hosted zone for custom DNS (e.g. `healing.com`).
> It is required only by staging and production — they read the `zone_id` from shared's state to create DNS records like `api.healing.com` or `api.staging.healing.com`.
> **Dev does not need shared at all.** It uses the ALB's AWS-generated hostname directly. If you just want to spin up a dev environment, skip Step 2 entirely and go straight to Step 3.

### Step 1 — Bootstrap the state backend

Each environment needs its own bootstrap. This creates the S3 bucket and DynamoDB table that Terraform uses to store state remotely. You run this once per environment and never touch it again.

```bash
# Pick your environment: dev, shared, staging, or production
ENV=dev

cp terraform/bootstrap/$ENV/$ENV.tfvars.example terraform/bootstrap/$ENV/$ENV.tfvars
# Edit the .tfvars file with your values

terraform -chdir=terraform/bootstrap/$ENV init
terraform -chdir=terraform/bootstrap/$ENV apply -var-file=$ENV.tfvars
```

Save the outputs — you need them for the next step:

```bash
terraform -chdir=terraform/bootstrap/$ENV output
```

### Step 2 — Deploy the shared environment (DNS)

This step creates the Route53 hosted zone that staging and production use for custom domains. Skip this if you only need dev.

```bash
# Bootstrap shared first (Step 1 above), then:

cp terraform/environments/shared/shared.tfvars.example terraform/environments/shared/shared.tfvars
# Edit shared.tfvars with your domain name

# Update the backend block in terraform/environments/shared/main.tf
# with the outputs from Step 1 (bucket name, region, DynamoDB table)

terraform -chdir=terraform/environments/shared init
terraform -chdir=terraform/environments/shared apply -var-file=shared.tfvars
```

After this, point your domain's nameservers (at your registrar) to the Route53 nameservers shown in the output.

### Step 3 — Deploy a service environment (dev, staging, or production)

Each service environment provisions the full stack in a **single `terraform apply`** — no phases, no targets.

```bash
# Pick your environment
ENV=dev

# Make sure you ran Step 1 (bootstrap) for this environment first

cp terraform/environments/$ENV/$ENV.tfvars.example terraform/environments/$ENV/terraform.tfvars
# Edit terraform.tfvars — fill in ECR repo name, GitHub org, passwords, etc.

# Update the backend block in terraform/environments/$ENV/main.tf
# with the outputs from Step 1 (bucket name, region, DynamoDB table)

terraform -chdir=terraform/environments/$ENV init
terraform -chdir=terraform/environments/$ENV apply
```

For staging and production: if you want custom DNS, make sure Step 2 (shared) is done first, and set `shared_state_bucket` in your tfvars to the shared environment's S3 bucket name.

For dev: no shared dependency needed. The ALB gets an AWS-generated hostname automatically.

> **Timing**: First apply takes ~25 minutes (EKS ~10 min + OpenSearch ~15 min, in parallel). Subsequent applies are incremental and fast.

### Get all outputs

```bash
terraform -chdir=terraform/environments/$ENV output -json
```

### Tearing down an environment

```bash
terraform -chdir=terraform/environments/$ENV destroy
```

Dev is designed for this — `skip_final_snapshot = true`, `ecr_force_delete = true`, minimal resources. Staging and production have safeguards (Multi-AZ, final snapshots) that you should review before destroying.

> **Important**: Before running `terraform destroy`, always delete Kubernetes Ingress resources first (`kubectl delete ingress --all -n healing`) — the ALB created by the Load Balancer Controller is **outside Terraform** and will block VPC deletion. The RDS Proxy, however, is fully Terraform-managed and needs no manual cleanup. See the [destroy guide](docs/dev-destroy-guide.md) for details.

### Quick reference — what to deploy for each scenario

| I want to... | Bootstrap | Shared | Environment |
|---|---|---|---|
| Test and develop locally | dev | No | dev |
| Set up staging with custom DNS | shared + staging | Yes | staging |
| Go to production | shared + production | Yes | production |
| Full stack (all environments) | shared + dev + staging + production | Yes | dev, staging, production |

---

## Connecting your application

After deploy, create a Kubernetes ServiceAccount with IRSA to give your pod access to SQS and OpenSearch:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: healing-specialist
  namespace: healing
  annotations:
    eks.amazonaws.com/role-arn: "<healing_specialist_role_arn from terraform output>"
```

Then reference it in your Deployment:

```yaml
spec:
  template:
    spec:
      serviceAccountName: healing-specialist
```

The AWS SDK automatically picks up IRSA credentials. No access keys needed.

**What the pod can do:**
- **SQS**: Create/manage/send/receive queues matching `specialist-*`
- **OpenSearch**: HTTP access restricted to `healing-*` indices only
- **Cluster-level**: Read-only cluster health checks

### Connecting to the database

When RDS Proxy is enabled (`rds_enable_proxy = true`), applications should use the `rds_connection_endpoint` output as the database host:

```bash
terraform -chdir=terraform/environments/$ENV output rds_connection_endpoint
```

This output automatically resolves to the proxy endpoint when the proxy is enabled, or to the direct RDS address when it's disabled. The proxy handles connection pooling, reducing connection overhead during high-throughput workloads. TLS is required by default (`rds_proxy_require_tls = true`).

---

## Tech stack

- Terraform >= 1.5
- AWS Provider ~> 6.0 | Helm ~> 3.0 | Kubernetes ~> 2.0
- Community modules: `terraform-aws-modules/eks/aws`, `vpc/aws`, `iam/aws`

## Conventions

- Naming: `{project}-{environment}` (e.g. `healing-dev`)
- Required tags: `Project`, `Environment`, `ManagedBy`
- Sensitive values are never committed — `.tfvars` is in `.gitignore`
- Remote state with encryption enabled and DynamoDB locking
- All services (OpenSearch, RDS) deployed inside the EKS VPC for low-latency communication

## GitOps

Kubernetes manifests live in `k8s/` and represent the desired state of applications in the cluster. Changes merged to the main branch are automatically reconciled.

## Detailed guides

- [Dev environment deployment guide](docs/dev-deployment-guide.md) — step-by-step with troubleshooting
- [Dev environment destroy guide](docs/dev-destroy-guide.md) — safe teardown without orphaned resources
