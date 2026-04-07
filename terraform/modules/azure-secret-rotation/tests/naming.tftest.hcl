# Tests for azure-secret-rotation module — runs with `terraform test` (no Azure needed)
mock_provider "azurerm" {}

variables {
  application_name           = "orders"
  environment                = "prod"
  location                   = "uksouth"
  key_vault_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-orders/providers/Microsoft.KeyVault/vaults/kv-orders-prod-uks-01"
  key_vault_name             = "kv-orders-prod-uks-01"
  rotation_function_name     = "rotate-db-password"
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/log-platform"
}

run "function_app_name_follows_convention" {
  command = plan

  assert {
    condition     = output.function_app_name == "func-rot-orders-prod-uks"
    error_message = "Function App name incorrect: got ${output.function_app_name}"
  }
}

run "rejects_invalid_environment" {
  command = plan

  variables {
    environment = "production"
  }

  expect_failures = [var.environment]
}
