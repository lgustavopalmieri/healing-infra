###############################################################################
# Outputs
###############################################################################

# --- EKS ---
output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint."
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Cluster CA data (base64-encoded)."
  value       = module.eks.cluster_certificate_authority_data
}

output "oidc_provider_arn" {
  description = "EKS OIDC provider ARN (useful for IRSA in other modules)."
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider" {
  description = "EKS OIDC provider URL without https:// prefix (for IRSA trust policy conditions)."
  value       = module.eks.oidc_provider
}

# --- VPC ---
output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.vpc.public_subnets
}

# --- ECR ---
output "ecr_repository_url" {
  description = "ECR repository URL."
  value       = aws_ecr_repository.this.repository_url
}

output "ecr_repository_arn" {
  description = "ECR repository ARN."
  value       = aws_ecr_repository.this.arn
}

# --- GitHub OIDC ---
output "github_actions_role_arn" {
  description = "IAM role ARN to configure in GitHub Actions."
  value       = aws_iam_role.github_actions.arn
}

# --- DNS ---
output "dns_records" {
  description = "DNS records created for this environment."
  value       = { for k, v in aws_route53_record.app : k => v.fqdn }
}