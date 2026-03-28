###############################################################################
# Backend Module Variables
###############################################################################

variable "project_name" {
  description = "Project name. Used as prefix for bucket and table names."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev, release, production)."
  type        = string
}

variable "aws_region" {
  description = "AWS region for the state bucket and lock table."
  type        = string
}

variable "tags" {
  description = "Additional tags applied to all backend resources."
  type        = map(string)
  default     = {}
}
