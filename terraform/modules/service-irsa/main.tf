###############################################################################
# Service IRSA Role
#
# Creates the IAM Role with an IRSA trust policy for a Kubernetes pod.
# Capabilities (SQS, SNS, OpenSearch, ...) are attached separately via
# `iam-policy-*` modules that consume this role by name.
#
# This module is intentionally minimal: one role, one trust policy, no perms.
###############################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  role_name   = "${local.name_prefix}-${var.service_name}-pod-role"

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

resource "aws_iam_role" "pod" {
  name = local.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.eks_oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.eks_oidc_provider}:sub" = "system:serviceaccount:${var.k8s_namespace}:${var.k8s_service_account}"
            "${var.eks_oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}
