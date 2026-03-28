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

###############################################################################
# Confluent Cloud Environment & Cluster
###############################################################################

variable "environment_name" {
  description = "Confluent Cloud environment display name."
  type        = string
}

variable "cluster_name" {
  description = "Kafka cluster display name."
  type        = string
}

variable "cloud_provider" {
  description = "Cloud provider for the cluster (AWS, GCP, AZURE)."
  type        = string
  default     = "AWS"

  validation {
    condition     = contains(["AWS", "GCP", "AZURE"], var.cloud_provider)
    error_message = "Cloud provider must be AWS, GCP or AZURE."
  }
}

variable "region" {
  description = "Cloud region for the Kafka cluster (e.g. us-east-1)."
  type        = string
}

variable "cluster_type" {
  description = "Cluster type: basic, standard or dedicated. PrivateLink requires dedicated."
  type        = string
  default     = "basic"

  validation {
    condition     = contains(["basic", "standard", "dedicated"], var.cluster_type)
    error_message = "Cluster type must be basic, standard or dedicated."
  }
}

###############################################################################
# Service Account & Application Credentials
###############################################################################

variable "app_service_account_name" {
  description = "Display name for the application service account."
  type        = string
  default     = "app-service-account"
}

###############################################################################
# Default Topic
###############################################################################

variable "app_topic_name" {
  description = "Name of the default Kafka topic to create."
  type        = string
  default     = "app-events"
}

variable "app_topic_partitions" {
  description = "Number of partitions for the default topic."
  type        = number
  default     = 3

  validation {
    condition     = var.app_topic_partitions >= 1 && var.app_topic_partitions <= 100
    error_message = "Partition count must be between 1 and 100."
  }
}
