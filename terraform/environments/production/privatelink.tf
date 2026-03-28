###############################################################################
# PrivateLink — Elastic Cloud
#
# Creates a VPC Interface Endpoint in the EKS VPC so that pods reach
# Elastic Cloud over the AWS backbone (PrivateLink) instead of the
# public internet. The VPC Endpoint ID is passed to the elasticsearch
# module which creates the traffic filter on the Elastic Cloud side.
#
# The Elastic Cloud PrivateLink endpoint service may not support all AZs in
# the region. We query the service's supported AZs and filter the VPC private
# subnets to only those in compatible AZs, avoiding CreateVpcEndpoint errors.
###############################################################################

data "aws_vpc_endpoint_service" "elastic" {
  service_name = var.elastic_privatelink_service_name
}

data "aws_subnet" "private" {
  for_each = toset(module.eks.private_subnet_ids)
  id       = each.value
}

locals {
  elastic_supported_azs = toset(data.aws_vpc_endpoint_service.elastic.availability_zones)

  elastic_privatelink_subnet_ids = [
    for id, s in data.aws_subnet.private : id
    if contains(local.elastic_supported_azs, s.availability_zone)
  ]
}

module "elastic_privatelink" {
  source = "../../modules/privatelink"

  project_name  = var.project_name
  environment   = var.environment
  service_label = "elastic"

  vpc_id     = module.eks.vpc_id
  subnet_ids = local.elastic_privatelink_subnet_ids
  vpc_cidr   = var.vpc_cidr

  service_name  = var.elastic_privatelink_service_name
  allowed_ports = [443, 9243]

  private_hosted_zone_domain = var.elastic_privatelink_phz_domain

  tags = var.tags
}
