locals {
  project = "soat-oficina"

  tags = {
    Project         = local.project
    ManagedBy       = "terraform"
    Phase           = "3"
    CreatedBy       = "rds-oss-skill"
    GenerationModel = "gpt-5.6"
  }
}
