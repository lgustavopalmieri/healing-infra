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

variable "availability_zones" {
  description = "List of AZs for subnet distribution. If empty, defaults to the first 3 AZs in the region."
  type        = list(string)
  default     = []
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

###############################################################################
# OpenSearch
###############################################################################

variable "opensearch_engine_version" {
  description = "OpenSearch engine version."
  type        = string
  default     = "OpenSearch_2.17"
}

variable "opensearch_instance_type" {
  description = "Instance type for OpenSearch data nodes."
  type        = string
  default     = "r6g.large.search"
}

variable "opensearch_instance_count" {
  description = "Number of OpenSearch data nodes."
  type        = number
  default     = 3
}

variable "opensearch_ebs_volume_size" {
  description = "EBS volume size in GiB per data node."
  type        = number
  default     = 100
}

variable "opensearch_ebs_volume_type" {
  description = "EBS volume type."
  type        = string
  default     = "gp3"
}

variable "opensearch_zone_awareness_enabled" {
  description = "Enable Multi-AZ deployment. Must be true for production."
  type        = bool
  default     = true
}

variable "opensearch_availability_zone_count" {
  description = "Number of AZs when zone awareness is enabled."
  type        = number
  default     = 3
}

variable "opensearch_dedicated_master_enabled" {
  description = "Enable dedicated master nodes. Recommended when cluster grows beyond 3 tenants."
  type        = bool
  default     = false
}

variable "opensearch_dedicated_master_type" {
  description = "Instance type for dedicated master nodes."
  type        = string
  default     = "m6g.large.search"
}

variable "opensearch_dedicated_master_count" {
  description = "Number of dedicated master nodes."
  type        = number
  default     = 3
}

variable "opensearch_create_service_linked_role" {
  description = "Create the OpenSearch service-linked role. Set to false if it already exists in the account (most common)."
  type        = bool
  default     = false
}

###############################################################################
# SQS / Workload Identity — Healing Specialist
###############################################################################

variable "sqs_healing_k8s_namespace" {
  description = "Kubernetes namespace for the healing specialist service."
  type        = string
  default     = "healing"
}

variable "sqs_healing_k8s_service_account" {
  description = "Kubernetes ServiceAccount for the healing specialist service."
  type        = string
  default     = "healing-specialist"
}

variable "sqs_healing_queue_prefix" {
  description = "SQS queue name prefix for the healing specialist service."
  type        = string
  default     = "specialist"
}

###############################################################################
# RDS PostgreSQL
###############################################################################

variable "rds_db_name" {
  description = "Name of the default database to create."
  type        = string
}

variable "rds_username" {
  description = "Master database username."
  type        = string
}

variable "rds_password" {
  description = "Master database password."
  type        = string
  sensitive   = true
}

variable "rds_engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "17"
}

variable "rds_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Allocated storage in GB."
  type        = number
  default     = 10
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ deployment for high availability."
  type        = bool
  default     = false
}

variable "rds_skip_final_snapshot" {
  description = "Skip final snapshot on deletion. Set to false in production."
  type        = bool
  default     = true
}

variable "rds_enable_proxy" {
  description = "Provision an RDS Proxy for connection pooling."
  type        = bool
  default     = false
}

variable "rds_proxy_idle_client_timeout" {
  description = "Seconds a proxy connection can stay idle before being closed."
  type        = number
  default     = 1800
}

variable "rds_proxy_require_tls" {
  description = "Require TLS for client connections to the proxy."
  type        = bool
  default     = true
}

variable "rds_proxy_max_connections_percent" {
  description = "Upper limit (%) of max_connections the proxy can open on the RDS instance."
  type        = number
  default     = 100
}

variable "rds_proxy_max_idle_connections_percent" {
  description = "Percentage of idle connections the proxy keeps open in the pool."
  type        = number
  default     = 50
}

variable "rds_proxy_connection_borrow_timeout" {
  description = "Seconds the proxy waits for a connection to become available."
  type        = number
  default     = 120
}

variable "rds_proxy_debug_logging" {
  description = "Enable enhanced logging for proxy SQL statements."
  type        = bool
  default     = false
}
