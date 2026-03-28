###############################################################################
# General
###############################################################################

variable "project_name" {
  description = "Project name. Used as prefix for auxiliary resources (VPC, IAM roles, etc.)."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, production)."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name. You have full control over this value."
  type        = string
}

variable "aws_region" {
  description = "AWS region where resources will be provisioned."
  type        = string
}

variable "tags" {
  description = "Additional tags applied to all module resources."
  type        = map(string)
  default     = {}
}

###############################################################################
# Networking (VPC)
###############################################################################

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of AZs for subnet distribution. If empty, defaults to the first 3 AZs in the region."
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "List of CIDRs for private subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  description = "List of CIDRs for public subnets."
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "single_nat_gateway" {
  description = "If true, creates a single NAT Gateway (cost saving). If false, one per AZ (HA)."
  type        = bool
  default     = true
}

###############################################################################
# EKS Cluster
###############################################################################

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.35"
}

variable "cluster_endpoint_public_access" {
  description = "Enable public access to the cluster endpoint."
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Enable private access to the cluster endpoint."
  type        = bool
  default     = true
}

variable "cluster_deletion_protection" {
  description = "Enable deletion protection for the EKS cluster. Set to true in production."
  type        = bool
  default     = true
}

variable "node_instance_types" {
  description = "Instance types for the managed node groups."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_min_size" {
  description = "Minimum number of nodes in the node group."
  type        = number
  default     = 3
}

variable "node_max_size" {
  description = "Maximum number of nodes in the node group."
  type        = number
  default     = 6
}

variable "node_desired_size" {
  description = "Desired number of nodes in the node group."
  type        = number
  default     = 3
}

###############################################################################
# ALB Controller
###############################################################################

variable "alb_controller_helm_version" {
  description = "Helm chart version for the AWS Load Balancer Controller."
  type        = string
  default     = "1.12.0"
}

###############################################################################
# ECR
###############################################################################

variable "ecr_repository_name" {
  description = "ECR repository name."
  type        = string
}

variable "ecr_image_tag_mutability" {
  description = "Image tag mutability (MUTABLE or IMMUTABLE)."
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.ecr_image_tag_mutability)
    error_message = "Value must be MUTABLE or IMMUTABLE."
  }
}

variable "ecr_force_delete" {
  description = "Allow deleting the repository even with images. Use with caution in production."
  type        = bool
  default     = false
}

variable "ecr_scan_on_push" {
  description = "Enable vulnerability scanning on image push."
  type        = bool
  default     = true
}

###############################################################################
# GitHub OIDC
###############################################################################

variable "github_org" {
  description = "GitHub organization or user for the OIDC provider."
  type        = string
}

variable "github_repos" {
  description = "List of GitHub repositories with ECR access via OIDC."
  type        = list(string)
}

###############################################################################
# DNS Records
###############################################################################

variable "zone_id" {
  description = "Route53 hosted zone ID. If empty, DNS records will not be created."
  type        = string
  default     = ""
}

variable "dns_records" {
  description = "List of DNS record names to create as aliases to the ALB (e.g. [\"api.staging.myapp.com\"])."
  type        = list(string)
  default     = []
}
