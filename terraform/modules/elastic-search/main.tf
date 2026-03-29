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

  depends_on = [
    ec_deployment_traffic_filter_association.privatelink,
    ec_deployment_traffic_filter_association.terraform_ip,
  ]
}

resource "elasticstack_elasticsearch_security_user" "app_user" {
  username            = var.app_user_name
  password_wo         = var.app_user_password
  password_wo_version = var.app_user_password_version
  roles               = [elasticstack_elasticsearch_security_role.app_role.name]
  enabled             = true
}

###############################################################################
# PrivateLink Traffic Filter
#
# When a VPC Endpoint ID is provided, creates a traffic filter rule that
# restricts the Elastic Cloud deployment to accept connections only from
# the specified VPC Endpoint (AWS PrivateLink). This ensures all traffic
# stays on the AWS backbone and never traverses the public internet.
#
# Reference: https://www.elastic.co/guide/en/cloud/current/ec-traffic-filtering-vpc.html
###############################################################################

locals {
  enable_privatelink    = var.enable_privatelink
  privatelink_region    = var.privatelink_region != "" ? var.privatelink_region : var.region
}

resource "ec_deployment_traffic_filter" "privatelink" {
  count = local.enable_privatelink ? 1 : 0

  name   = "${local.name_prefix}-privatelink"
  region = local.privatelink_region
  type   = "vpce"

  rule {
    source = var.vpc_endpoint_id
  }
}

resource "ec_deployment_traffic_filter_association" "privatelink" {
  count = local.enable_privatelink ? 1 : 0

  traffic_filter_id = ec_deployment_traffic_filter.privatelink[0].id
  deployment_id     = ec_deployment.this.id
}

###############################################################################
# IP-based Traffic Filter (Terraform / CI access)
#
# Allows the Terraform runner (local machine or CI) to reach the Elasticsearch
# API over the public internet even when a PrivateLink filter is active.
# Each CIDR in var.terraform_allowed_ips becomes a rule inside a single filter.
###############################################################################

resource "ec_deployment_traffic_filter" "terraform_ip" {
  count = length(var.terraform_allowed_ips) > 0 ? 1 : 0

  name   = "${local.name_prefix}-terraform-ip"
  region = var.region
  type   = "ip"

  dynamic "rule" {
    for_each = var.terraform_allowed_ips
    content {
      source = rule.value
    }
  }
}

resource "ec_deployment_traffic_filter_association" "terraform_ip" {
  count = length(var.terraform_allowed_ips) > 0 ? 1 : 0

  traffic_filter_id = ec_deployment_traffic_filter.terraform_ip[0].id
  deployment_id     = ec_deployment.this.id
}
