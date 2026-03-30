# ---------------------------------------------------------------------------
# Example: azure-spoke-vnet — Complete
#
# Provisions a production spoke VNet with the hub peering correctly
# configured across two separate subscriptions. The default provider
# targets the spoke subscription; the hub alias targets the shared
# connectivity subscription.
#
# This example also demonstrates how to feed the spoke outputs into a
# dependent SQL database module that requires the private endpoint subnet.
# ---------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

# ---------------------------------------------------------------------------
# Provider Configuration
# ---------------------------------------------------------------------------

# Default provider — spoke (workload) subscription
provider "azurerm" {
  features {}
  subscription_id = "11111111-1111-1111-1111-111111111111"
}

# Hub alias — shared connectivity subscription
# The module uses this alias to create the hub-to-spoke peering inside
# the hub resource group, which lives in a different subscription.
provider "azurerm" {
  alias           = "hub"
  features {}
  subscription_id = "00000000-0000-0000-0000-000000000000"
}

# ---------------------------------------------------------------------------
# Variables (override via terraform.tfvars or -var flags in CI)
# ---------------------------------------------------------------------------

variable "hub_subscription_id" {
  type        = string
  description = "Subscription ID of the hub/connectivity subscription."
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "spoke_subscription_id" {
  type        = string
  description = "Subscription ID of the spoke/workload subscription."
  default     = "11111111-1111-1111-1111-111111111111"
}

# ---------------------------------------------------------------------------
# Local Values
# ---------------------------------------------------------------------------

locals {
  hub_rg_name   = "rg-hub-prod-uks"
  hub_vnet_name = "vnet-hub-prod-uks"
}

# ---------------------------------------------------------------------------
# Payments Spoke — Production
# ---------------------------------------------------------------------------

module "payments_spoke_prod" {
  source = "../../"

  providers = {
    azurerm     = azurerm
    azurerm.hub = azurerm.hub
  }

  spoke_name    = "payments"
  address_space = "10.2.0.0/22"
  environment   = "prod"
  team          = "Payments Team"
  cost_centre   = "CC-5678"
  location      = "uksouth"

  hub_vnet_id             = "/subscriptions/${var.hub_subscription_id}/resourceGroups/${local.hub_rg_name}/providers/Microsoft.Network/virtualNetworks/${local.hub_vnet_name}"
  hub_vnet_name           = local.hub_vnet_name
  hub_resource_group      = local.hub_rg_name
  hub_firewall_private_ip = "10.0.0.68"
}

# ---------------------------------------------------------------------------
# Orders Spoke — Production (second spoke in the same deployment)
# ---------------------------------------------------------------------------

module "orders_spoke_prod" {
  source = "../../"

  providers = {
    azurerm     = azurerm
    azurerm.hub = azurerm.hub
  }

  spoke_name    = "orders"
  address_space = "10.1.0.0/22"
  environment   = "prod"
  team          = "Orders Team"
  cost_centre   = "CC-1234"
  location      = "uksouth"

  hub_vnet_id             = "/subscriptions/${var.hub_subscription_id}/resourceGroups/${local.hub_rg_name}/providers/Microsoft.Network/virtualNetworks/${local.hub_vnet_name}"
  hub_vnet_name           = local.hub_vnet_name
  hub_resource_group      = local.hub_rg_name
  hub_firewall_private_ip = "10.0.0.68"
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "payments_vnet_id" {
  description = "Resource ID of the payments production spoke VNet."
  value       = module.payments_spoke_prod.vnet_id
}

output "payments_private_endpoint_subnet_id" {
  description = "Resource ID of the payments PrivateEndpointSubnet — pass this to the SQL database module."
  value       = module.payments_spoke_prod.private_endpoint_subnet_id
}

output "payments_integration_subnet_id" {
  description = "Resource ID of the payments IntegrationSubnet — pass this to the Container Apps environment."
  value       = module.payments_spoke_prod.integration_subnet_id
}

output "orders_vnet_id" {
  description = "Resource ID of the orders production spoke VNet."
  value       = module.orders_spoke_prod.vnet_id
}

output "orders_private_endpoint_subnet_id" {
  description = "Resource ID of the orders PrivateEndpointSubnet."
  value       = module.orders_spoke_prod.private_endpoint_subnet_id
}

output "orders_integration_subnet_id" {
  description = "Resource ID of the orders IntegrationSubnet."
  value       = module.orders_spoke_prod.integration_subnet_id
}
