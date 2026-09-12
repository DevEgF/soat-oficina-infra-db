mock_provider "aws" {}

run "network_isolation" {
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

  assert {
    condition     = length(aws_db_subnet_group.this.subnet_ids) == 2
    error_message = "RDS needs two private subnets"
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.postgres) == 2
    error_message = "only EKS and Lambda may connect"
  }

  assert {
    condition = alltrue([
      for rule in aws_vpc_security_group_ingress_rule.postgres :
      rule.cidr_ipv4 == null && rule.referenced_security_group_id != null
    ])
    error_message = "PostgreSQL ingress must use only security group references"
  }
  assert {
    condition     = aws_iam_service_linked_role.rds.aws_service_name == "rds.amazonaws.com"
    error_message = "RDS service-linked role must exist before creating the subnet group"
  }

}
