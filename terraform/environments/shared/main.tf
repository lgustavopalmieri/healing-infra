###############################################################################
# Backend — values come from the shared bootstrap output
###############################################################################

terraform {
  required_version = ">= 1.5"

  backend "s3" {
    bucket         = "REPLACE-WITH-BOOTSTRAP-OUTPUT-state_bucket_name"
    key            = "environments/shared/terraform.tfstate"
    region         = "REPLACE-WITH-BOOTSTRAP-OUTPUT-aws_region"
    dynamodb_table = "REPLACE-WITH-BOOTSTRAP-OUTPUT-lock_table_name"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

###############################################################################
# DNS — Route53 Hosted Zone (shared across all environments)
###############################################################################

module "dns" {
  source = "../../modules/dns"

  domain_name = var.domain_name
  tags        = var.tags
}
