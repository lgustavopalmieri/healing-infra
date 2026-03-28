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
- Elastic Cloud deployments (Elasticsearch + Kibana) with application-level RBAC users and PrivateLink connectivity
- Confluent Cloud Kafka clusters with service accounts, ACLs, and default topics (basic cluster; PrivateLink available when upgrading to dedicated)
- RDS PostgreSQL in EKS VPC private subnets (not publicly accessible)
- AWS PrivateLink via a generic reusable module for private connectivity to external services
- S3 + DynamoDB remote state backends (bootstrap layer)
- Kubernetes manifests for application deployments (GitOps)

## Environments

Four isolated environments, each with its own state and bootstrap:
- **shared** — cross-environment resources (Route53 hosted zone)
- **dev** — development / testing (same stack as production but lightweight, no custom DNS, easy to destroy)
- **staging** — pre-production / staging (EKS + Elasticsearch via PrivateLink + Kafka basic + RDS PostgreSQL)
- **production** — live workloads (EKS + Elasticsearch via PrivateLink + Kafka basic + RDS PostgreSQL)

## Deployment model

Bootstrap-first: each environment requires a one-time bootstrap (`terraform/bootstrap/<env>`) that creates the S3 state bucket and DynamoDB lock table. Environment configs then reference those outputs in their backend blocks.

Application deployments follow GitOps — manifests in `k8s/` are reconciled automatically to the cluster.
