# Tests for azure-static-web-app module — runs with `terraform test` (no Azure needed)
mock_provider "azurerm" {}

variables {
  application_name = "orders"
  environment      = "prod"
  team             = "platform-engineering"
  cost_centre      = "PLATFORM-001"
  location         = "uksouth"
  instance_number  = 1
}

run "naming_follows_convention" {
  command = plan

  assert {
    condition     = output.static_site_name == "stapp-orders-prod-uks-01"
    error_message = "Static Web App name incorrect: got ${output.static_site_name}"
  }
}

run "rejects_invalid_sku_tier" {
  command = plan

  variables {
    sku_tier = "Premium"
  }

  expect_failures = [var.sku_tier]
}

run "rejects_invalid_environment" {
  command = plan

  variables {
    environment = "production"
  }

  expect_failures = [var.environment]
}
