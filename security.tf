locals {
  postgres_sources = {
    eks    = data.terraform_remote_state.k8s.outputs.node_security_group_id
    lambda = data.terraform_remote_state.k8s.outputs.lambda_security_group_id
  }
}

resource "aws_db_subnet_group" "this" {
  depends_on = [aws_iam_service_linked_role.rds]

  name        = "${local.project}-db"
  description = "Private subnet group for the managed PostgreSQL instance"
  subnet_ids  = data.terraform_remote_state.k8s.outputs.private_subnet_ids
}

resource "aws_security_group" "rds" {
  name        = "${local.project}-rds"
  description = "Restricts PostgreSQL access to approved application runtimes"
  vpc_id      = data.terraform_remote_state.k8s.outputs.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "postgres" {
  for_each = local.postgres_sources

  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = each.value
  description                  = "PostgreSQL from ${each.key}"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

# checkov:skip=CKV_AWS_382:RDS response traffic uses a stateful security group and the instance has no public route.
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.rds.id
  description       = "Allow response traffic from the private database"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_iam_service_linked_role" "rds" {
  aws_service_name = "rds.amazonaws.com"
}