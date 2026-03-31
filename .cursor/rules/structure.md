---
inclusion: always
---

# Project Structure

```
terraform/
├── bootstrap/              # One-time state backend setup (local state)
│   ├── dev/
│   ├── staging/
│   ├── production/
│   └── shared/
├── environments/           # Root modules — one per environment
│   ├── dev/                # EKS + OpenSearch (VPC) + SQS (IAM) + RDS — lightweight, no custom DNS, easy teardown
│   ├── production/         # EKS + OpenSearch (VPC, Multi-AZ) + SQS (IAM) + RDS PostgreSQL
│   ├── staging/            # EKS + OpenSearch (VPC) + SQS (IAM) + RDS PostgreSQL
│   └── shared/             # DNS only (Route53 hosted zone)
└── modules/                # Reusable modules consumed by environments
    ├── backend/            # S3 bucket + DynamoDB lock table
    ├── dns/                # Route53 hosted zone
    ├── eks/                # VPC + EKS + ECR + ALB Controller + GitHub OIDC + DNS records
    ├── opensearch/         # AWS OpenSearch domain (VPC-based) + IAM auth + Security Group
    ├── privatelink/        # Generic VPC Interface Endpoint + SG + Private Hosted Zone (reusable for any service)
    ├── sqs/                # IRSA pod role + SQS IAM policy (prefix-restricted) + OpenSearch IAM policy (index-restricted)
    └── rds-postgres/       # RDS PostgreSQL in EKS VPC private subnets

k8s/                        # Kubernetes manifests (GitOps)
└── ...                     # Deployments, Services, Ingress, ConfigMaps, etc.
```

## File conventions per module/environment

| File | Purpose |
|---|---|
| `main.tf` | Primary resources, backend config (in roots), provider config (in roots) |
| `variables.tf` | All input variables with descriptions, types, defaults, and validations |
| `outputs.tf` | All outputs with descriptions |
| `locals.tf` | Computed locals (`name_prefix`, `common_tags`, `azs`) |
| `providers.tf` | `required_providers` block (modules only) |
| `versions.tf` | Alternative name for `providers.tf` in some modules |
| `opensearch.tf` | OpenSearch module call (in environment roots) |
| `sqs.tf` | SQS workload identity module calls (in environment roots) |
| `*.tfvars.example` | Example variable files — copy and fill, never commit actual `.tfvars` |

## Naming patterns

- Resource name prefix: `{project_name}-{environment}` (e.g. `myapp-staging`)
- All resources tagged with: `Project`, `Environment`, `ManagedBy = "terraform"`
- Bootstrap resources use `ManagedBy = "terraform-bootstrap"`
- IRSA pod roles: `{project}-{env}-{service}-pod-role` (e.g. `healing-dev-specialist-pod-role`)
- SQS queue prefix restriction: `{service}-*` (e.g. `specialist-*`)
- OpenSearch index prefix restriction: `{index_prefix}-*` (e.g. `healing-*`)

## State architecture

- Each environment has its own S3 backend with DynamoDB locking
- Shared environment outputs (e.g. `zone_id`) are consumed via `terraform_remote_state` data sources
- Bootstrap uses local state intentionally — it creates the remote backend itself

## Cross-environment data flow

`shared` environment → exposes `zone_id` output → consumed by `staging`/`production` via `terraform_remote_state` or direct `zone_id` variable override

## Deployment

Single `terraform apply` per environment — no phased applies, no `-target` flags needed. Everything deploys in one shot.
