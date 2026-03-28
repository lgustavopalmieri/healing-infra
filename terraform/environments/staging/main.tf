###############################################################################
# Backend — values come from the bootstrap output
#
# Fill in the actual values from: terraform -chdir=../../bootstrap/staging output
# These cannot be variables — Terraform requires literal values in backend blocks.
###############################################################################

terraform {
  required_version = ">= 1.5"

  backend "s3" {
    bucket         = "REPLACE-WITH-BOOTSTRAP-OUTPUT-state_bucket_name"
    key            = "environments/staging/terraform.tfstate"
    region         = "REPLACE-WITH-BOOTSTRAP-OUTPUT-aws_region"
    dynamodb_table = "REPLACE-WITH-BOOTSTRAP-OUTPUT-lock_table_name"
    encrypt        = true
  }
}

###############################################################################
# Providers
###############################################################################

provider "aws" {
  region = var.aws_region
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

provider "ec" {
  apikey = var.ec_api_key
}

provider "confluent" {
  cloud_api_key    = var.confluent_api_key
  cloud_api_secret = var.confluent_api_secret
}

provider "elasticstack" {
  elasticsearch {
    endpoints = [module.elasticsearch.elasticsearch_https_endpoint]
    username  = module.elasticsearch.elasticsearch_username
    password  = module.elasticsearch.elasticsearch_password
  }
}

###############################################################################
# Remote State — shared layer (Route53 hosted zone)
###############################################################################

data "terraform_remote_state" "shared" {
  count   = var.zone_id != "" ? 0 : (var.shared_state_bucket != "" ? 1 : 0)
  backend = "s3"

  config = {
    bucket = var.shared_state_bucket
    key    = "environments/shared/terraform.tfstate"
    region = var.aws_region
  }
}

locals {
  zone_id = var.zone_id != "" ? var.zone_id : try(data.terraform_remote_state.shared[0].outputs.zone_id, "")
}
