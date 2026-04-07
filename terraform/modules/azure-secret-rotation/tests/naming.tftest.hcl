# Tests for azure-secret-rotation module — runs with `terraform test` (no Azure needed)
mock_provider "azurerm" {}

variables {
  application_name           = "orders"
  environment                = "production"
  location                   = "uksouth"
  instance_number            = 1
  key_vault_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-orders/providers/Microsoft.KeyVault/vaults/kv-orders-prod-uks-01"
  storage_account_name       = "stordersrotdevuks01"
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-connectivity/providers/Microsoft.OperationalInsights/workspaces/log-platform"
}

run "function_app_name_follows_convention" {
  command = plan

  assert {
    condition     = output.function_app_name == "func-orders-production-uks-01"
    error_message = "Function App name does not follow naming convention: got ${output.function_app_name}"
  }
}

run "rejects_invalid_environment" {
  command = plan

  variables {
    environment = "prod"
  }

  expect_failures = [var.environment]
}
