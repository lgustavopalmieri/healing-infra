###############################################################################
# RDS PostgreSQL Module
#
# Places the database in the EKS VPC private subnets. Not publicly
# accessible — pods reach it directly over the private network.
# No PrivateLink needed since RDS lives inside the same VPC.
###############################################################################

module "rds_postgres" {
  source = "../../modules/rds-postgres"

  project_name = var.project_name
  environment  = var.environment

  # Networking — from the EKS module which owns the VPC
  vpc_id     = module.eks.vpc_id
  subnet_ids = module.eks.private_subnet_ids
  vpc_cidr   = var.vpc_cidr

  # RDS
  db_name           = var.rds_db_name
  username          = var.rds_username
  password          = var.rds_password
  engine_version    = var.rds_engine_version
  instance_class    = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage
  multi_az          = var.rds_multi_az
  skip_final_snapshot = var.rds_skip_final_snapshot

  tags = var.tags
}
