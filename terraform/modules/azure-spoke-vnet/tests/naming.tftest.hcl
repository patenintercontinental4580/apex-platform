# Tests for azure-spoke-vnet module — runs with `terraform test` (no Azure needed)
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
}

run "naming_follows_convention" {
  command = plan

  assert {
    condition     = output.vnet_name == "vnet-orders-production-uks-01"
    error_message = "VNet name does not follow naming convention: got ${output.vnet_name}"
  }

  assert {
    condition     = output.resource_group_name == "rg-orders-production-uks-01"
    error_message = "Resource group name incorrect: got ${output.resource_group_name}"
  }
}

run "subnet_names_follow_convention" {
  command = plan

  assert {
    condition     = contains(keys(output.subnet_ids), "ApplicationSubnet")
    error_message = "ApplicationSubnet missing from subnet_ids output"
  }

  assert {
    condition     = contains(keys(output.subnet_ids), "DataSubnet")
    error_message = "DataSubnet missing from subnet_ids output"
  }

  assert {
    condition     = contains(keys(output.subnet_ids), "PrivateEndpointSubnet")
    error_message = "PrivateEndpointSubnet missing from subnet_ids output"
  }

  assert {
    condition     = contains(keys(output.subnet_ids), "IntegrationSubnet")
    error_message = "IntegrationSubnet missing from subnet_ids output"
  }
}

run "rejects_invalid_environment" {
  command = plan

  variables {
    environment = "prod"
  }

  expect_failures = [var.environment]
}

run "rejects_invalid_cidr" {
  command = plan

  variables {
    vnet_address_space = ["10.10.0.0/16"]
  }

  expect_failures = [var.vnet_address_space]
}
