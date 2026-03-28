###############################################################################
# DNS Module Variables
###############################################################################

variable "domain_name" {
  description = "Root domain name for the hosted zone (e.g. myapp.com)."
  type        = string
}

variable "tags" {
  description = "Additional tags applied to all DNS resources."
  type        = map(string)
  default     = {}
}
