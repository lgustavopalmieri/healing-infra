###############################################################################
# Bootstrap outputs — use these in environments/staging/main.tf backend block
###############################################################################

output "state_bucket_name" {
  value = module.backend.state_bucket_name
}

output "lock_table_name" {
  value = module.backend.lock_table_name
}

output "aws_region" {
  value = var.aws_region
}
