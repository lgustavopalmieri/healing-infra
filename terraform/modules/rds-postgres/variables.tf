###############################################################################
# General
###############################################################################

variable "project_name" {
  description = "Project name. Used as prefix for resource naming."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. staging, production)."
  type        = string
}

variable "tags" {
  description = "Additional tags applied to all module resources."
  type        = map(string)
  default     = {}
}

###############################################################################
# Networking — provided by the caller (from the EKS module outputs)
###############################################################################

variable "vpc_id" {
  description = "VPC ID where the RDS instance will be placed."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the DB subnet group."
  type        = list(string)
}

variable "vpc_cidr" {
  description = "VPC CIDR block. Used for Security Group ingress rules."
  type        = string
}

###############################################################################
# RDS Instance
###############################################################################

variable "db_name" {
  description = "Name of the default database to create."
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "17"
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB."
  type        = number
  default     = 10
}

variable "username" {
  description = "Master database username."
  type        = string
}

variable "password" {
  description = "Master database password."
  type        = string
  sensitive   = true
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for high availability."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on deletion. Set to false in production."
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Enable deletion protection. Set to true in production."
  type        = bool
  default     = false
}

###############################################################################
# RDS Proxy (optional — controlled by enable_proxy)
###############################################################################

variable "enable_proxy" {
  description = "Provision an RDS Proxy in front of the PostgreSQL instance."
  type        = bool
  default     = false
}

variable "proxy_idle_client_timeout" {
  description = "Seconds a proxy connection can stay idle before being closed."
  type        = number
  default     = 1800
}

variable "proxy_require_tls" {
  description = "Require TLS for client connections to the proxy."
  type        = bool
  default     = true
}

variable "proxy_max_connections_percent" {
  description = "Upper limit (%) of max_connections the proxy can open on the RDS instance."
  type        = number
  default     = 100
}

variable "proxy_max_idle_connections_percent" {
  description = "Percentage of idle connections the proxy keeps open in the pool."
  type        = number
  default     = 50
}

variable "proxy_connection_borrow_timeout" {
  description = "Seconds the proxy waits for a connection to become available."
  type        = number
  default     = 120
}

variable "proxy_debug_logging" {
  description = "Enable enhanced logging for proxy SQL statements (use only for debugging)."
  type        = bool
  default     = false
}
