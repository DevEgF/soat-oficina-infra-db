resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name          = "${local.project}-db-high-cpu"
  alarm_description   = "Managed PostgreSQL CPU utilization exceeded 80 percent"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 80
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.identifier
  }

  alarm_actions = [data.terraform_remote_state.k8s.outputs.alerts_topic_arn]
  ok_actions    = [data.terraform_remote_state.k8s.outputs.alerts_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "storage" {
  alarm_name          = "${local.project}-db-low-storage"
  alarm_description   = "Managed PostgreSQL free storage dropped below 5 GiB"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  comparison_operator = "LessThanThreshold"
  threshold           = 5 * 1024 * 1024 * 1024
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  treat_missing_data  = "breaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.identifier
  }

  alarm_actions = [data.terraform_remote_state.k8s.outputs.alerts_topic_arn]
  ok_actions    = [data.terraform_remote_state.k8s.outputs.alerts_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "connections" {
  alarm_name          = "${local.project}-db-high-connections"
  alarm_description   = "Managed PostgreSQL connections exceeded the safe academic threshold"
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 70
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.identifier
  }

  alarm_actions = [data.terraform_remote_state.k8s.outputs.alerts_topic_arn]
  ok_actions    = [data.terraform_remote_state.k8s.outputs.alerts_topic_arn]
}
