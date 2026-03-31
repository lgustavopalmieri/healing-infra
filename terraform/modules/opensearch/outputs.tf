###############################################################################
# Outputs
###############################################################################

output "domain_endpoint" {
  description = "Domain-specific endpoint for index, search, and data upload requests."
  value       = aws_opensearch_domain.this.endpoint
}

output "domain_arn" {
  description = "ARN of the OpenSearch domain."
  value       = aws_opensearch_domain.this.arn
}

output "domain_name" {
  description = "Name of the OpenSearch domain."
  value       = aws_opensearch_domain.this.domain_name
}

output "domain_id" {
  description = "Unique identifier for the domain."
  value       = aws_opensearch_domain.this.domain_id
}

output "dashboard_endpoint" {
  description = "Domain-specific endpoint for OpenSearch Dashboards."
  value       = aws_opensearch_domain.this.dashboard_endpoint
}

output "security_group_id" {
  description = "Security Group ID attached to the OpenSearch domain."
  value       = aws_security_group.opensearch.id
}
