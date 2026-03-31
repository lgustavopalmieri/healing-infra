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

variable "domain_name" {
  description = "OpenSearch domain name. Defaults to {project_name}-{environment}. Max 28 characters, lowercase alphanumeric and hyphens."
  type        = string
  default     = ""

  validation {
    condition     = var.domain_name == "" || can(regex("^[a-z][a-z0-9-]{2,27}$", var.domain_name))
    error_message = "Domain name must be 3-28 lowercase alphanumeric characters or hyphens, starting with a letter."
  }
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}

###############################################################################
# Engine & Cluster
###############################################################################

variable "engine_version" {
  description = "OpenSearch engine version (e.g. OpenSearch_2.17)."
  type        = string
  default     = "OpenSearch_2.17"
}

variable "instance_type" {
  description = "Instance type for data nodes."
  type        = string
  default     = "t3.small.search"
}

variable "instance_count" {
  description = "Number of data node instances."
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count >= 1
    error_message = "Instance count must be at least 1."
  }
}

variable "zone_awareness_enabled" {
  description = "Enable Multi-AZ deployment for high availability."
  type        = bool
  default     = false
}

variable "availability_zone_count" {
  description = "Number of AZs when zone awareness is enabled (2 or 3)."
  type        = number
  default     = 2

  validation {
    condition     = contains([2, 3], var.availability_zone_count)
    error_message = "Availability zone count must be 2 or 3."
  }
}

variable "dedicated_master_enabled" {
  description = "Enable dedicated master nodes. Recommended for production clusters with 3+ tenants."
  type        = bool
  default     = false
}

variable "dedicated_master_type" {
  description = "Instance type for dedicated master nodes."
  type        = string
  default     = "m6g.large.search"
}

variable "dedicated_master_count" {
  description = "Number of dedicated master nodes (3 or 5)."
  type        = number
  default     = 3
}

###############################################################################
# Storage
###############################################################################

variable "ebs_volume_type" {
  description = "EBS volume type (gp3, gp2, io1)."
  type        = string
  default     = "gp3"
}

variable "ebs_volume_size" {
  description = "EBS volume size in GiB per data node."
  type        = number
  default     = 20

  validation {
    condition     = var.ebs_volume_size >= 10
    error_message = "EBS volume size must be at least 10 GiB."
  }
}

variable "kms_key_id" {
  description = "KMS key ARN for encryption at rest. Defaults to the AWS-managed es key."
  type        = string
  default     = null
}

###############################################################################
# Networking — provided by the caller (e.g. from the EKS module outputs)
###############################################################################

variable "vpc_id" {
  description = "VPC ID where the OpenSearch domain will be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the OpenSearch domain. Must span the configured number of AZs."
  type        = list(string)
}

variable "vpc_cidr" {
  description = "VPC CIDR block. Used for Security Group ingress."
  type        = string
}

###############################################################################
# Access Control
###############################################################################

variable "create_service_linked_role" {
  description = "Create the OpenSearch service-linked role. Set to false if it already exists in the account."
  type        = bool
  default     = true
}

###############################################################################
# Logging (optional)
###############################################################################

variable "log_publishing_options" {
  description = "Log publishing options for CloudWatch Logs. Each entry needs log_type (INDEX_SLOW_LOGS, SEARCH_SLOW_LOGS, ES_APPLICATION_LOGS, AUDIT_LOGS) and cloudwatch_log_group_arn."
  type = list(object({
    log_type                 = string
    cloudwatch_log_group_arn = string
  }))
  default = []
}
