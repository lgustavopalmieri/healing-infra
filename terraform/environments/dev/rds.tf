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

  tags = var.tags
}
