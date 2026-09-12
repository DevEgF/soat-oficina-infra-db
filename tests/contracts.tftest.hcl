mock_provider "aws" {}

run "database_contract" {
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
    condition     = output.database_name == "oficina"
    error_message = "database name changed"
  }

  assert {
    condition     = output.database_port == 5432
    error_message = "database port changed"
  }
}
