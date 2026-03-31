###############################################################################
# General
###############################################################################

variable "project_name" {
  description = "Project name. Used as prefix for resource naming."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, production)."
  type        = string
}

variable "service_name" {
  description = "Name of the service (e.g. specialist). Used in IAM role and policy names."
  type        = string
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}

###############################################################################
# IRSA (IAM Roles for Service Accounts)
###############################################################################

variable "k8s_namespace" {
  description = "Kubernetes namespace where the service runs."
  type        = string
}

variable "k8s_service_account" {
  description = "Kubernetes ServiceAccount name for the service."
  type        = string
}

variable "eks_oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider for IRSA trust policy."
  type        = string
}

variable "eks_oidc_provider" {
  description = "EKS OIDC provider URL without https:// prefix (e.g. oidc.eks.us-east-1.amazonaws.com/id/...)."
  type        = string
}

###############################################################################
# SQS
###############################################################################

variable "sqs_queue_prefix" {
  description = "Prefix for SQS queue names this service is allowed to manage (e.g. specialist). The service can only create queues matching {prefix}-*."
  type        = string
}

###############################################################################
# OpenSearch
###############################################################################

variable "opensearch_domain_name" {
  description = "Name of the OpenSearch domain. Used to construct the IAM policy resource ARN (no dependency on the domain resource)."
  type        = string
}

variable "opensearch_index_prefix" {
  description = "Index prefix this service is allowed to access (e.g. healing). The IAM policy restricts to {prefix}-* indices."
  type        = string
}
