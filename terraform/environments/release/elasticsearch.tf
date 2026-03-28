###############################################################################
# Elasticsearch Module
###############################################################################

module "elasticsearch" {
  source = "../../modules/elastic-search"

  project_name = var.project_name
  environment  = var.environment

  # Elastic Cloud
  region                      = var.es_region
  deployment_name             = var.es_deployment_name
  deployment_template_id      = var.es_deployment_template_id
  elasticsearch_version_regex = var.es_version_regex
  elasticsearch_size          = var.es_size
  elasticsearch_zone_count    = var.es_zone_count
  kibana_size                 = var.es_kibana_size

  # Application user
  app_user_name             = var.es_app_user_name
  app_user_password         = var.es_app_user_password
  app_user_password_version = var.es_app_user_password_version
  app_indices               = var.es_app_indices

  tags = var.tags
}
