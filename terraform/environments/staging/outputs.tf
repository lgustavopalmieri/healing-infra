###############################################################################
# Environment outputs — exposes module values
###############################################################################

output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint."
  value       = module.eks.cluster_endpoint
}

output "ecr_repository_url" {
  description = "ECR repository URL for container images."
  value       = module.eks.ecr_repository_url
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC."
  value       = module.eks.github_actions_role_arn
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.eks.vpc_id
}

output "dns_records" {
  description = "DNS records created as aliases to the ALB."
  value       = module.eks.dns_records
}

# OpenSearch
output "opensearch_endpoint" {
  description = "OpenSearch domain endpoint."
  value       = module.opensearch.domain_endpoint
}

output "opensearch_dashboard_endpoint" {
  description = "OpenSearch Dashboards endpoint."
  value       = module.opensearch.dashboard_endpoint
}

# RDS PostgreSQL
output "rds_endpoint" {
  description = "RDS instance endpoint (host:port)."
  value       = module.rds_postgres.endpoint
}

output "rds_connection_endpoint" {
  description = "Recommended DB endpoint: proxy when enabled, otherwise direct RDS address."
  value       = module.rds_postgres.connection_endpoint
}

output "rds_proxy_endpoint" {
  description = "RDS Proxy endpoint (null when proxy is disabled)."
  value       = module.rds_postgres.proxy_endpoint
}

# SQS / Workload Identity
output "healing_specialist_role_arn" {
  description = "IAM role ARN for the healing specialist pod (annotate on K8s ServiceAccount)."
  value       = module.sqs_healing_specialist.iam_role_arn
}
