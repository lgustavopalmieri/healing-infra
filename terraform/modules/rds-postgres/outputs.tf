###############################################################################
# Outputs — RDS Instance
###############################################################################

output "endpoint" {
  description = "RDS instance endpoint (host:port)."
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "RDS instance hostname."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "RDS instance port."
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Name of the default database."
  value       = aws_db_instance.this.db_name
}

output "username" {
  description = "Master database username."
  value       = aws_db_instance.this.username
}

output "security_group_id" {
  description = "Security Group ID attached to the RDS instance."
  value       = aws_security_group.rds.id
}

output "identifier" {
  description = "RDS instance identifier."
  value       = aws_db_instance.this.identifier
}

###############################################################################
# Outputs — RDS Proxy (only populated when enable_proxy = true)
###############################################################################

output "proxy_endpoint" {
  description = "RDS Proxy endpoint. Applications should connect here instead of the RDS instance directly."
  value       = var.enable_proxy ? aws_db_proxy.this[0].endpoint : null
}

output "proxy_arn" {
  description = "ARN of the RDS Proxy."
  value       = var.enable_proxy ? aws_db_proxy.this[0].arn : null
}

output "proxy_security_group_id" {
  description = "Security Group ID attached to the RDS Proxy."
  value       = var.enable_proxy ? aws_security_group.rds_proxy[0].id : null
}

output "connection_endpoint" {
  description = "Recommended connection endpoint: proxy when enabled, otherwise direct RDS address."
  value       = var.enable_proxy ? aws_db_proxy.this[0].endpoint : aws_db_instance.this.address
}
