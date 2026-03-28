---
inclusion: always
---

# PrivateLink Connectivity Standard

Every managed service consumed by EKS workloads that lives outside the VPC (Elastic Cloud, Confluent Cloud Kafka, or any future external service) must be connected via AWS PrivateLink. Public internet access to these services is not acceptable in any environment.

Services that live inside the EKS VPC (e.g. RDS PostgreSQL) do not need PrivateLink — they are already reachable over the private network.

## Current status

- **Elastic Cloud**: PrivateLink active in dev, staging and production
- **Confluent Cloud Kafka**: currently using basic cluster (public internet + TLS/SASL). PrivateLink requires upgrading to dedicated tier
- **RDS PostgreSQL**: inside the VPC, private subnets only — no PrivateLink needed

## Why

- Traffic stays on the AWS backbone — never exposed to the public internet
- Latency between pods and the service stays in the 1–5ms range (same region, same AZ can be sub-2ms)
- Reduces attack surface — the service endpoint is only reachable from within the VPC
- Consistent pattern across all services — one generic module, multiple instances

## How it works

The connectivity is split into two sides:

1. **AWS side** (`modules/privatelink`): a generic, reusable module that creates a VPC Interface Endpoint, a dedicated Security Group, and an optional Private Hosted Zone with a wildcard CNAME record. It receives `vpc_id`, `subnet_ids`, `vpc_cidr`, `service_name`, `allowed_ports`, and optionally `private_hosted_zone_domain` from the caller.

2. **Service side** (e.g. `modules/elastic-search`): the service-specific module receives the `vpc_endpoint_id` output from the privatelink module and creates the appropriate traffic filter or access policy on the service provider's side (e.g. `ec_deployment_traffic_filter` for Elastic Cloud).

## Rules for adding a new service

When introducing any new managed service that EKS pods need to reach:

1. **Never place PrivateLink resources inside the EKS module.** The EKS module owns the VPC and exposes `vpc_id`, `private_subnet_ids`, and `vpc_cidr`. It must not know about Elastic, Kafka, RDS, or any other service.

2. **Always use `modules/privatelink`** to create the VPC Endpoint. Instantiate it in the environment root (e.g. `environments/production/privatelink.tf`) with a unique `service_label` per service.

3. **Pass the `vpc_endpoint_id`** from the privatelink module to the service-specific module so it can create the traffic filter or access policy on the provider side.

4. **Always create a Private Hosted Zone** when the service provider documents one (Elastic Cloud, Confluent Cloud, etc.). This enables automatic DNS resolution from pods to the private endpoint — no application code changes needed.

5. **Restrict Security Group ports** to only what the service requires. For example: Elastic Cloud uses 443 + 9243, Kafka typically uses 9092 + 9094, RDS PostgreSQL uses 5432.

6. **Same region is mandatory.** The Elastic Cloud deployment (or Confluent Cloud cluster, or RDS instance) must be in the same AWS region as the EKS cluster. Cross-region PrivateLink adds latency and complexity.

7. **Span all AZs.** Place the VPC Endpoint in all private subnets (all AZs) to maximize throughput and resilience. The `modules/privatelink` module already does this by accepting the full `subnet_ids` list.

8. **Environment variables go in `.tfvars`.** The `service_name` and `private_hosted_zone_domain` are region-specific values provided by the service vendor. They belong in the `.tfvars` file, not hardcoded in modules.

## Dependency chain

Terraform resolves this implicitly through output references — no `depends_on` needed:

```
module.eks (VPC + subnets)
  → module.<service>_privatelink (VPC Endpoint + SG + PHZ)
    → module.<service> (traffic filter / access policy)
```

## Example: adding Kafka (Confluent Cloud) in the future

```hcl
# environments/production/privatelink.tf

module "kafka_privatelink" {
  source = "../../modules/privatelink"

  project_name  = var.project_name
  environment   = var.environment
  service_label = "kafka"

  vpc_id     = module.eks.vpc_id
  subnet_ids = module.eks.private_subnet_ids
  vpc_cidr   = var.vpc_cidr

  service_name  = var.kafka_privatelink_service_name
  allowed_ports = [9092, 9094]

  private_hosted_zone_domain = var.kafka_privatelink_phz_domain

  tags = var.tags
}
```

Then pass `module.kafka_privatelink.vpc_endpoint_id` to the Kafka module for network policy association.
