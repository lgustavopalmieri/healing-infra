###############################################################################
# EKS Module
#
# Dev environment — no custom DNS. Access the ALB via the AWS-generated
# DNS name (*.elb.amazonaws.com). Lightweight config for fast spin-up/teardown.
###############################################################################

module "eks" {
  source = "../../modules/eks"

  project_name = var.project_name
  environment  = var.environment
  cluster_name = var.cluster_name
  aws_region   = var.aws_region

  # Networking
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  private_subnets    = var.private_subnets
  public_subnets     = var.public_subnets
  single_nat_gateway = var.single_nat_gateway

  # EKS
  kubernetes_version              = var.kubernetes_version
  cluster_deletion_protection     = var.cluster_deletion_protection
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

  # No DNS — dev uses the ALB's AWS-generated hostname
  zone_id     = ""
  dns_records = []

  tags = var.tags
}
