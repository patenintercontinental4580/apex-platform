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
  environment             = "dev"
  address_space           = "10.1.0.0/22"
  hub_vnet_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-apex-connectivity/providers/Microsoft.Network/virtualNetworks/vnet-apex-hub-uks"
  hub_vnet_name           = "vnet-apex-hub-uks"
  hub_resource_group      = "rg-apex-connectivity"
  hub_firewall_private_ip = "10.0.0.4"
  monthly_budget          = 500
  alert_emails            = ["orders-team@example.com"]
  cost_centre             = "CC-ORDERS"
  subscription_id         = "00000000-0000-0000-0000-000000000000"
}
