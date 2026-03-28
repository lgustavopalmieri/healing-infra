# healing-infra

Production-grade infrastructure for the Healing platform — built on AWS with Terraform, EKS, and GitOps.

## What gets provisioned

| Layer | Resources | Connectivity |
|---|---|---|
| Networking | VPC, public/private subnets, NAT Gateway | — |
| Compute | EKS (managed node groups) + ALB Ingress Controller | — |
| Container Registry | ECR with GitHub Actions OIDC (keyless push) | — |
| DNS | Route53 hosted zone + ALB alias records | — |
| Search | Elastic Cloud (Elasticsearch + Kibana) with per-app RBAC | AWS PrivateLink |
| Messaging | Confluent Cloud Kafka with service accounts + ACLs | Public (TLS/SASL); PrivateLink when dedicated |
| Database | RDS PostgreSQL | VPC private subnets (not publicly accessible) |
| PrivateLink | Generic reusable module for VPC Endpoints + PHZ | — |
| State backend | S3 + DynamoDB (locking) per environment | — |

## Environments

| Environment | Purpose | DNS | Designed for |
|---|---|---|---|
| shared | Route53 hosted zone shared by release and production | Custom domain | Always running |
| dev | Full stack, lightweight config, no custom DNS | ALB hostname | Spin up / tear down quickly |
| release | Pre-production / staging | Custom subdomain | Always running |
| production | Live workloads | Custom domain | Always running |

## Repository structure

```
terraform/
├── bootstrap/          # Step 1: state backend (S3 + DynamoDB) — run once per env
│   ├── shared/
│   ├── dev/
│   ├── release/
│   └── production/
├── environments/       # Step 2/3: actual infrastructure — run after bootstrap
│   ├── shared/         # Step 2: DNS hosted zone (needed by release + production)
│   ├── dev/            # Step 3: EKS + Elastic + Kafka + RDS (no DNS dependency)
│   ├── release/        # Step 3: EKS + Elastic + Kafka + RDS
│   └── production/     # Step 3: EKS + Elastic + Kafka + RDS
└── modules/            # Reusable modules (never applied directly)
    ├── backend/
    ├── dns/
    ├── eks/
    ├── elastic-search/
    ├── privatelink/
    ├── kafka/
    └── rds-postgres/

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
Step 3: Service environments (dev, release, production)
```

- Step 1 must run before anything else — it creates the state backend.
- Step 2 (shared) is only needed if you want custom DNS (release, production). Dev does not need it.
- Step 3 environments are independent of each other. You can deploy dev without release or production.

> **About the shared environment (Step 2):**
> The shared environment only creates a Route53 hosted zone for custom DNS (e.g. `healing.com`).
> It is required only by release and production — they read the `zone_id` from shared's state to create DNS records like `api.healing.com` or `api.release.healing.com`.
> **Dev does not need shared at all.** It uses the ALB's AWS-generated hostname directly. If you just want to spin up a dev environment, skip Step 2 entirely and go straight to Step 3.

### Step 1 — Bootstrap the state backend

Each environment needs its own bootstrap. This creates the S3 bucket and DynamoDB table that Terraform uses to store state remotely. You run this once per environment and never touch it again.

```bash
# Pick your environment: dev, shared, release, or production
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

This step creates the Route53 hosted zone that release and production use for custom domains. Skip this if you only need dev.

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

### Step 3 — Deploy a service environment (dev, release, or production)

Each service environment provisions the full stack: EKS + Elasticsearch + Kafka + RDS.

```bash
# Pick your environment
ENV=dev

# Make sure you ran Step 1 (bootstrap) for this environment first

cp terraform/environments/$ENV/$ENV.tfvars.example terraform/environments/$ENV/$ENV.tfvars
# Edit the .tfvars file — fill in API keys, passwords, and config

# Update the backend block in terraform/environments/$ENV/main.tf
# with the outputs from Step 1 (bucket name, region, DynamoDB table)

terraform -chdir=terraform/environments/$ENV init
terraform -chdir=terraform/environments/$ENV apply -var-file=$ENV.tfvars
```

For release and production: if you want custom DNS, make sure Step 2 (shared) is done first, and set `shared_state_bucket` in your .tfvars to the shared environment's S3 bucket name.

For dev: no shared dependency needed. The ALB gets an AWS-generated hostname automatically.

### Tearing down an environment

```bash
ENV=dev

terraform -chdir=terraform/environments/$ENV destroy -var-file=$ENV.tfvars
```

Dev is designed for this — `skip_final_snapshot = true`, `ecr_force_delete = true`, minimal resources. Release and production have safeguards (Multi-AZ, final snapshots) that you should review before destroying.

### Quick reference — what to deploy for each scenario

| I want to... | Bootstrap | Shared | Environment |
|---|---|---|---|
| Test and develop locally | dev | No | dev |
| Set up staging with custom DNS | shared + release | Yes | release |
| Go to production | shared + production | Yes | production |
| Full stack (all environments) | shared + dev + release + production | Yes | dev, release, production |

---

## Tech stack

- Terraform >= 1.5
- AWS Provider ~> 6.0 | Helm ~> 3.0 | Kubernetes ~> 2.0
- Elastic Cloud (ec ~> 0.12, elasticstack ~> 0.11)
- Confluent Cloud (confluentinc/confluent ~> 2.0)
- Community modules: `terraform-aws-modules/eks/aws`, `vpc/aws`, `iam/aws`

## Conventions

- Naming: `{project}-{environment}` (e.g. `myapp-dev`)
- Required tags: `Project`, `Environment`, `ManagedBy`
- Sensitive values are never committed — `.tfvars` is in `.gitignore`
- Remote state with encryption enabled and DynamoDB locking
- External services use AWS PrivateLink when supported by the provider

## GitOps

Kubernetes manifests live in `k8s/` and represent the desired state of applications in the cluster. Changes merged to the main branch are automatically reconciled.
