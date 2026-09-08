mock_provider "aws" {}

run "managed_rds_contract" {
  command = plan

  variables {
    state_bucket = "soat-oficina-test-state"
  }

  override_data {
    target = data.terraform_remote_state.k8s
    values = {
      outputs = {
        vpc_id                     = "vpc-12345678"
        private_subnet_ids         = ["subnet-11111111", "subnet-22222222"]
        node_security_group_id     = "sg-11111111"
        lambda_security_group_id   = "sg-22222222"
        app_pod_identity_role_name = "soat-oficina-app-pod"
        alerts_topic_arn           = "arn:aws:sns:us-east-1:111122223333:soat-oficina-alerts"
      }
    }
  }

  override_resource {
    target          = aws_db_instance.this
    override_during = plan
    values = {
      address = "soat-oficina-db.example.us-east-1.rds.amazonaws.com"
      master_user_secret = [{
        kms_key_id    = null
        secret_arn    = "arn:aws:secretsmanager:us-east-1:111122223333:secret:rds-db-credentials/example"
        secret_status = "active"
      }]
    }
  }

  override_resource {
    target          = aws_kms_key.rds
    override_during = plan
    values = {
      arn    = "arn:aws:kms:us-east-1:111122223333:key/11111111-2222-3333-4444-555555555555"
      key_id = "11111111-2222-3333-4444-555555555555"
    }
  }

  assert {
    condition     = aws_db_instance.this.engine == "postgres" && startswith(aws_db_instance.this.engine_version, "16")
    error_message = "engine must remain on PostgreSQL major 16"
  }

  assert {
    condition     = aws_db_instance.this.instance_class == "db.t4g.micro"
    error_message = "instance class changed outside the approved cost envelope"
  }

  assert {
    condition     = aws_db_instance.this.publicly_accessible == false && aws_db_instance.this.multi_az == false
    error_message = "RDS must be private and Single-AZ for the academic environment"
  }

  assert {
    condition = (
      aws_db_instance.this.allocated_storage == 20 &&
      aws_db_instance.this.max_allocated_storage == 100 &&
      aws_db_instance.this.storage_type == "gp3" &&
      aws_db_instance.this.storage_encrypted
    )
    error_message = "RDS storage must use the approved encrypted gp3 envelope"
  }

  assert {
    condition     = aws_db_instance.this.manage_master_user_password && aws_db_instance.this.username == "oficina_admin"
    error_message = "RDS must manage a non-default master credential"
  }

  assert {
    condition     = aws_db_instance.this.backup_retention_period == 1 && aws_db_instance.this.deletion_protection
    error_message = "RDS must keep the academic backup window and enable deletion protection"
  }

  assert {
    condition     = aws_db_instance.this.performance_insights_enabled && aws_db_instance.this.iam_database_authentication_enabled
    error_message = "RDS observability and IAM database authentication must be enabled"
  }

  assert {
    condition = (
      aws_db_instance.this.kms_key_id == aws_kms_key.rds.arn &&
      aws_db_instance.this.performance_insights_kms_key_id == aws_kms_key.rds.arn
    )
    error_message = "RDS storage and Performance Insights must use the customer-managed key"
  }

  assert {
    condition = anytrue([
      for parameter in aws_db_parameter_group.postgres16.parameter :
      parameter.name == "rds.force_ssl" && parameter.value == "1"
    ])
    error_message = "PostgreSQL must require TLS"
  }


  assert {
    condition = (
      jsondecode(aws_iam_role_policy.app_rds_secret.policy).Statement[0].Action == "secretsmanager:GetSecretValue" &&
      jsondecode(aws_iam_role_policy.app_rds_secret.policy).Statement[0].Resource == "arn:aws:secretsmanager:us-east-1:111122223333:secret:rds-db-credentials/example"
    )
    error_message = "application policy must read only the exact RDS-managed secret"
  }
}
