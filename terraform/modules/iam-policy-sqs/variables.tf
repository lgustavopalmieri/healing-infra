###############################################################################
# Inputs
###############################################################################

variable "project_name" {
  description = "Project name. Used only for tagging."
  type        = string
}

variable "environment" {
  description = "Deployment environment. Used only for tagging."
  type        = string
}

variable "name_prefix" {
  description = "Prefix used to name the IAM policy (e.g. healing-dev-specialist). The final name is {name_prefix}-sqs."
  type        = string
}

variable "role_name" {
  description = "Name of the IAM role to attach this policy to (typically from service-irsa.role_name)."
  type        = string
}

variable "queue_prefix" {
  description = "SQS queue name prefix the caller is allowed to manage (e.g. specialist). Access is restricted to {queue_prefix}-*."
  type        = string
}

variable "tags" {
  description = "Additional tags applied to the policy."
  type        = map(string)
  default     = {}
}
