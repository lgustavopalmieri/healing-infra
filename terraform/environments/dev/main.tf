###############################################################################
# Backend — values come from the bootstrap output
#
# Fill in the actual values from: terraform -chdir=../../bootstrap/dev output
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
    ec = {
      source  = "elastic/ec"
      version = "~> 0.12"
    }
    elasticstack = {
      source  = "elastic/elasticstack"
      version = "~> 0.11"
    }
    confluent = {
      source  = "confluentinc/confluent"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    bucket         = "healing-dev-dev-terraform-state"
    key            = "environments/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "healing-dev-dev-terraform-locks"
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

provider "elasticstack" {
  elasticsearch {
    endpoints = [module.elasticsearch.elasticsearch_https_endpoint]
    username  = module.elasticsearch.elasticsearch_username
    password  = module.elasticsearch.elasticsearch_password
  }
}

provider "confluent" {
  cloud_api_key    = var.confluent_api_key
  cloud_api_secret = var.confluent_api_secret
}
