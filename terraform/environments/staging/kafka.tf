###############################################################################
# Kafka Module (Confluent Cloud)
#
# PrivateLink note: Confluent Cloud PrivateLink requires "dedicated" clusters.
# The current setup uses basic/standard clusters. When upgrading to dedicated,
# add a kafka_privatelink module instance in privatelink.tf and configure the
# Confluent Cloud network + PrivateLink access resources.
###############################################################################

module "kafka" {
  source = "../../modules/kafka"

  project_name = var.project_name
  environment  = var.environment

  # Confluent Cloud
  environment_name         = var.kafka_environment_name
  cluster_name             = var.kafka_cluster_name
  cloud_provider           = var.kafka_cloud_provider
  region                   = var.kafka_region
  cluster_type             = var.kafka_cluster_type
  app_service_account_name = var.kafka_app_service_account_name
  app_topic_name           = var.kafka_app_topic_name
  app_topic_partitions     = var.kafka_app_topic_partitions
}
