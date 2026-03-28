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
