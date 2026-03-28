###############################################################################
# Confluent Cloud Kafka
#
# Creates a Confluent Cloud environment, Kafka cluster, service account with
# ACLs, API keys, and a default topic. The module preserves all original
# resources (environment, cluster, service account, role binding, admin and
# app API keys, ACLs for create/delete/produce/consume/group, and a topic).
#
# PrivateLink note: Confluent Cloud PrivateLink is only available for
# "dedicated" clusters. When upgrading to dedicated, add the PrivateLink
# network + access resources and wire the VPC Endpoint from the privatelink
# module in the environment root.
###############################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

###############################################################################
# Environment
###############################################################################

resource "confluent_environment" "this" {
  display_name = var.environment_name
}

###############################################################################
# Kafka Cluster
###############################################################################

resource "confluent_kafka_cluster" "this" {
  display_name = var.cluster_name
  availability = "SINGLE_ZONE"
  cloud        = var.cloud_provider
  region       = var.region

  dynamic "basic" {
    for_each = var.cluster_type == "basic" ? [1] : []
    content {}
  }

  dynamic "standard" {
    for_each = var.cluster_type == "standard" ? [1] : []
    content {}
  }

  dynamic "dedicated" {
    for_each = var.cluster_type == "dedicated" ? [1] : []
    content {
      cku = 1
    }
  }

  environment {
    id = confluent_environment.this.id
  }
}

###############################################################################
# Service Account
###############################################################################

resource "confluent_service_account" "app" {
  display_name = var.app_service_account_name
  description  = "Service account for application access to Kafka"
}

resource "confluent_role_binding" "app_cluster_admin" {
  principal   = "User:${confluent_service_account.app.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.this.rbac_crn
}

###############################################################################
# API Keys
###############################################################################

# Admin API key — used by Terraform to manage topics and ACLs
resource "confluent_api_key" "admin" {
  display_name = "${local.name_prefix}-admin-api-key"
  description  = "Admin API key for cluster management"

  owner {
    id          = confluent_service_account.app.id
    api_version = confluent_service_account.app.api_version
    kind        = confluent_service_account.app.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.this.id
    api_version = confluent_kafka_cluster.this.api_version
    kind        = confluent_kafka_cluster.this.kind

    environment {
      id = confluent_environment.this.id
    }
  }

  depends_on = [confluent_role_binding.app_cluster_admin]
}

# Application API key — credentials delivered to applications
resource "confluent_api_key" "app" {
  display_name = "${local.name_prefix}-app-api-key"
  description  = "Application API key for ${var.app_service_account_name}"

  owner {
    id          = confluent_service_account.app.id
    api_version = confluent_service_account.app.api_version
    kind        = confluent_service_account.app.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.this.id
    api_version = confluent_kafka_cluster.this.api_version
    kind        = confluent_kafka_cluster.this.kind

    environment {
      id = confluent_environment.this.id
    }
  }
}

###############################################################################
# ACLs — Topic operations
###############################################################################

resource "confluent_kafka_acl" "app_create_topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.this.id
  }

  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app.id}"
  host          = "*"
  operation     = "CREATE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.this.rest_endpoint

  credentials {
    key    = confluent_api_key.admin.id
    secret = confluent_api_key.admin.secret
  }
}

resource "confluent_kafka_acl" "app_delete_topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.this.id
  }

  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app.id}"
  host          = "*"
  operation     = "DELETE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.this.rest_endpoint

  credentials {
    key    = confluent_api_key.admin.id
    secret = confluent_api_key.admin.secret
  }
}

resource "confluent_kafka_acl" "app_producer" {
  kafka_cluster {
    id = confluent_kafka_cluster.this.id
  }

  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.this.rest_endpoint

  credentials {
    key    = confluent_api_key.admin.id
    secret = confluent_api_key.admin.secret
  }
}

resource "confluent_kafka_acl" "app_consumer" {
  kafka_cluster {
    id = confluent_kafka_cluster.this.id
  }

  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.this.rest_endpoint

  credentials {
    key    = confluent_api_key.admin.id
    secret = confluent_api_key.admin.secret
  }
}

###############################################################################
# ACLs — Consumer groups
###############################################################################

resource "confluent_kafka_acl" "app_group" {
  kafka_cluster {
    id = confluent_kafka_cluster.this.id
  }

  resource_type = "GROUP"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.this.rest_endpoint

  credentials {
    key    = confluent_api_key.admin.id
    secret = confluent_api_key.admin.secret
  }
}

###############################################################################
# Default Topic
###############################################################################

resource "confluent_kafka_topic" "app" {
  kafka_cluster {
    id = confluent_kafka_cluster.this.id
  }

  topic_name       = var.app_topic_name
  partitions_count = var.app_topic_partitions
  rest_endpoint    = confluent_kafka_cluster.this.rest_endpoint

  credentials {
    key    = confluent_api_key.admin.id
    secret = confluent_api_key.admin.secret
  }
}
