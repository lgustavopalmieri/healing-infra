###############################################################################
# Outputs
###############################################################################

output "iam_role_arn" {
  description = "ARN of the pod IAM role. Annotate on the K8s ServiceAccount with eks.amazonaws.com/role-arn."
  value       = aws_iam_role.pod.arn
}

output "iam_role_name" {
  description = "Name of the pod IAM role."
  value       = aws_iam_role.pod.name
}

output "sqs_policy_arn" {
  description = "ARN of the SQS IAM policy."
  value       = aws_iam_policy.sqs.arn
}

output "opensearch_policy_arn" {
  description = "ARN of the OpenSearch IAM policy."
  value       = aws_iam_policy.opensearch.arn
}
