###############################################################################
# Bootstrap — Production Environment
#
# Creates the S3 bucket and DynamoDB table for this environment's remote state.
# Uses LOCAL state on purpose — this is the bootstrap.
#
# Usage:
#   cp production.tfvars.example production.tfvars
#   terraform init
#   terraform apply -var-file=production.tfvars
#
# Then copy the outputs into environments/production/main.tf backend block.
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
