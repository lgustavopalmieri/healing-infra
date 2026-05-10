###############################################################################
# healing-specialist — pod identity + attached capabilities
#
# Composition pattern:
#   1. service-irsa creates the pod's IAM role with an IRSA trust policy.
#   2. iam-policy-* modules each create a scoped policy and attach it to the
#      role. They compose freely — add or remove capabilities without touching
#      the others.
#
# Applications create their own queues/topics at startup (idempotent). Terraform
# only provisions the IAM authorization.
#
# Multi-tenant isolation:
#   - SQS  → restricted to {queue_prefix}-*
#   - SNS  → restricted to {topic_prefix}-*
#   - OpenSearch → restricted to {index_prefix}-* indices on the domain.
###############################################################################

locals {
  specialist_name_prefix = "${var.project_name}-${var.environment}-specialist"
}

module "specialist_irsa" {
  source = "../../modules/service-irsa"

  project_name = var.project_name
  environment  = var.environment
  service_name = "specialist"

  k8s_namespace       = var.specialist_k8s_namespace
  k8s_service_account = var.specialist_k8s_service_account

  eks_oidc_provider_arn = module.eks.oidc_provider_arn
  eks_oidc_provider     = module.eks.oidc_provider

  tags = var.tags
}

module "specialist_sqs" {
  source = "../../modules/iam-policy-sqs"

  project_name = var.project_name
  environment  = var.environment
  name_prefix  = local.specialist_name_prefix
  role_name    = module.specialist_irsa.role_name

  queue_prefix = var.specialist_sqs_queue_prefix

  tags = var.tags
}

module "specialist_sns" {
  source = "../../modules/iam-policy-sns"

  project_name = var.project_name
  environment  = var.environment
  name_prefix  = local.specialist_name_prefix
  role_name    = module.specialist_irsa.role_name

  topic_prefix = var.specialist_sns_topic_prefix

  tags = var.tags
}

module "specialist_opensearch" {
  source = "../../modules/iam-policy-opensearch"

  project_name = var.project_name
  environment  = var.environment
  name_prefix  = local.specialist_name_prefix
  role_name    = module.specialist_irsa.role_name

  domain_name  = module.opensearch.domain_name
  index_prefix = var.specialist_opensearch_index_prefix

  tags = var.tags
}
