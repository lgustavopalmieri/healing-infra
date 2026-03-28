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

# Elasticsearch
output "elasticsearch_endpoint" {
  value = module.elasticsearch.elasticsearch_https_endpoint
}

output "kibana_endpoint" {
  value = module.elasticsearch.kibana_https_endpoint
}

output "elasticsearch_app_user" {
  value = module.elasticsearch.app_user_name
}
