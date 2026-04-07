# Tests for azure-landing-zone module — runs with `terraform test` (no Azure needed)
mock_provider "azurerm" {
  alias = "hub"
}
mock_provider "azurerm" {}

variables {
  team_name               = "orders"
  environment             = "prod"
  cost_centre             = "PLATFORM-001"
  location                = "uksouth"
  address_space           = ["10.10.0.0/22"]
  hub_vnet_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-connectivity/providers/Microsoft.Network/virtualNetworks/vnet-hub"
  hub_vnet_name           = "vnet-hub"
  hub_resource_group      = "rg-connectivity-prod-uks-01"
  hub_firewall_private_ip = "10.0.1.4"
  monthly_budget          = 500
  alert_emails            = ["platform@example.com"]
  subscription_id         = "00000000-0000-0000-0000-000000000000"
}

run "vnet_output_exists" {
  command = plan

  assert {
    condition     = output.vnet_id != null
    error_message = "vnet_id output should not be null"
  }
}

run "rejects_invalid_environment" {
  command = plan

  variables {
    environment = "production"
  }

  expect_failures = [var.environment]
}
