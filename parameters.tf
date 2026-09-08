resource "aws_db_parameter_group" "postgres16" {
  name        = "${local.project}-postgres16"
  description = "PostgreSQL 16 parameters with TLS enforcement"
  family      = "postgres16"

  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "pending-reboot"
  }
}
