###############################################################################
# Bootstrap — Shared Environment
#
# Creates the S3 bucket and DynamoDB table for the shared layer's remote state.
# Uses LOCAL state on purpose — this is the bootstrap.
#
# Usage:
#   cp shared.tfvars.example shared.tfvars
#   terraform init
#   terraform apply -var-file=shared.tfvars
#
# Then copy the outputs into environments/shared/main.tf backend block.
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

provider "aws" {
  region = var.aws_region
}

module "backend" {
  source = "../../modules/backend"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  tags         = var.tags
}
