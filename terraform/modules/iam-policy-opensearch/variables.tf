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
  description = "Prefix used to name the IAM policy (e.g. healing-dev-specialist). The final name is {name_prefix}-opensearch."
  type        = string
}

variable "role_name" {
  description = "Name of the IAM role to attach this policy to (typically from service-irsa.role_name)."
  type        = string
}

variable "domain_name" {
  description = "OpenSearch domain name to scope the policy to (typically from the opensearch module output)."
  type        = string
}

variable "index_prefix" {
  description = "Index prefix the caller is allowed to access (e.g. healing). Access is restricted to {index_prefix}-* indices via Resource ARN."
  type        = string
}

variable "tags" {
  description = "Additional tags applied to the policy."
  type        = map(string)
  default     = {}
}
