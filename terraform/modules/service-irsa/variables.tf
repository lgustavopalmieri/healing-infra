###############################################################################
# Inputs
###############################################################################

variable "project_name" {
  description = "Project name. Used as prefix for the role name."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, production)."
  type        = string
}

variable "service_name" {
  description = "Name of the service (e.g. specialist). Used in the role name."
  type        = string
}

variable "k8s_namespace" {
  description = "Kubernetes namespace where the pod runs."
  type        = string
}

variable "k8s_service_account" {
  description = "Kubernetes ServiceAccount name bound to this role."
  type        = string
}

variable "eks_oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider for the IRSA trust policy."
  type        = string
}

variable "eks_oidc_provider" {
  description = "EKS OIDC provider URL without https:// prefix (e.g. oidc.eks.us-east-1.amazonaws.com/id/...)."
  type        = string
}

variable "tags" {
  description = "Additional tags applied to the role."
  type        = map(string)
  default     = {}
}
