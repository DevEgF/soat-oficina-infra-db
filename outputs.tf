output "database_name" {
  description = "Shared PostgreSQL database name."
  value       = aws_db_instance.this.db_name
}

output "database_port" {
  description = "PostgreSQL listener port."
  value       = 5432
}

output "rds_security_group_id" {
  description = "Security group that protects the RDS instance."
  value       = aws_security_group.rds.id
}

output "db_subnet_group_name" {
  description = "Private subnet group used by RDS."
  value       = aws_db_subnet_group.this.name
}

output "database_endpoint" {
  description = "Private RDS hostname consumed by application runtimes."
  value       = aws_db_instance.this.address
  sensitive   = true
}

output "master_secret_arn" {
  description = "ARN of the RDS-managed master credential."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
  sensitive   = true
}

output "database_kms_key_arn" {
  description = "Customer-managed KMS key metadata for exact runtime decryption permissions."
  value       = aws_kms_key.rds.arn
}

output "database_alarm_names" {
  description = "CloudWatch alarms that protect the managed database."
  value = [
    aws_cloudwatch_metric_alarm.cpu.alarm_name,
    aws_cloudwatch_metric_alarm.storage.alarm_name,
    aws_cloudwatch_metric_alarm.connections.alarm_name,
  ]
}
