###############################################################################
# RDS PostgreSQL
#
# Creates a PostgreSQL instance in the EKS VPC private subnets.
# The instance is NOT publicly accessible — only reachable from within
# the VPC (pods, other services in private subnets).
###############################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

###############################################################################
# Security Group — PostgreSQL port restricted to VPC CIDR
###############################################################################

resource "aws_security_group" "rds" {
  name_prefix = "${local.name_prefix}-rds-pg-"
  description = "Allow PostgreSQL access from VPC CIDR"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL from VPC CIDR"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rds-postgres"
  })

  lifecycle {
    create_before_destroy = true
  }
}

###############################################################################
# DB Subnet Group — private subnets only
###############################################################################

resource "aws_db_subnet_group" "this" {
  name       = "${local.name_prefix}-rds-pg"
  subnet_ids = var.subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rds-pg"
  })
}

###############################################################################
# RDS Instance
###############################################################################

resource "aws_db_instance" "this" {
  identifier = "${local.name_prefix}-pg"

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  db_name           = var.db_name
  username          = var.username
  password          = var.password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false
  multi_az            = var.multi_az
  skip_final_snapshot = var.skip_final_snapshot

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-pg"
  })
}
