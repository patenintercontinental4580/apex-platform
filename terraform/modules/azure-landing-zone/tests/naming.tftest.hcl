# Tests for azure-landing-zone module — runs with `terraform test` (no Azure needed)
mock_provider "azurerm" {
  alias = "hub"
}
mock_provider "azurerm" {}

variables {
  application_name        = "orders"
  environment             = "production"
  location                = "uksouth"
  instance_number         = 1
  vnet_address_space      = ["10.10.0.0/22"]
  hub_vnet_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-connectivity/providers/Microsoft.Network/virtualNetworks/vnet-hub"
  hub_firewall_private_ip = "10.0.1.4"
  budget_amount           = 500
  budget_contact_emails   = ["platform@example.com"]
  subscription_id         = "00000000-0000-0000-0000-000000000000"
}

run "vnet_output_exists" {
  command = plan

  assert {
    condition     = output.vnet_id != ""
    error_message = "vnet_id output should not be empty"
  }
}

run "rejects_invalid_environment" {
  command = plan

  variables {
    environment = "prod"
  }

  expect_failures = [var.environment]
}
