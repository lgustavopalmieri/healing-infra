###############################################################################
# SQS Workload Identity
#
# Creates an IRSA-based IAM Role for a Kubernetes pod, with policies granting:
#   - SQS queue management (prefix-restricted — apps create their own queues)
#   - OpenSearch HTTP access (FGAC handles index-level authorization)
#
# This module replaces Confluent Cloud service accounts + API keys + ACLs
# with AWS-native IAM roles and policies.
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

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

###############################################################################
# IRSA IAM Role
###############################################################################

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

###############################################################################
# SQS IAM Policy — prefix-restricted queue management
###############################################################################

resource "aws_iam_policy" "sqs" {
  name = "${local.name_prefix}-${var.service_name}-sqs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowQueueManagement"
        Effect = "Allow"
        Action = [
          "sqs:CreateQueue",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes",
          "sqs:SetQueueAttributes",
          "sqs:TagQueue",
        ]
        Resource = "arn:aws:sqs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:${var.sqs_queue_prefix}-*"
      },
      {
        Sid    = "AllowMessageOperations"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:ChangeMessageVisibility",
        ]
        Resource = "arn:aws:sqs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:${var.sqs_queue_prefix}-*"
      },
      {
        Sid      = "AllowListQueues"
        Effect   = "Allow"
        Action   = ["sqs:ListQueues"]
        Resource = "*"
      },
    ]
  })

  tags = local.common_tags
}

###############################################################################
# OpenSearch IAM Policy — index-level isolation via ARN restriction
#
# Without FGAC, IAM policies enforce which indices a role can access.
# The Resource ARN pattern restricts this pod to only {index_prefix}-* indices.
###############################################################################

resource "aws_iam_policy" "opensearch" {
  name = "${local.name_prefix}-${var.service_name}-opensearch"

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
        Resource = "arn:aws:es:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:domain/${var.opensearch_domain_name}/${var.opensearch_index_prefix}-*"
      },
      {
        Sid    = "AllowClusterReadOnly"
        Effect = "Allow"
        Action = [
          "es:ESHttpGet",
        ]
        Resource = "arn:aws:es:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:domain/${var.opensearch_domain_name}"
      },
    ]
  })

  tags = local.common_tags
}

###############################################################################
# Policy Attachments
###############################################################################

resource "aws_iam_role_policy_attachment" "sqs" {
  role       = aws_iam_role.pod.name
  policy_arn = aws_iam_policy.sqs.arn
}

resource "aws_iam_role_policy_attachment" "opensearch" {
  role       = aws_iam_role.pod.name
  policy_arn = aws_iam_policy.opensearch.arn
}
