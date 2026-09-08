mock_provider "aws" {}

run "database_contract" {
  command = plan

  variables {
    state_bucket = "soat-oficina-test-state"
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
