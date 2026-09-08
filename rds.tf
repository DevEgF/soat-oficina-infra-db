data "aws_caller_identity" "current" {}

resource "aws_kms_key" "rds" {
  description             = "Encrypts the soat-oficina managed PostgreSQL data and telemetry"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  rotation_period_in_days = 365
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EnableAccountAdministration"
        Effect   = "Allow"
        Action   = "kms:*"
        Resource = "*"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      },
      {
        Sid    = "AllowCloudWatchLogsEncryption"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*",
        ]
        Resource = "*"
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
        }
        Condition = {
          ArnEquals = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/rds/instance/${local.project}-db/postgresql"
          }
        }
      },
    ]
  })
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${local.project}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

resource "aws_cloudwatch_log_group" "postgresql" {
  name              = "/aws/rds/instance/${local.project}-db/postgresql"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.rds.arn
}

resource "aws_iam_role" "rds_monitoring" {
  name = "${local.project}-rds-monitoring"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_instance" "this" {
  # checkov:skip=CKV_AWS_133:One-day backup retention is the approved academic cost and recovery trade-off.
  # checkov:skip=CKV_AWS_157:Single-AZ is the approved academic cost trade-off for the shared non-production workload.
  # checkov:skip=CKV_AWS_354:The protected destroy workflow creates and verifies a final snapshot before disabling protection.
  identifier = "${local.project}-db"

  engine         = "postgres"
  engine_version = "16"
  instance_class = "db.t4g.micro"
  db_name        = "oficina"
  username       = "oficina_admin"

  manage_master_user_password   = true
  master_user_secret_kms_key_id = aws_kms_key.rds.arn

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.postgres16.name
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period    = 1
  deletion_protection        = var.deletion_protection
  skip_final_snapshot        = true
  apply_immediately          = true
  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true

  iam_database_authentication_enabled   = true
  enabled_cloudwatch_logs_exports       = ["postgresql"]
  monitoring_interval                   = 60
  monitoring_role_arn                   = aws_iam_role.rds_monitoring.arn
  performance_insights_enabled          = true
  performance_insights_kms_key_id       = aws_kms_key.rds.arn
  performance_insights_retention_period = 7

  depends_on = [aws_cloudwatch_log_group.postgresql]
}

resource "aws_iam_role_policy" "app_rds_secret" {
  name = "${local.project}-app-rds-secret"
  role = data.terraform_remote_state.k8s.outputs.app_pod_identity_role_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "ReadExactRdsManagedSecret"
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      Resource = aws_db_instance.this.master_user_secret[0].secret_arn
      Condition = {
        Bool = { "aws:SecureTransport" = "true" }
      }
      }, {
      Sid      = "DecryptExactRdsManagedSecret"
      Effect   = "Allow"
      Action   = "kms:Decrypt"
      Resource = aws_kms_key.rds.arn
      Condition = {
        StringEquals = {
          "kms:ViaService"                  = "secretsmanager.${var.aws_region}.amazonaws.com"
          "kms:EncryptionContext:SecretARN" = aws_db_instance.this.master_user_secret[0].secret_arn
        }
      }
    }]
  })
}
