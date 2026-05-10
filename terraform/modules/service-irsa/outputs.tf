###############################################################################
# Outputs
###############################################################################

output "role_arn" {
  description = "ARN of the pod IAM role. Annotate this on the K8s ServiceAccount via eks.amazonaws.com/role-arn."
  value       = aws_iam_role.pod.arn
}

output "role_name" {
  description = "Name of the pod IAM role. Pass this as input to iam-policy-* modules."
  value       = aws_iam_role.pod.name
}

output "role_id" {
  description = "Unique ID of the pod IAM role."
  value       = aws_iam_role.pod.unique_id
}
