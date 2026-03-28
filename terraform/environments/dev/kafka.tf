###############################################################################
# Kafka Module (Confluent Cloud)
###############################################################################

module "kafka" {
  source = "../../modules/kafka"

  project_name = var.project_name
  environment  = var.environment

  environment_name         = var.kafka_environment_name
  cluster_name             = var.kafka_cluster_name
  cloud_provider           = var.kafka_cloud_provider
  region                   = var.kafka_region
  cluster_type             = var.kafka_cluster_type
  app_service_account_name = var.kafka_app_service_account_name
  app_topic_name           = var.kafka_app_topic_name
  app_topic_partitions     = var.kafka_app_topic_partitions
}
