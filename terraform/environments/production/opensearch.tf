###############################################################################
# OpenSearch Module
#
# Production VPC-based OpenSearch domain: Multi-AZ (3 nodes, 3 AZs),
# IAM authentication, encryption at rest, node-to-node encryption,
# HTTPS enforcement. Index isolation via IAM policies on pod roles.
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
  availability_zone_count  = var.opensearch_availability_zone_count
  dedicated_master_enabled = var.opensearch_dedicated_master_enabled
  dedicated_master_type    = var.opensearch_dedicated_master_type
  dedicated_master_count   = var.opensearch_dedicated_master_count

  vpc_id     = module.eks.vpc_id
  subnet_ids = module.eks.private_subnet_ids
  vpc_cidr   = var.vpc_cidr

  create_service_linked_role = var.opensearch_create_service_linked_role

  tags = var.tags
}
