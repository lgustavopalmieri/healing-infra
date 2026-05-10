###############################################################################
# Outputs
###############################################################################

output "policy_arn" {
  description = "ARN of the SQS IAM policy."
  value       = aws_iam_policy.this.arn
}

output "policy_name" {
  description = "Name of the SQS IAM policy."
  value       = aws_iam_policy.this.name
}
