terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

provider "azurerm" {
  features {}
}

# This example demonstrates the minimum viable configuration for deploying
# a Container App using the azure-container-app module. Only required variables
# are set; all optional variables use their defaults.

resource "azurerm_log_analytics_workspace" "example" {
  name                = "law-orders-dev-uks-01"
  resource_group_name = azurerm_resource_group.prereqs.name
  location            = azurerm_resource_group.prereqs.location
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    ManagedBy = "Terraform"
  }
}

resource "azurerm_resource_group" "prereqs" {
  name     = "rg-prereqs-dev-uks-01"
  location = "uksouth"

  tags = {
    ManagedBy = "Terraform"
  }
}

module "orders_api" {
  source = "../../"

  application_name           = "orders"
  environment                = "dev"
  team                       = "platform"
  cost_centre                = "CC-1234"
  container_image            = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id
}

output "container_app_fqdn" {
  description = "The FQDN of the deployed Container App."
  value       = module.orders_api.container_app_fqdn
}

output "resource_group_name" {
  description = "The name of the resource group created by the module."
  value       = module.orders_api.resource_group_name
}
