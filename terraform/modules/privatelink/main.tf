###############################################################################
# Generic PrivateLink Module
#
# Creates an AWS VPC Interface Endpoint with a dedicated Security Group and
# an optional Private Hosted Zone + wildcard CNAME record. This module is
# service-agnostic — the caller provides the VPC Endpoint Service name,
# allowed ports, and (optionally) the PHZ domain.
#
# Usage examples:
#   - Elastic Cloud PrivateLink
#   - MSK (Kafka) PrivateLink (future)
#   - RDS PrivateLink (future)
#   - Any third-party service exposing an AWS PrivateLink endpoint
###############################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  resource_name = "${local.name_prefix}-${var.service_label}-pl"

  create_phz = var.private_hosted_zone_domain != ""

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

###############################################################################
# Security Group
###############################################################################

resource "aws_security_group" "this" {
  name_prefix = "${local.resource_name}-"
  description = "Allow VPC traffic to ${var.service_label} PrivateLink endpoint"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_ports
    content {
      description = "Port ${ingress.value} from VPC CIDR"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = local.resource_name
  })

  lifecycle {
    create_before_destroy = true
  }
}

###############################################################################
# VPC Interface Endpoint
###############################################################################

resource "aws_vpc_endpoint" "this" {
  vpc_id              = var.vpc_id
  service_name        = var.service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = false

  subnet_ids         = var.subnet_ids
  security_group_ids = [aws_security_group.this.id]

  tags = merge(local.common_tags, {
    Name = local.resource_name
  })
}

###############################################################################
# Private Hosted Zone + Wildcard CNAME
#
# When a PHZ domain is provided, creates a private zone associated with the
# VPC and a wildcard CNAME pointing to the VPC Endpoint's regional DNS name.
# This allows pods/instances to resolve service-specific domains (e.g.
# *.vpce.us-east-1.aws.elastic-cloud.com) to the private endpoint
# automatically — no application-level changes required.
###############################################################################

resource "aws_route53_zone" "this" {
  count = local.create_phz ? 1 : 0

  name = var.private_hosted_zone_domain

  vpc {
    vpc_id = var.vpc_id
  }

  tags = merge(local.common_tags, {
    Name = "${local.resource_name}-phz"
  })

  lifecycle {
    ignore_changes = [vpc]
  }
}

resource "aws_route53_record" "wildcard" {
  count = local.create_phz ? 1 : 0

  zone_id = aws_route53_zone.this[0].zone_id
  name    = "*"
  type    = "CNAME"
  ttl     = 300
  records = [aws_vpc_endpoint.this.dns_entry[0]["dns_name"]]
}
