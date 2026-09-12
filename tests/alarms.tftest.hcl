mock_provider "aws" {}

run "database_alarms" {
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
    condition = alltrue([
      for alarm in [
        aws_cloudwatch_metric_alarm.cpu,
        aws_cloudwatch_metric_alarm.storage,
        aws_cloudwatch_metric_alarm.connections,
      ] : alarm.evaluation_periods == 3 && alarm.datapoints_to_alarm == 2 && alarm.period == 60
    ])
    error_message = "database alarms must evaluate two breaching points out of three one-minute periods"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.storage.treat_missing_data == "breaching"
    error_message = "missing storage data must alert"
  }

  assert {
    condition = alltrue([
      for alarm in [aws_cloudwatch_metric_alarm.cpu, aws_cloudwatch_metric_alarm.connections] :
      alarm.treat_missing_data == "notBreaching"
    ])
    error_message = "missing CPU or connection data must not alert"
  }

  assert {
    condition = alltrue([
      for alarm in [
        aws_cloudwatch_metric_alarm.cpu,
        aws_cloudwatch_metric_alarm.storage,
        aws_cloudwatch_metric_alarm.connections,
      ] : toset(alarm.alarm_actions) == toset(["arn:aws:sns:us-east-1:111122223333:soat-oficina-alerts"]) && toset(alarm.ok_actions) == toset(["arn:aws:sns:us-east-1:111122223333:soat-oficina-alerts"])
    ])
    error_message = "all database alarms must notify the shared SNS topic on alarm and recovery"
  }
}
