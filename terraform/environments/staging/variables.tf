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

variable "cluster_deletion_protection" {
  description = "Enable deletion protection for the EKS cluster."
  type        = bool
  default     = false
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
  default = true
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

# Elastic Cloud
variable "ec_api_key" {
  description = "Elastic Cloud API key."
  type        = string
  sensitive   = true
}

variable "es_region" {
  description = "Elastic Cloud deployment region."
  type        = string
  default     = "us-east-1"
}

variable "es_deployment_name" {
  description = "Elastic Cloud deployment name."
  type        = string
}

variable "es_deployment_template_id" {
  description = "Elastic Cloud deployment template ID."
  type        = string
  default     = "aws-general-purpose"
}

variable "es_version_regex" {
  description = "Regex to select Elasticsearch version."
  type        = string
  default     = "9\\..*"
}

variable "es_size" {
  description = "Elasticsearch hot tier memory size."
  type        = string
  default     = "4g"
}

variable "es_zone_count" {
  description = "Number of availability zones for Elasticsearch."
  type        = number
  default     = 1
}

variable "es_kibana_size" {
  description = "Kibana memory size."
  type        = string
  default     = "1g"
}

variable "es_app_user_name" {
  description = "Elasticsearch application user name."
  type        = string
  default     = "app_user"
}

variable "es_app_user_password" {
  description = "Elasticsearch application user password."
  type        = string
  sensitive   = true
}

variable "es_app_user_password_version" {
  description = "Increment to force password rotation."
  type        = number
  default     = 1
}

variable "es_app_indices" {
  description = "Index patterns the app user can access."
  type        = list(string)
  default     = ["*"]
}

# PrivateLink — Elastic Cloud
variable "elastic_privatelink_service_name" {
  description = "AWS VPC Endpoint Service name for Elastic Cloud PrivateLink in the target region. Find yours at: https://www.elastic.co/guide/en/cloud/current/ec-traffic-filtering-vpc.html"
  type        = string
}

variable "elastic_privatelink_phz_domain" {
  description = "Private Hosted Zone domain for Elastic Cloud PrivateLink (e.g. vpce.us-east-1.aws.elastic-cloud.com). Enables automatic DNS resolution from pods to the VPC Endpoint."
  type        = string
  default     = ""
}

# RDS PostgreSQL
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

# Kafka (Confluent Cloud)
variable "confluent_api_key" {
  description = "Confluent Cloud API key."
  type        = string
  sensitive   = true
}

variable "confluent_api_secret" {
  description = "Confluent Cloud API secret."
  type        = string
  sensitive   = true
}

variable "kafka_environment_name" {
  description = "Confluent Cloud environment display name."
  type        = string
}

variable "kafka_cluster_name" {
  description = "Kafka cluster display name."
  type        = string
}

variable "kafka_cloud_provider" {
  description = "Cloud provider for the Kafka cluster."
  type        = string
  default     = "AWS"
}

variable "kafka_region" {
  description = "Cloud region for the Kafka cluster."
  type        = string
  default     = "us-east-1"
}

variable "kafka_cluster_type" {
  description = "Cluster type: basic, standard or dedicated. PrivateLink requires dedicated."
  type        = string
  default     = "basic"
}

variable "kafka_app_service_account_name" {
  description = "Display name for the Kafka application service account."
  type        = string
  default     = "app-service-account"
}

variable "kafka_app_topic_name" {
  description = "Name of the default Kafka topic."
  type        = string
  default     = "app-events"
}

variable "kafka_app_topic_partitions" {
  description = "Number of partitions for the default topic."
  type        = number
  default     = 3
}
