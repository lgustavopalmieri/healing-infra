###############################################################################
# Shared environment variables — values come from .tfvars
###############################################################################

variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "domain_name" {
  description = "Root domain name (e.g. myapp.com)."
  type        = string
}

variable "tags" {
  description = "Additional tags."
  type        = map(string)
  default     = {}
}
