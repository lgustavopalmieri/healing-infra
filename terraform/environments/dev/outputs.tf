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

output "rds_address" {
  description = "RDS instance hostname (without port)."
  value       = module.rds_postgres.address
}

output "rds_port" {
  description = "RDS instance port."
  value       = module.rds_postgres.port
}

output "rds_db_name" {
  description = "Name of the default database."
  value       = module.rds_postgres.db_name
}

output "rds_username" {
  description = "Master database username."
  value       = module.rds_postgres.username
}

# SQS / Workload Identity
output "healing_specialist_role_arn" {
  description = "IAM role ARN for the healing specialist pod (annotate on K8s ServiceAccount)."
  value       = module.sqs_healing_specialist.iam_role_arn
}

output "healing_specialist_role_name" {
  description = "IAM role name for the healing specialist pod."
  value       = module.sqs_healing_specialist.iam_role_name
}

output "healing_specialist_sqs_policy_arn" {
  description = "ARN of the SQS IAM policy (prefix-restricted queue management)."
  value       = module.sqs_healing_specialist.sqs_policy_arn
}

output "healing_specialist_opensearch_policy_arn" {
  description = "ARN of the OpenSearch IAM policy (index-restricted access)."
  value       = module.sqs_healing_specialist.opensearch_policy_arn
}
