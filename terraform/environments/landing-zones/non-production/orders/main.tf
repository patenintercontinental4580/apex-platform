terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
      configuration_aliases = [azurerm.hub]
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-apex-platform-tfstate-uks"
    storage_account_name = "stapexplatformtfstate"
    container_name       = "tfstate"
    key                  = "landing-zones/non-production/orders/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

provider "azurerm" {
  alias           = "hub"
  subscription_id = var.hub_subscription_id
  features {}
}

data "terraform_remote_state" "connectivity" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-apex-platform-tfstate-uks"
    storage_account_name = "stapexplatformtfstate"
    container_name       = "tfstate"
    key                  = "connectivity/hub-network.tfstate"
  }
}

variable "hub_subscription_id" {
  type        = string
  description = "The subscription ID where the hub network is deployed."
}

variable "subscription_id" {
  type        = string
  description = "The subscription ID for the orders team non-production landing zone."
}

module "orders_landing_zone" {
  source = "../../../../modules/azure-landing-zone"

  providers = {
    azurerm     = azurerm
    azurerm.hub = azurerm.hub
  }

  team_name               = "orders"
  environment             = "dev"
  address_space           = "10.2.0.0/22"
  location                = "uksouth"
  hub_vnet_id             = data.terraform_remote_state.connectivity.outputs.hub_vnet_id
  hub_vnet_name           = data.terraform_remote_state.connectivity.outputs.hub_vnet_name
  hub_resource_group      = data.terraform_remote_state.connectivity.outputs.hub_resource_group_name
  hub_firewall_private_ip = data.terraform_remote_state.connectivity.outputs.firewall_private_ip
  monthly_budget          = 500
  alert_emails            = ["orders-team@example.com", "platform-team@example.com"]
  escalation_emails       = ["cto@example.com"]
  cost_centre             = "CC-ORDERS"
  subscription_id         = var.subscription_id
}

output "vnet_id" {
  description = "The resource ID of the orders non-production spoke virtual network."
  value       = module.orders_landing_zone.vnet_id
}

output "application_subnet_id" {
  description = "The resource ID of the orders non-production application subnet."
  value       = module.orders_landing_zone.application_subnet_id
}
