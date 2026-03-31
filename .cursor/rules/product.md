---
inclusion: always
---

# Product Overview

healing-infra is a Terraform-based infrastructure-as-code repository that provisions and manages the cloud infrastructure for a globally-scaled application platform. It also hosts Kubernetes manifests following GitOps practices — the repo is the single source of truth for cluster state.

## What it provisions

- AWS EKS clusters with managed node groups and ALB ingress
- VPC networking (public/private subnets, NAT gateways)
- ECR container registry with GitHub Actions OIDC for keyless CI/CD pushes
- Route53 DNS hosted zones and ALB alias records
- AWS OpenSearch domains (VPC-based) with IAM authentication for multi-tenant index isolation
- SQS workload identity: IRSA-based IAM roles with prefix-restricted SQS queue policies (apps create their own queues)
- RDS PostgreSQL in EKS VPC private subnets (not publicly accessible)
- AWS PrivateLink via a generic reusable module for private connectivity to external services
- S3 + DynamoDB remote state backends (bootstrap layer)
- Kubernetes manifests for application deployments (GitOps)

## Multi-tenant isolation (OpenSearch)

OpenSearch uses a 3-layer defense-in-depth model:
1. **VPC Security Group** — only traffic from within the VPC CIDR can reach port 443
2. **Domain Access Policy** — open within VPC; the SG is the network boundary
3. **IAM Identity Policies** — each pod's IAM role restricts access to specific index patterns via ARN (e.g. `healing-*`)

No opensearch-project/opensearch provider needed — all access control is pure AWS IAM.

## Environments

Four isolated environments, each with its own state and bootstrap:
- **shared** — cross-environment resources (Route53 hosted zone)
- **dev** — development / testing (same stack as production but lightweight, no custom DNS, easy to destroy)
- **staging** — pre-production (EKS + OpenSearch + SQS IAM + RDS PostgreSQL)
- **production** — live workloads (EKS + OpenSearch Multi-AZ + SQS IAM + RDS PostgreSQL)

## Deployment model

Bootstrap-first: each environment requires a one-time bootstrap (`terraform/bootstrap/<env>`) that creates the S3 state bucket and DynamoDB lock table. Environment configs then reference those outputs in their backend blocks.

Single `terraform apply` per environment — no phased applies needed.

Application deployments follow GitOps — manifests in `k8s/` are reconciled automatically to the cluster.
