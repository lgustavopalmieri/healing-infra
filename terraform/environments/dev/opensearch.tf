###############################################################################
# OpenSearch Module
#
# VPC-based OpenSearch domain with IAM-only access control.
# Index isolation enforced via IAM policies on pod roles (SQS module).
# Dev uses a single small node to save cost.
###############################################################################

module "opensearch" {
  source = "../../modules/opensearch"

  project_name = var.project_name
  environment  = var.environment

  engine_version           = var.opensearch_engine_version
  instance_type            = var.opensearch_instance_type
  instance_count           = var.opensearch_instance_count
  ebs_volume_size          = var.opensearch_ebs_volume_size
  ebs_volume_type          = var.opensearch_ebs_volume_type
  zone_awareness_enabled   = var.opensearch_zone_awareness_enabled
  dedicated_master_enabled = var.opensearch_dedicated_master_enabled

  vpc_id     = module.eks.vpc_id
  subnet_ids = module.eks.private_subnet_ids
  vpc_cidr   = var.vpc_cidr

  create_service_linked_role = var.opensearch_create_service_linked_role

  tags = var.tags
}
