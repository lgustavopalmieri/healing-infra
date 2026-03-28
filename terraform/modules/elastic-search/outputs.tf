output "elasticsearch_https_endpoint" {
  description = "Endpoint HTTPS do Elasticsearch"
  value       = ec_deployment.this.elasticsearch.https_endpoint
}

output "elasticsearch_cloud_id" {
  description = "Cloud ID para configuração de clientes"
  value       = ec_deployment.this.elasticsearch.cloud_id
  sensitive   = true
}

output "kibana_https_endpoint" {
  description = "Endpoint HTTPS do Kibana"
  value       = ec_deployment.this.kibana.https_endpoint
}

output "elasticsearch_username" {
  description = "Usuário admin do Elasticsearch"
  value       = ec_deployment.this.elasticsearch_username
}

output "elasticsearch_password" {
  description = "Senha do usuário admin"
  value       = ec_deployment.this.elasticsearch_password
  sensitive   = true
}

output "app_user_name" {
  description = "Usuário de aplicação para conexão ao Elasticsearch"
  value       = elasticstack_elasticsearch_security_user.app_user.username
}

output "app_user_password" {
  description = "Senha do usuário de aplicação"
  value       = var.app_user_password
  sensitive   = true
}

output "deployment_id" {
  description = "ID do deployment"
  value       = ec_deployment.this.id
}

output "elasticsearch_version" {
  description = "Versão do Elasticsearch provisionada"
  value       = data.ec_stack.latest.version
}
