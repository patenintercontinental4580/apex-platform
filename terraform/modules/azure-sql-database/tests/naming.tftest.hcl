# Tests for azure-sql-database module — runs with `terraform test` (no Azure needed)
mock_provider "azurerm" {}

variables {
  application_name             = "orders"
  environment                  = "development"
  location                     = "uksouth"
  instance_number              = 1
  administrator_login          = "sqladmin"
  administrator_login_password = "P@ssw0rd1234!"
}

run "naming_follows_convention" {
  command = plan

  assert {
    condition     = output.server_name == "sql-orders-development-uks-01"
    error_message = "SQL Server name does not follow naming convention: got ${output.server_name}"
  }

  assert {
    condition     = output.database_name == "sqldb-orders-development-uks-01"
    error_message = "SQL Database name incorrect: got ${output.database_name}"
  }
}

run "production_backup_guardrail" {
  command = plan

  variables {
    environment           = "production"
    backup_retention_days = 7
    geo_redundant_backup  = false
  }

  expect_failures = [azurerm_mssql_database.this]
}

run "production_backup_passes_with_correct_config" {
  command = plan

  variables {
    environment           = "production"
    backup_retention_days = 35
    geo_redundant_backup  = true
  }

  assert {
    condition     = output.server_name == "sql-orders-production-uks-01"
    error_message = "Production SQL Server name incorrect: got ${output.server_name}"
  }
}

run "rejects_invalid_environment" {
  command = plan

  variables {
    environment = "prod"
  }

  expect_failures = [var.environment]
}
