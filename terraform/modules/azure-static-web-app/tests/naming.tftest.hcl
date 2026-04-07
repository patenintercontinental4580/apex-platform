# Tests for azure-static-web-app module — runs with `terraform test` (no Azure needed)
mock_provider "azurerm" {}

variables {
  application_name = "orders"
  environment      = "production"
  location         = "uksouth"
  instance_number  = 1
}

run "naming_follows_convention" {
  command = plan

  assert {
    condition     = output.static_web_app_name == "stapp-orders-production-uks-01"
    error_message = "Static Web App name does not follow naming convention: got ${output.static_web_app_name}"
  }
}

run "rejects_invalid_sku_tier" {
  command = plan

  variables {
    sku_tier = "Premium"
  }

  expect_failures = [var.sku_tier]
}
