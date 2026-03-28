###############################################################################
# Outputs
###############################################################################

output "vpc_endpoint_id" {
  description = "VPC Endpoint ID. Pass to the target service module for traffic filter or access policy association."
  value       = aws_vpc_endpoint.this.id
}

output "vpc_endpoint_dns_name" {
  description = "Primary DNS name of the VPC Endpoint."
  value       = aws_vpc_endpoint.this.dns_entry[0]["dns_name"]
}

output "security_group_id" {
  description = "Security Group ID attached to the VPC Endpoint."
  value       = aws_security_group.this.id
}

output "private_hosted_zone_id" {
  description = "Private Hosted Zone ID (empty if PHZ was not created)."
  value       = var.private_hosted_zone_domain != "" ? aws_route53_zone.this[0].zone_id : ""
}
