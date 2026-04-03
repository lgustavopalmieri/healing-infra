###############################################################################
# Backend — values come from the bootstrap output
#
# Fill in the actual values from: terraform -chdir=../../bootstrap/staging output
# These cannot be variables — Terraform requires literal values in backend blocks.
###############################################################################

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }

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

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.aws_region]
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.aws_region]
    }
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
