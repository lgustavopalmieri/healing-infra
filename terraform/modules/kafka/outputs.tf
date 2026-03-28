###############################################################################
# Outputs
###############################################################################

output "cluster_id" {
  description = "Confluent Cloud Kafka cluster ID."
  value       = confluent_kafka_cluster.this.id
}

output "bootstrap_endpoint" {
  description = "Bootstrap endpoint for Kafka client connections."
  value       = confluent_kafka_cluster.this.bootstrap_endpoint
}

output "rest_endpoint" {
  description = "REST endpoint for the Kafka cluster."
  value       = confluent_kafka_cluster.this.rest_endpoint
}

output "app_api_key" {
  description = "Application API key ID (connection username)."
  value       = confluent_api_key.app.id
}

output "app_api_secret" {
  description = "Application API key secret (connection password)."
  value       = confluent_api_key.app.secret
  sensitive   = true
}

output "environment_id" {
  description = "Confluent Cloud environment ID."
  value       = confluent_environment.this.id
}

output "topic_name" {
  description = "Name of the default topic created."
  value       = confluent_kafka_topic.app.topic_name
}
