# ---------------------------------------------------------------------------
# Example: azure-spoke-vnet — Basic
#
# Provisions a development spoke VNet with all defaults. Both provider
# aliases point at the same subscription to simplify local testing; in a
# real deployment the hub alias would target the hub/connectivity
# subscription.
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

# Default provider — spoke subscription
provider "azurerm" {
  features {}
  # subscription_id = "00000000-0000-0000-0000-000000000001"
}

# Hub provider alias — connectivity/hub subscription
# In this basic example both aliases share the same subscription.
provider "azurerm" {
  alias   = "hub"
  features {}
  # subscription_id = "00000000-0000-0000-0000-000000000000"
}

# ---------------------------------------------------------------------------
# Pre-existing hub resources (already deployed, referenced by ID/name)
# ---------------------------------------------------------------------------

locals {
  hub_subscription_id = "00000000-0000-0000-0000-000000000000"
  hub_rg_name         = "rg-hub-dev-uks"
  hub_vnet_name       = "vnet-hub-dev-uks"
}

# ---------------------------------------------------------------------------
# Spoke VNet Module
# ---------------------------------------------------------------------------

module "orders_spoke_dev" {
  source = "../../"

  providers = {
    azurerm     = azurerm
    azurerm.hub = azurerm.hub
  }

  spoke_name    = "orders"
  address_space = "10.1.0.0/22"
  environment   = "dev"
  team          = "Platform Engineering"
  cost_centre   = "CC-1234"
  location      = "uksouth"

  hub_vnet_id             = "/subscriptions/${local.hub_subscription_id}/resourceGroups/${local.hub_rg_name}/providers/Microsoft.Network/virtualNetworks/${local.hub_vnet_name}"
  hub_vnet_name           = local.hub_vnet_name
  hub_resource_group      = local.hub_rg_name
  hub_firewall_private_ip = "10.0.0.68"
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "vnet_id" {
  description = "Resource ID of the orders dev spoke VNet."
  value       = module.orders_spoke_dev.vnet_id
}

output "application_subnet_id" {
  description = "Resource ID of the ApplicationSubnet."
  value       = module.orders_spoke_dev.application_subnet_id
}
