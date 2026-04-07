# Tests for azure-spoke-vnet module — runs with `terraform test` (no Azure needed)
mock_provider "azurerm" {
  alias = "hub"
}
mock_provider "azurerm" {}

variables {
  spoke_name              = "orders"
  environment             = "prod"
  team                    = "platform-engineering"
  cost_centre             = "PLATFORM-001"
  location                = "uksouth"
  address_space           = ["10.10.0.0/22"]
  hub_vnet_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-connectivity/providers/Microsoft.Network/virtualNetworks/vnet-hub"
  hub_vnet_name           = "vnet-hub"
  hub_resource_group      = "rg-connectivity-prod-uks-01"
  hub_firewall_private_ip = "10.0.1.4"
}

run "naming_follows_convention" {
  command = plan

  assert {
    condition     = output.vnet_name == "vnet-orders-prod-uks-01"
    error_message = "VNet name incorrect: got ${output.vnet_name}"
  }

  assert {
    condition     = output.resource_group_name == "rg-orders-prod-uks-01"
    error_message = "Resource group name incorrect: got ${output.resource_group_name}"
  }
}

run "subnet_outputs_exist" {
  command = plan

  assert {
    condition     = output.application_subnet_id != null
    error_message = "application_subnet_id output should not be null"
  }

  assert {
    condition     = output.data_subnet_id != null
    error_message = "data_subnet_id output should not be null"
  }

  assert {
    condition     = output.private_endpoint_subnet_id != null
    error_message = "private_endpoint_subnet_id output should not be null"
  }

  assert {
    condition     = output.integration_subnet_id != null
    error_message = "integration_subnet_id output should not be null"
  }
}

run "rejects_invalid_environment" {
  command = plan

  variables {
    environment = "production"
  }

  expect_failures = [var.environment]
}
