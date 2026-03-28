###############################################################################
# DNS Module — Route53 Hosted Zone
###############################################################################

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

resource "aws_route53_zone" "this" {
  name = var.domain_name

  tags = merge(var.tags, {
    Name      = var.domain_name
    ManagedBy = "terraform"
  })
}
