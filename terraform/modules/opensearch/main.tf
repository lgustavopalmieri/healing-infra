###############################################################################
# AWS OpenSearch Domain
#
# Creates a VPC-based OpenSearch domain with IAM authentication, encryption
# at rest, node-to-node encryption, and HTTPS enforcement. The domain lives
# in the EKS VPC private subnets for low-latency pod-to-cluster communication.
#
# Multi-tenant index isolation is handled via IAM policies on caller roles
# (e.g. the SQS module restricts each pod to its own index prefix).
# No opensearch-project/opensearch provider is needed — everything is
# managed via the AWS provider, so a single `terraform apply` works.
###############################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  domain_name = var.domain_name != "" ? var.domain_name : "${var.project_name}-${var.environment}"

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

###############################################################################
# Service-Linked Role (one per account)
###############################################################################

resource "aws_iam_service_linked_role" "opensearch" {
  count            = var.create_service_linked_role ? 1 : 0
  aws_service_name = "opensearchservice.amazonaws.com"
}

###############################################################################
# Security Group
###############################################################################

resource "aws_security_group" "opensearch" {
  name_prefix = "${local.name_prefix}-opensearch-"
  description = "Allow HTTPS from VPC to OpenSearch domain"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-opensearch"
  })

  lifecycle {
    create_before_destroy = true
  }
}

###############################################################################
# OpenSearch Domain
###############################################################################

resource "aws_opensearch_domain" "this" {
  domain_name    = local.domain_name
  engine_version = var.engine_version

  cluster_config {
    instance_type          = var.instance_type
    instance_count         = var.instance_count
    zone_awareness_enabled = var.zone_awareness_enabled

    dynamic "zone_awareness_config" {
      for_each = var.zone_awareness_enabled ? [1] : []
      content {
        availability_zone_count = var.availability_zone_count
      }
    }

    dedicated_master_enabled = var.dedicated_master_enabled
    dedicated_master_type    = var.dedicated_master_enabled ? var.dedicated_master_type : null
    dedicated_master_count   = var.dedicated_master_enabled ? var.dedicated_master_count : null
  }

  vpc_options {
    subnet_ids         = var.zone_awareness_enabled ? slice(var.subnet_ids, 0, var.availability_zone_count) : [var.subnet_ids[0]]
    security_group_ids = [aws_security_group.opensearch.id]
  }

  ebs_options {
    ebs_enabled = true
    volume_type = var.ebs_volume_type
    volume_size = var.ebs_volume_size
  }

  encrypt_at_rest {
    enabled    = true
    kms_key_id = var.kms_key_id
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "es:ESHttp*"
        Resource = "arn:aws:es:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:domain/${local.domain_name}/*"
      }
    ]
  })

  dynamic "log_publishing_options" {
    for_each = var.log_publishing_options
    content {
      cloudwatch_log_group_arn = log_publishing_options.value.cloudwatch_log_group_arn
      log_type                 = log_publishing_options.value.log_type
    }
  }

  tags = merge(local.common_tags, {
    Name = local.domain_name
  })

  depends_on = [aws_iam_service_linked_role.opensearch]
}
