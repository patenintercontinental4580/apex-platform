# Tests for azure-key-vault module — runs with `terraform test` (no Azure needed)
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
  enable_private_endpoint    = false
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/log-platform"
}

run "naming_follows_convention" {
  command = plan

  assert {
    condition     = output.key_vault_name == "kv-orders-dev-uks-01"
    error_message = "Key Vault name incorrect: got ${output.key_vault_name}"
  }

  assert {
    condition     = output.resource_group_name == "rg-orders-dev-uks-01"
    error_message = "Resource group name incorrect: got ${output.resource_group_name}"
  }
}

run "prod_environment_naming" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = output.key_vault_name == "kv-orders-prod-uks-01"
    error_message = "Production Key Vault name incorrect: got ${output.key_vault_name}"
  }
}

run "rejects_invalid_application_name" {
  command = plan

  variables {
    application_name = "INVALID_NAME!"
  }

  expect_failures = [var.application_name]
}

run "rejects_invalid_environment" {
  command = plan

  variables {
    environment = "production"
  }

  expect_failures = [var.environment]
}
