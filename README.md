# healing-infra

Production-grade infrastructure powering the Healing platform at global scale — built on AWS with Terraform, EKS, and GitOps. This repo is the single source of truth: it provisions cloud resources (networking, compute, messaging, storage, observability) via IaC and reconciles application state to Kubernetes through declarative manifests, enabling fully automated, auditable deployments across multiple environments.

## What gets provisioned

| Layer | Resources |
|---|---|
| Networking | VPC, public/private subnets, NAT Gateway |
| Compute | EKS (managed node groups) + ALB Ingress Controller |
| Container Registry | ECR with GitHub Actions OIDC (keyless push) |
| DNS | Route53 hosted zone + ALB alias records |
| Search | Elastic Cloud (Elasticsearch + Kibana) with per-app RBAC |
| Messaging | Kafka / MSK *(coming soon)* |
| Database | RDS PostgreSQL *(coming soon)* |
| State backend | S3 + DynamoDB (locking) per environment |

## Repository structure

```
terraform/
├── bootstrap/          # One-time state backend setup (S3 + DynamoDB)
│   ├── shared/
│   ├── release/
│   └── production/
├── environments/       # Root modules — one per environment
│   ├── shared/         # Shared resources (Route53)
│   ├── release/        # Pre-production
│   └── production/     # Production
└── modules/            # Reusable modules
    ├── backend/        # S3 + DynamoDB
    ├── dns/            # Route53
    ├── eks/            # VPC + EKS + ECR + ALB + OIDC + DNS
    ├── elastic-search/ # Elastic Cloud + app user
    ├── kafka/          # MSK (coming soon)
    └── rds-postgres/   # RDS PostgreSQL (coming soon)

k8s/                    # Kubernetes manifests (GitOps)
└── ...                 # Deployments, Services, Ingress, ConfigMaps, etc.
```

## Environments

- **shared** — cross-environment resources (DNS hosted zone)
- **release** — staging / pre-production
- **production** — live workloads

## GitOps

Kubernetes manifests live in `k8s/` and represent the desired state of applications in the cluster. Changes merged to the main branch are automatically reconciled — no manual `kubectl apply`.

## Quick start

```bash
# 1. Bootstrap the state backend (once per environment)
cp terraform/bootstrap/<env>/<env>.tfvars.example terraform/bootstrap/<env>/<env>.tfvars
terraform -chdir=terraform/bootstrap/<env> init
terraform -chdir=terraform/bootstrap/<env> apply -var-file=<env>.tfvars

# 2. Update the backend block in environments/<env>/main.tf with bootstrap outputs

# 3. Apply the environment
cp terraform/environments/<env>/<env>.tfvars.example terraform/environments/<env>/<env>.tfvars
terraform -chdir=terraform/environments/<env> init
terraform -chdir=terraform/environments/<env> apply -var-file=<env>.tfvars
```

## Tech stack

- Terraform >= 1.5
- AWS Provider ~> 6.0 | Helm ~> 3.0 | Kubernetes ~> 2.0
- Elastic Cloud (ec ~> 0.12, elasticstack ~> 0.11)
- Community modules: `terraform-aws-modules/eks/aws`, `vpc/aws`, `iam/aws`

## Conventions

- Naming: `{project}-{environment}` (e.g. `myapp-release`)
- Required tags: `Project`, `Environment`, `ManagedBy`
- Sensitive values are never committed — `.tfvars` is in `.gitignore`
- Remote state with encryption enabled and DynamoDB locking
