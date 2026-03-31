###############################################################################
# Environment outputs — exposes module values
###############################################################################

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "ecr_repository_url" {
  value = module.eks.ecr_repository_url
}

output "github_actions_role_arn" {
  value = module.eks.github_actions_role_arn
}

output "vpc_id" {
  value = module.eks.vpc_id
}

output "dns_records" {
  value = module.eks.dns_records
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

# SQS / Workload Identity
output "healing_specialist_role_arn" {
  description = "IAM role ARN for the healing specialist pod (annotate on K8s ServiceAccount)."
  value       = module.sqs_healing_specialist.iam_role_arn
}
