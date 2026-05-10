###############################################################################
# IAM Policy — OpenSearch (index-prefix isolation via Resource ARN)
#
# Attaches to an existing IAM role (typically from `service-irsa`).
# Grants HTTP access restricted to indices matching {index_prefix}-* on the
# given domain, plus read-only access to the domain root for cluster health
# checks (_cat, _cluster/health, ...).
#
# This is how the platform enforces multi-tenant index isolation without
# relying on the FGAC plugin.
###############################################################################

locals {
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_policy" "this" {
  name        = "${var.name_prefix}-opensearch"
  description = "OpenSearch access for ${var.name_prefix}: HTTP access restricted to ${var.index_prefix}-* indices on ${var.domain_name}."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowIndexAccess"
        Effect = "Allow"
        Action = [
          "es:ESHttpGet",
          "es:ESHttpPost",
          "es:ESHttpPut",
          "es:ESHttpHead",
          "es:ESHttpDelete",
        ]
        Resource = "arn:aws:es:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:domain/${var.domain_name}/${var.index_prefix}-*"
      },
      {
        Sid      = "AllowClusterReadOnly"
        Effect   = "Allow"
        Action   = ["es:ESHttpGet"]
        Resource = "arn:aws:es:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:domain/${var.domain_name}"
      },
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = var.role_name
  policy_arn = aws_iam_policy.this.arn
}
