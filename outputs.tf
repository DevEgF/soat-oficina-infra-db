output "database_name" {
  description = "Shared PostgreSQL database name."
  value       = "oficina"
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
