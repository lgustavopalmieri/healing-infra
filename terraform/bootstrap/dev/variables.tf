###############################################################################
# Bootstrap variables — values come from .tfvars
###############################################################################

variable "project_name" {
  description = "Project name."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "tags" {
  description = "Additional tags."
  type        = map(string)
  default     = {}
}

variable "force_destroy" {
  description = "Allow destroying the S3 state bucket even when it contains objects."
  type        = bool
  default     = false
}
