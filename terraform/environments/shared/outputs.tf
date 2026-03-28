###############################################################################
# Shared environment outputs
###############################################################################

output "zone_id" {
  description = "Route53 hosted zone ID. Used by per-environment DNS records."
  value       = module.dns.zone_id
}

output "name_servers" {
  description = "Name servers — point your domain registrar to these."
  value       = module.dns.name_servers
}

output "domain_name" {
  description = "Domain name of the hosted zone."
  value       = module.dns.domain_name
}
