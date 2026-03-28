###############################################################################
# Backend — values come from the bootstrap output
#
# Fill in the actual values from: terraform -chdir=../../../bootstrap output
# These cannot be variables — Terraform requires literal values in backend blocks.
###############################################################################

terraform {
  required_version = ">= 1.5"

  backend "s3" {
    bucket         = "REPLACE-WITH-BOOTSTRAP-OUTPUT-state_bucket_name"
    key            = "environments/release/terraform.tfstate"
    region         = "REPLACE-WITH-BOOTSTRAP-OUTPUT-aws_region"
    dynamodb_table = "REPLACE-WITH-BOOTSTRAP-OUTPUT-lock_table_name"
    encrypt        = true
  }
}

###############################################################################
# Providers — configured here, implicitly passed to the module
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

###############################################################################
# EKS Module
###############################################################################

module "eks" {
  source = "../../modules/eks"

  project_name = var.project_name
  environment  = var.environment
  cluster_name = var.cluster_name
  aws_region   = var.aws_region

  # Networking
  vpc_cidr           = var.vpc_cidr
  private_subnets    = var.private_subnets
  public_subnets     = var.public_subnets
  single_nat_gateway = var.single_nat_gateway

  # EKS
  kubernetes_version              = var.kubernetes_version
  node_instance_types             = var.node_instance_types
  node_min_size                   = var.node_min_size
  node_max_size                   = var.node_max_size
  node_desired_size               = var.node_desired_size
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = var.cluster_endpoint_private_access

  # ECR
  ecr_repository_name = var.ecr_repository_name
  ecr_force_delete    = var.ecr_force_delete

  # GitHub OIDC
  github_org   = var.github_org
  github_repos = var.github_repos

  tags = var.tags
}
