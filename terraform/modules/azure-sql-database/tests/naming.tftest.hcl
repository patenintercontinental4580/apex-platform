# Tests for azure-sql-database module — runs with `terraform test` (no Azure needed)
mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      client_id       = "00000000-0000-0000-0000-000000000001"
      tenant_id       = "00000000-0000-0000-0000-000000000002"
      subscription_id = "00000000-0000-0000-0000-000000000003"
      object_id       = "00000000-0000-0000-0000-000000000004"
    }
  }
}

variables {
  application_name           = "orders"
  environment                = "dev"
  team                       = "platform-engineering"
  cost_centre                = "PLATFORM-001"
  location                   = "uksouth"
  instance_number            = 1
  admin_login                = "sqladmin"
  admin_password             = "P@ssw0rd1234!"
  enable_private_endpoint    = false
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/log-platform"
}

run "naming_follows_convention" {
  command = plan

  assert {
    condition     = output.sql_server_name == "sql-orders-dev-uks-01"
    error_message = "SQL Server name incorrect: got ${output.sql_server_name}"
  }

  assert {
    condition     = output.sql_database_name == "sqldb-orders-dev-uks-01"
    error_message = "SQL Database name incorrect: got ${output.sql_database_name}"
  }
}

run "production_backup_guardrail_fails" {
  command = plan

  variables {
    environment           = "prod"
    backup_retention_days = 7
    geo_redundant_backup  = false
  }

  # Precondition is on azurerm_mssql_server, not azurerm_mssql_database
  expect_failures = [azurerm_mssql_server.this]
}

run "production_with_correct_backup_passes" {
  command = plan

  variables {
    environment           = "prod"
    backup_retention_days = 35
    geo_redundant_backup  = true
  }

  assert {
    condition     = output.sql_server_name == "sql-orders-prod-uks-01"
    error_message = "Production SQL Server name incorrect: got ${output.sql_server_name}"
  }
}

run "rejects_invalid_environment" {
  command = plan

  variables {
    environment = "production"
  }

  expect_failures = [var.environment]
}
