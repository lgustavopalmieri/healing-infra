###############################################################################
# IAM Policy — SNS (prefix-restricted topic management)
#
# Attaches to an existing IAM role (typically from `service-irsa`).
# Grants the caller permission to create and use SNS topics whose names match
# {topic_prefix}-*.
#
# Notes on actions that cannot be scoped by ARN:
#   - sns:ListTopics — not scoped by resource (AWS requires Resource = "*").
#   - sns:ListSubscriptions — idem.
# Everything else is restricted to the prefix.
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
  name        = "${var.name_prefix}-sns"
  description = "SNS access for ${var.name_prefix}: manage and use topics matching ${var.topic_prefix}-*."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowTopicManagement"
        Effect = "Allow"
        Action = [
          "sns:CreateTopic",
          "sns:DeleteTopic",
          "sns:GetTopicAttributes",
          "sns:SetTopicAttributes",
          "sns:TagResource",
          "sns:UntagResource",
          "sns:ListTagsForResource",
        ]
        Resource = "arn:aws:sns:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:${var.topic_prefix}-*"
      },
      {
        Sid    = "AllowPublishAndSubscribe"
        Effect = "Allow"
        Action = [
          "sns:Publish",
          "sns:Subscribe",
          "sns:Unsubscribe",
          "sns:ListSubscriptionsByTopic",
        ]
        Resource = "arn:aws:sns:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:${var.topic_prefix}-*"
      },
      {
        Sid    = "AllowGlobalListings"
        Effect = "Allow"
        Action = [
          "sns:ListTopics",
          "sns:ListSubscriptions",
        ]
        Resource = "*"
      },
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = var.role_name
  policy_arn = aws_iam_policy.this.arn
}
