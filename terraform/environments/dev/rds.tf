###############################################################################
# RDS PostgreSQL Module
###############################################################################

module "rds_postgres" {
  source = "../../modules/rds-postgres"

  project_name = var.project_name
  environment  = var.environment

  vpc_id     = module.eks.vpc_id
  subnet_ids = module.eks.private_subnet_ids
  vpc_cidr   = var.vpc_cidr

  db_name             = var.rds_db_name
  username            = var.rds_username
  password            = var.rds_password
  engine_version      = var.rds_engine_version
  instance_class      = var.rds_instance_class
  allocated_storage   = var.rds_allocated_storage
  multi_az            = var.rds_multi_az
  skip_final_snapshot = var.rds_skip_final_snapshot

  enable_proxy                       = var.rds_enable_proxy
  proxy_idle_client_timeout          = var.rds_proxy_idle_client_timeout
  proxy_require_tls                  = var.rds_proxy_require_tls
  proxy_max_connections_percent      = var.rds_proxy_max_connections_percent
  proxy_max_idle_connections_percent = var.rds_proxy_max_idle_connections_percent
  proxy_connection_borrow_timeout    = var.rds_proxy_connection_borrow_timeout
  proxy_debug_logging                = var.rds_proxy_debug_logging

  tags = var.tags
}
