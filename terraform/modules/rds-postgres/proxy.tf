###############################################################################
# RDS Proxy — optional, gated by var.enable_proxy
#
# Provisions: Secrets Manager secret (DB creds), IAM role for proxy,
# dedicated Security Group, the proxy itself, default target group, and target
# registration pointing at the RDS instance.
###############################################################################

###############################################################################
# Secrets Manager — RDS Proxy requires credentials stored here
###############################################################################

resource "aws_secretsmanager_secret" "rds_credentials" {
  count = var.enable_proxy ? 1 : 0

  name_prefix             = "${local.name_prefix}-rds-creds-"
  recovery_window_in_days = 0

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rds-credentials"
  })
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  count = var.enable_proxy ? 1 : 0

  secret_id = aws_secretsmanager_secret.rds_credentials[0].id
  secret_string = jsonencode({
    username = var.username
    password = var.password
  })
}

###############################################################################
# IAM Role — allows the proxy to read the Secrets Manager secret
###############################################################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_role" "rds_proxy" {
  count = var.enable_proxy ? 1 : 0

  name_prefix = "${local.name_prefix}-rds-proxy-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "rds.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rds-proxy"
  })
}

resource "aws_iam_role_policy" "rds_proxy_secrets" {
  count = var.enable_proxy ? 1 : 0

  name = "${local.name_prefix}-rds-proxy-secrets"
  role = aws_iam_role.rds_proxy[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.rds_credentials[0].arn
      },
      {
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      }
    ]
  })
}

###############################################################################
# Security Group — the proxy gets its own SG, with egress to the RDS SG
###############################################################################

resource "aws_security_group" "rds_proxy" {
  count = var.enable_proxy ? 1 : 0

  name_prefix = "${local.name_prefix}-rds-proxy-"
  description = "Allow PostgreSQL traffic from VPC CIDR to the RDS Proxy"
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
    Name = "${local.name_prefix}-rds-proxy"
  })

  lifecycle {
    create_before_destroy = true
  }
}

###############################################################################
# RDS Proxy
###############################################################################

resource "aws_db_proxy" "this" {
  count = var.enable_proxy ? 1 : 0

  name                   = "${local.name_prefix}-pg-proxy"
  debug_logging          = var.proxy_debug_logging
  engine_family          = "POSTGRESQL"
  idle_client_timeout    = var.proxy_idle_client_timeout
  require_tls            = var.proxy_require_tls
  role_arn               = aws_iam_role.rds_proxy[0].arn
  vpc_security_group_ids = [aws_security_group.rds_proxy[0].id]
  vpc_subnet_ids         = var.subnet_ids

  auth {
    auth_scheme = "SECRETS"
    description = "RDS credentials from Secrets Manager"
    iam_auth    = "DISABLED"
    secret_arn  = aws_secretsmanager_secret.rds_credentials[0].arn
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-pg-proxy"
  })
}

###############################################################################
# Default Target Group — connection pool settings
###############################################################################

resource "aws_db_proxy_default_target_group" "this" {
  count = var.enable_proxy ? 1 : 0

  db_proxy_name = aws_db_proxy.this[0].name

  connection_pool_config {
    connection_borrow_timeout    = var.proxy_connection_borrow_timeout
    max_connections_percent      = var.proxy_max_connections_percent
    max_idle_connections_percent = var.proxy_max_idle_connections_percent
  }

  lifecycle {
    replace_triggered_by = [aws_db_proxy.this[0].id]
  }
}

###############################################################################
# Target — register the RDS instance with the proxy
###############################################################################

resource "aws_db_proxy_target" "this" {
  count = var.enable_proxy ? 1 : 0

  db_instance_identifier = aws_db_instance.this.identifier
  db_proxy_name          = aws_db_proxy.this[0].name
  target_group_name      = aws_db_proxy_default_target_group.this[0].name

  lifecycle {
    replace_triggered_by = [aws_db_proxy.this[0].id]
  }
}
