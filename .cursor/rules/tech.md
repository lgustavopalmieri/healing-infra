---
inclusion: always
---

# Tech Stack

## Core tooling

- **Terraform** >= 1.5 (HCL)
- **AWS Provider** ~> 6.0
- **Helm Provider** ~> 3.0
- **Kubernetes Provider** ~> 2.0
- **Elastic Cloud Provider** (elastic/ec) ~> 0.12
- **Elasticstack Provider** (elastic/elasticstack) ~> 0.11
- **Confluent Cloud Provider** (confluentinc/confluent) ~> 2.0

## Key community modules

- `terraform-aws-modules/eks/aws` v21.15.1
- `terraform-aws-modules/vpc/aws` v6.6.0
- `terraform-aws-modules/iam/aws` ~> 5.0 (IRSA)

## AWS services used

EKS, VPC, ECR, S3, DynamoDB, Route53, IAM (OIDC), ALB (via AWS LB Controller Helm chart v1.12.0), RDS PostgreSQL

## External services

- Elastic Cloud (Elasticsearch + Kibana) — connected via AWS PrivateLink
- Confluent Cloud (Kafka) — basic cluster over public internet (PrivateLink requires dedicated tier)

## Common commands

```bash
# Bootstrap (run once per environment)
cp terraform/bootstrap/<env>/<env>.tfvars.example terraform/bootstrap/<env>/<env>.tfvars
terraform -chdir=terraform/bootstrap/<env> init
terraform -chdir=terraform/bootstrap/<env> apply -var-file=<env>.tfvars

# Environment apply
cp terraform/environments/<env>/<env>.tfvars.example terraform/environments/<env>/<env>.tfvars
# Update backend block in main.tf with bootstrap outputs first
terraform -chdir=terraform/environments/<env> init
terraform -chdir=terraform/environments/<env> plan -var-file=<env>.tfvars
terraform -chdir=terraform/environments/<env> apply -var-file=<env>.tfvars
```

## Conventions

- Terraform version constraint: `>= 1.5` in all modules and roots
- Provider configuration is the caller's responsibility — modules only declare `required_providers`
- Sensitive values use `sensitive = true` and are never committed (`.tfvars` in `.gitignore`)
- State encryption enabled (`encrypt = true` in all S3 backends)
- All content (comments, docs, READMEs, commit messages) must be written in English
