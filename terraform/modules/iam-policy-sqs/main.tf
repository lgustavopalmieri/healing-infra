###############################################################################
# IAM Policy — SQS (prefix-restricted queue management)
#
# Attaches to an existing IAM role (typically created by `service-irsa`).
# Grants the caller permission to create and use SQS queues whose names
# match {queue_prefix}-*. sqs:ListQueues cannot be scoped by resource — AWS
# only accepts Resource = "*" for that action.
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
  name        = "${var.name_prefix}-sqs"
  description = "SQS access for ${var.name_prefix}: manage and use queues matching ${var.queue_prefix}-*."

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
        Resource = "arn:aws:sqs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:${var.queue_prefix}-*"
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
        Resource = "arn:aws:sqs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:${var.queue_prefix}-*"
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

resource "aws_iam_role_policy_attachment" "this" {
  role       = var.role_name
  policy_arn = aws_iam_policy.this.arn
}
