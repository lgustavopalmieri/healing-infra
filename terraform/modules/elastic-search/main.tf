###############################################################################
# Elastic Cloud Deployment
###############################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

data "ec_stack" "latest" {
  version_regex = var.elasticsearch_version_regex
  region        = var.region
}

resource "ec_deployment" "this" {
  name                   = var.deployment_name
  region                 = var.region
  version                = data.ec_stack.latest.version
  deployment_template_id = var.deployment_template_id

  tags = local.common_tags

  elasticsearch = {
    hot = {
      size        = var.elasticsearch_size
      zone_count  = var.elasticsearch_zone_count
      autoscaling = {}
    }
  }

  kibana = {
    size       = var.kibana_size
    zone_count = var.elasticsearch_zone_count
  }
}

###############################################################################
# Application Role & User
###############################################################################

resource "elasticstack_elasticsearch_security_role" "app_role" {
  name = "${local.name_prefix}-app-role"

  indices {
    names      = var.app_indices
    privileges = ["read", "write", "create_index", "index", "view_index_metadata"]
  }

  cluster = ["monitor"]
}

resource "elasticstack_elasticsearch_security_user" "app_user" {
  username            = var.app_user_name
  password_wo         = var.app_user_password
  password_wo_version = var.app_user_password_version
  roles               = [elasticstack_elasticsearch_security_role.app_role.name]
  enabled             = true
}
