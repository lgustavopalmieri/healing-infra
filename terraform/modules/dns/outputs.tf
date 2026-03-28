###############################################################################
# DNS Module Outputs
###############################################################################

output "zone_id" {
  description = "Route53 hosted zone ID."
  value       = aws_route53_zone.this.zone_id
}

output "zone_arn" {
  description = "Route53 hosted zone ARN."
  value       = aws_route53_zone.this.arn
}

output "name_servers" {
  description = "Name servers for the hosted zone. Point your domain registrar to these."
  value       = aws_route53_zone.this.name_servers
}

output "domain_name" {
  description = "Domain name of the hosted zone."
  value       = aws_route53_zone.this.name
}
