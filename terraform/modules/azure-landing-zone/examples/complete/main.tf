terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
      configuration_aliases = [azurerm.hub]
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azurerm" {
  alias   = "hub"
  features {}
}

module "orders_landing_zone" {
  source = "../../"

  providers = {
    azurerm     = azurerm
    azurerm.hub = azurerm.hub
  }

  team_name               = "orders"
  environment             = "prod"
  location                = "uksouth"
  address_space           = "10.1.0.0/22"
  hub_vnet_id             = var.hub_vnet_id
  hub_vnet_name           = var.hub_vnet_name
  hub_resource_group      = var.hub_resource_group
  hub_firewall_private_ip = var.hub_firewall_private_ip
  monthly_budget          = 2000
  alert_emails            = ["orders-team@example.com"]
  escalation_emails       = ["platform-team@example.com", "finance@example.com"]
  cost_centre             = "CC-ORDERS"
  subscription_id         = var.subscription_id
  budget_start_date       = "2024-01-01T00:00:00Z"
}

variable "hub_vnet_id" {
  type        = string
  description = "The resource ID of the hub VNet."
}

variable "hub_vnet_name" {
  type        = string
  description = "The name of the hub VNet."
}

variable "hub_resource_group" {
  type        = string
  description = "The resource group of the hub VNet."
}

variable "hub_firewall_private_ip" {
  type        = string
  description = "The private IP of the hub Azure Firewall."
}

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID."
}

output "vnet_id" {
  value = module.orders_landing_zone.vnet_id
}

output "vnet_name" {
  value = module.orders_landing_zone.vnet_name
}

output "application_subnet_id" {
  value = module.orders_landing_zone.application_subnet_id
}

output "data_subnet_id" {
  value = module.orders_landing_zone.data_subnet_id
}

output "private_endpoint_subnet_id" {
  value = module.orders_landing_zone.private_endpoint_subnet_id
}

output "integration_subnet_id" {
  value = module.orders_landing_zone.integration_subnet_id
}

output "budget_id" {
  value = module.orders_landing_zone.budget_id
}
