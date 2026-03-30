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

# Shared Log Analytics Workspace used for diagnostics
resource "azurerm_resource_group" "observability" {
  name     = "rg-observability-dev-uks-01"
  location = "uksouth"
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-observability-dev-uks-01"
  resource_group_name = azurerm_resource_group.observability.name
  location            = azurerm_resource_group.observability.location
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
    Repository  = "apex-platform"
  }
}

# Basic Python Function App on a Consumption plan
module "orders_function" {
  source = "../../"

  application_name           = "orders"
  environment                = "dev"
  team                       = "platform"
  cost_centre                = "CC-1234"
  location                   = "uksouth"
  runtime_stack              = "python"
  runtime_version            = "3.11"
  plan_type                  = "Consumption"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
}

output "function_app_name" {
  description = "The name of the deployed Function App."
  value       = module.orders_function.function_app_name
}

output "function_app_default_hostname" {
  description = "The default hostname of the deployed Function App."
  value       = module.orders_function.function_app_default_hostname
}
