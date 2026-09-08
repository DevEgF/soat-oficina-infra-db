locals {
  project = "soat-oficina"

  tags = {
    Component       = "infra-db"
    Project         = local.project
    ManagedBy       = "terraform"
    Phase           = "3"
    CreatedBy       = "rds-oss-skill"
    GenerationModel = "gpt-5.6"
  }
}
