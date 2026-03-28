###############################################################################
# PrivateLink — Elastic Cloud
#
# Creates a VPC Interface Endpoint in the EKS VPC so that pods reach
# Elastic Cloud over the AWS backbone (PrivateLink) instead of the
# public internet. The VPC Endpoint ID is passed to the elasticsearch
# module which creates the traffic filter on the Elastic Cloud side.
#
# depends_on is not needed here — Terraform resolves the implicit
# dependency through module.eks.vpc_id / module.eks.private_subnet_ids.
###############################################################################

module "elastic_privatelink" {
  source = "../../modules/privatelink"

  project_name  = var.project_name
  environment   = var.environment
  service_label = "elastic"

  # Networking — comes from the EKS module which owns the VPC
  vpc_id     = module.eks.vpc_id
  subnet_ids = module.eks.private_subnet_ids
  vpc_cidr   = var.vpc_cidr

  # Elastic Cloud PrivateLink endpoint service
  service_name = var.elastic_privatelink_service_name

  # Elasticsearch (443) + Kibana/transport (9243)
  allowed_ports = [443, 9243]

  # Private Hosted Zone so pods resolve *.vpce.<region>.aws.elastic-cloud.com
  # to the VPC Endpoint ENIs automatically — no app-level changes needed
  private_hosted_zone_domain = var.elastic_privatelink_phz_domain

  tags = var.tags
}
