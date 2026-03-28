data "ec_stack" "latest" {
  version_regex = var.elasticsearch_version_regex
  region        = var.region
}

resource "ec_deployment" "this" {
  name                   = var.deployment_name
  region                 = var.region
  version                = data.ec_stack.latest.version
  deployment_template_id = var.deployment_template_id

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

# Role com permissões de leitura/escrita para as aplicações
resource "elasticstack_elasticsearch_security_role" "app_role" {
  name = "app_role"

  indices {
    names      = var.app_indices
    privileges = ["read", "write", "create_index", "index", "view_index_metadata"]
  }

  cluster = ["monitor"]
}

# Usuário dedicado para as aplicações
resource "elasticstack_elasticsearch_security_user" "app_user" {
  username            = var.app_user_name
  password_wo         = var.app_user_password
  password_wo_version = var.app_user_password_version
  roles               = [elasticstack_elasticsearch_security_role.app_role.name]
  enabled             = true
}
