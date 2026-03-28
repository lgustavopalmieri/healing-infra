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

variable "tags" {
  description = "Additional tags applied to all module resources."
  type        = map(string)
  default     = {}
}

###############################################################################
# Elastic Cloud Deployment
###############################################################################

variable "region" {
  description = "Elastic Cloud deployment region (e.g. us-east-1, sa-east-1, eu-west-1)."
  type        = string
}

variable "deployment_name" {
  description = "Elastic Cloud deployment name."
  type        = string
}

variable "deployment_template_id" {
  description = "Deployment template ID (varies by region and provider)."
  type        = string
  default     = "aws-general-purpose"
}

variable "elasticsearch_version_regex" {
  description = "Regex to select the Elasticsearch version (e.g. \"9\\\\..*\" for latest 9.x)."
  type        = string
  default     = "9\\..*"
}

variable "elasticsearch_size" {
  description = "Hot tier memory size (e.g. 1g, 2g, 4g, 8g)."
  type        = string
  default     = "4g"

  validation {
    condition     = contains(["1g", "2g", "4g", "8g", "16g", "32g", "64g"], var.elasticsearch_size)
    error_message = "Invalid size. Use: 1g, 2g, 4g, 8g, 16g, 32g or 64g."
  }
}

variable "elasticsearch_zone_count" {
  description = "Number of availability zones (1, 2 or 3)."
  type        = number
  default     = 1

  validation {
    condition     = contains([1, 2, 3], var.elasticsearch_zone_count)
    error_message = "Zone count must be 1, 2 or 3."
  }
}

###############################################################################
# Kibana
###############################################################################

variable "kibana_size" {
  description = "Kibana memory size (e.g. 1g, 2g, 4g, 8g)."
  type        = string
  default     = "1g"

  validation {
    condition     = contains(["1g", "2g", "4g", "8g"], var.kibana_size)
    error_message = "Invalid Kibana size. Use: 1g, 2g, 4g or 8g."
  }
}

###############################################################################
# Application User
###############################################################################

variable "app_user_name" {
  description = "Application user name in Elasticsearch."
  type        = string
  default     = "app_user"
}

variable "app_user_password" {
  description = "Application user password (minimum 6 characters)."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.app_user_password) >= 6
    error_message = "Password must be at least 6 characters."
  }
}

variable "app_user_password_version" {
  description = "Increment to force password rotation without recreating the resource."
  type        = number
  default     = 1
}

variable "app_indices" {
  description = "Index patterns the app_user can access (e.g. [\"app-*\", \"logs-*\"]). Use [\"*\"] for all."
  type        = list(string)
  default     = ["*"]
}
