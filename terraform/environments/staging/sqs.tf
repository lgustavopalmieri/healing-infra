###############################################################################
# SQS — Healing Specialist workload identity
#
# Creates IRSA role + IAM policies for SQS queue management and OpenSearch
# access. The application creates its own queues at startup (idempotent
# pattern); Terraform only provisions the IAM authorization.
#
# Index isolation: the OpenSearch IAM policy restricts this pod to
# healing-* indices only (via ARN-level restriction).
###############################################################################

module "sqs_healing_specialist" {
  source = "../../modules/sqs"

  project_name = var.project_name
  environment  = var.environment
  service_name = "specialist"

  k8s_namespace       = var.sqs_healing_k8s_namespace
  k8s_service_account = var.sqs_healing_k8s_service_account

  eks_oidc_provider_arn = module.eks.oidc_provider_arn
  eks_oidc_provider     = module.eks.oidc_provider

  sqs_queue_prefix        = var.sqs_healing_queue_prefix
  opensearch_domain_name  = "${var.project_name}-${var.environment}"
  opensearch_index_prefix = "healing"

  tags = var.tags
}
