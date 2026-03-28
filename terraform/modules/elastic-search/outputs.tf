###############################################################################
# Outputs
###############################################################################

output "elasticsearch_https_endpoint" {
  description = "Elasticsearch HTTPS endpoint."
  value       = ec_deployment.this.elasticsearch.https_endpoint
}

output "elasticsearch_cloud_id" {
  description = "Cloud ID for client configuration."
  value       = ec_deployment.this.elasticsearch.cloud_id
  sensitive   = true
}

output "kibana_https_endpoint" {
  description = "Kibana HTTPS endpoint."
  value       = ec_deployment.this.kibana.https_endpoint
}

output "elasticsearch_username" {
  description = "Elasticsearch admin username."
  value       = ec_deployment.this.elasticsearch_username
}

output "elasticsearch_password" {
  description = "Elasticsearch admin password."
  value       = ec_deployment.this.elasticsearch_password
  sensitive   = true
}

output "app_user_name" {
  description = "Application user for Elasticsearch connections."
  value       = elasticstack_elasticsearch_security_user.app_user.username
}

output "deployment_id" {
  description = "Elastic Cloud deployment ID."
  value       = ec_deployment.this.id
}

output "elasticsearch_version" {
  description = "Provisioned Elasticsearch version."
  value       = data.ec_stack.latest.version
}

output "traffic_filter_id" {
  description = "PrivateLink traffic filter ID (empty if PrivateLink is not enabled)."
  value       = var.vpc_endpoint_id != "" ? ec_deployment_traffic_filter.privatelink[0].id : ""
}
