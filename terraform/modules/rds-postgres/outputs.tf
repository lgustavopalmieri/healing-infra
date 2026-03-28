###############################################################################
# Outputs
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
