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

variable "project_name" {
  description = "Project name."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "tags" {
  description = "Additional tags."
  type        = map(string)
  default     = {}
}

module "backend" {
  source = "../../modules/backend"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  tags         = var.tags
}

output "state_bucket_name" {
  value = module.backend.state_bucket_name
}

output "lock_table_name" {
  value = module.backend.lock_table_name
}

output "aws_region" {
  value = var.aws_region
}
