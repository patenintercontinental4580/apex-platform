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

# ---------------------------------------------------------------------------
# Basic example — Key Vault without a private endpoint.
# Suitable for development environments where VNet integration is not required.
# Purge protection is disabled so the vault can be fully deleted between test runs.
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "prereqs" {
  name     = "rg-prereqs-dev-uks-01"
  location = "uksouth"

  tags = {
    ManagedBy = "Terraform"
  }
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = "law-payments-dev-uks-01"
  resource_group_name = azurerm_resource_group.prereqs.name
  location            = azurerm_resource_group.prereqs.location
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    ManagedBy = "Terraform"
  }
}

module "payments_kv" {
  source = "../../"

  application_name           = "payments"
  environment                = "dev"
  team                       = "platform"
  cost_centre                = "CC-1234"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  # Private endpoint is disabled for this minimal dev example
  enable_private_endpoint = false

  # Purge protection disabled to allow full cleanup in development
  enable_purge_protection = false

  # Reduced retention for dev environments
  soft_delete_retention_days = 7
}

output "key_vault_id" {
  description = "The resource ID of the Key Vault."
  value       = module.payments_kv.key_vault_id
}

output "key_vault_name" {
  description = "The name of the Key Vault."
  value       = module.payments_kv.key_vault_name
}

output "key_vault_uri" {
  description = "The URI of the Key Vault."
  value       = module.payments_kv.key_vault_uri
}

output "resource_group_name" {
  description = "The name of the resource group created by the module."
  value       = module.payments_kv.resource_group_name
}
