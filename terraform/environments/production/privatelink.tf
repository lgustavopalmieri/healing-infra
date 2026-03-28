###############################################################################
# PrivateLink — Elastic Cloud
#
# The Elastic Cloud PrivateLink endpoint service may not support all AZs in
# the region. We query the service's supported AZs and use the statically-known
# AZ list to compute which subnet indices are compatible — this avoids
# for_each/count issues with unknown subnet IDs on first apply.
###############################################################################

data "aws_vpc_endpoint_service" "elastic" {
  service_name = var.elastic_privatelink_service_name
}

locals {
  # AZ list — must match the logic in modules/eks/locals.tf
  azs = length(var.availability_zones) > 0 ? var.availability_zones : [
    "${var.aws_region}a",
    "${var.aws_region}b",
    "${var.aws_region}c",
  ]

  elastic_supported_azs = toset(data.aws_vpc_endpoint_service.elastic.availability_zones)

  # Indices of AZs that the endpoint service supports
  elastic_supported_indices = [
    for i, az in local.azs : i
    if contains(local.elastic_supported_azs, az)
  ]
}

module "elastic_privatelink" {
  source = "../../modules/privatelink"

  project_name  = var.project_name
  environment   = var.environment
  service_label = "elastic"

  vpc_id     = module.eks.vpc_id
  subnet_ids = [for i in local.elastic_supported_indices : module.eks.private_subnet_ids[i]]
  vpc_cidr   = var.vpc_cidr

  service_name  = var.elastic_privatelink_service_name
  allowed_ports = [443, 9243]

  private_hosted_zone_domain = var.elastic_privatelink_phz_domain

  tags = var.tags
}
