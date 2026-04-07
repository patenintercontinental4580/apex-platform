# Tests for azure-key-vault module — runs with `terraform test` (no Azure needed)
mock_provider "azurerm" {}

variables {
  application_name = "orders"
  environment      = "development"
  location         = "uksouth"
  instance_number  = 1
  tenant_id        = "00000000-0000-0000-0000-000000000000"
}

run "naming_follows_convention" {
  command = plan

  assert {
    condition     = output.key_vault_name == "kv-orders-development-uks-01"
    error_message = "Key Vault name does not follow naming convention: got ${output.key_vault_name}"
  }

  assert {
    condition     = output.resource_group_name == "rg-orders-development-uks-01"
    error_message = "Resource group name does not follow naming convention: got ${output.resource_group_name}"
  }
}

run "production_environment_naming" {
  command = plan

  variables {
    environment = "production"
  }

  assert {
    condition     = output.key_vault_name == "kv-orders-production-uks-01"
    error_message = "Production key vault name incorrect: got ${output.key_vault_name}"
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
    environment = "prod"
  }

  expect_failures = [var.environment]
}
