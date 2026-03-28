###############################################################################
# Environment variables — values come from .tfvars
###############################################################################

variable "project_name" {
  description = "Project name."
  type        = string
}

variable "environment" {
  description = "Environment (e.g. dev, staging, production)."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name."
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

# Networking
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

# EKS
variable "kubernetes_version" {
  type    = string
  default = "1.35"
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_min_size" {
  type    = number
  default = 3
}

variable "node_max_size" {
  type    = number
  default = 6
}

variable "node_desired_size" {
  type    = number
  default = 3
}

variable "cluster_endpoint_public_access" {
  type    = bool
  default = true
}

variable "cluster_endpoint_private_access" {
  type    = bool
  default = true
}

# ECR
variable "ecr_repository_name" {
  type = string
}

variable "ecr_force_delete" {
  type    = bool
  default = false
}

# GitHub OIDC
variable "github_org" {
  type = string
}

variable "github_repos" {
  type = list(string)
}

# DNS
variable "shared_state_bucket" {
  description = "S3 bucket name of the shared environment state. Used to read the Route53 zone_id."
  type        = string
  default     = ""
}

variable "zone_id" {
  description = "Route53 zone ID. If provided, takes precedence over shared remote state lookup."
  type        = string
  default     = ""
}

variable "dns_records" {
  description = "List of DNS record names to create as aliases to the ALB."
  type        = list(string)
  default     = []
}
