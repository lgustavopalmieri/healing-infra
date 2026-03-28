###############################################################################
# PrivateLink — Elastic Cloud
###############################################################################

module "elastic_privatelink" {
  source = "../../modules/privatelink"

  project_name  = var.project_name
  environment   = var.environment
  service_label = "elastic"

  vpc_id     = module.eks.vpc_id
  subnet_ids = module.eks.private_subnet_ids
  vpc_cidr   = var.vpc_cidr

  service_name  = var.elastic_privatelink_service_name
  allowed_ports = [443, 9243]

  private_hosted_zone_domain = var.elastic_privatelink_phz_domain

  tags = var.tags
}
