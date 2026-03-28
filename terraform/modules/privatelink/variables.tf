###############################################################################
# General
###############################################################################

variable "project_name" {
  description = "Project name. Used as prefix for resource naming."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. release, production)."
  type        = string
}

variable "service_label" {
  description = "Short label identifying the target service (e.g. elastic, kafka, rds). Used in resource names and tags."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,19}$", var.service_label))
    error_message = "service_label must be lowercase alphanumeric with hyphens, max 20 chars."
  }
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}

###############################################################################
# Networking — provided by the caller (e.g. from the EKS module outputs)
###############################################################################

variable "vpc_id" {
  description = "VPC ID where the Interface Endpoint will be created."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the VPC Endpoint ENIs. Should span all AZs supported by the target service."
  type        = list(string)
}

variable "vpc_cidr" {
  description = "VPC CIDR block. Used for Security Group ingress rules."
  type        = string
}

###############################################################################
# VPC Endpoint
###############################################################################

variable "service_name" {
  description = "AWS VPC Endpoint Service name (e.g. com.amazonaws.vpce.us-east-1.vpce-svc-...)."
  type        = string
}

variable "allowed_ports" {
  description = "List of TCP ports to allow from the VPC CIDR to the endpoint."
  type        = list(number)
  default     = [443]

  validation {
    condition     = length(var.allowed_ports) > 0
    error_message = "At least one port must be specified."
  }
}

###############################################################################
# Private Hosted Zone (optional)
###############################################################################

variable "private_hosted_zone_domain" {
  description = "Domain name for the Private Hosted Zone (e.g. vpce.us-east-1.aws.elastic-cloud.com). If empty, no PHZ or DNS record is created."
  type        = string
  default     = ""
}
