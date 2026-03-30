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
# Complete example — Key Vault with private endpoint, Private DNS Zone
# integration, RBAC assignments, premium SKU, and full diagnostic settings.
# Reflects a production-grade deployment on the Apex Platform.
# ---------------------------------------------------------------------------

locals {
  location    = "uksouth"
  environment = "prod"
  common_tags = {
    ManagedBy = "Terraform"
    Team      = "platform-engineering"
  }
}

# ---------------------------------------------------------------------------
# Prerequisites — shared infrastructure that would typically be managed by a
# separate platform/networking module and referenced via remote state.
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "prereqs" {
  name     = "rg-prereqs-${local.environment}-uks-01"
  location = local.location
  tags     = local.common_tags
}

resource "azurerm_log_analytics_workspace" "shared" {
  name                = "law-shared-${local.environment}-uks-01"
  resource_group_name = azurerm_resource_group.prereqs.name
  location            = azurerm_resource_group.prereqs.location
  sku                 = "PerGB2018"
  retention_in_days   = 90
  tags                = local.common_tags
}

resource "azurerm_virtual_network" "example" {
  name                = "vnet-${local.environment}-uks-01"
  resource_group_name = azurerm_resource_group.prereqs.name
  location            = azurerm_resource_group.prereqs.location
  address_space       = ["10.1.0.0/16"]
  tags                = local.common_tags
}

resource "azurerm_subnet" "endpoints" {
  name                 = "snet-private-endpoints"
  resource_group_name  = azurerm_resource_group.prereqs.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.1.1.0/24"]

  # Private endpoints do not require a service delegation
}

resource "azurerm_private_dns_zone" "key_vault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.prereqs.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "key_vault" {
  name                  = "pdnslink-kv-${local.environment}"
  resource_group_name   = azurerm_resource_group.prereqs.name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault.name
  virtual_network_id    = azurerm_virtual_network.example.id
  registration_enabled  = false
  tags                  = local.common_tags
}

# ---------------------------------------------------------------------------
# Managed identities whose principal IDs are used in the RBAC assignments.
# In practice these would be the identities of Container Apps, Azure Functions,
# or service principals that need access to the vault.
# ---------------------------------------------------------------------------

resource "azurerm_user_assigned_identity" "payments_api" {
  name                = "id-payments-${local.environment}-uks-01"
  resource_group_name = azurerm_resource_group.prereqs.name
  location            = azurerm_resource_group.prereqs.location
  tags                = local.common_tags
}

resource "azurerm_user_assigned_identity" "payments_worker" {
  name                = "id-payworker-${local.environment}-uks-01"
  resource_group_name = azurerm_resource_group.prereqs.name
  location            = azurerm_resource_group.prereqs.location
  tags                = local.common_tags
}

# ---------------------------------------------------------------------------
# Key Vault — complete configuration
# ---------------------------------------------------------------------------

module "payments_kv" {
  source = "../../"

  # Identity
  application_name = "payments"
  environment      = local.environment
  team             = "platform-engineering"
  cost_centre      = "CC-5678"

  # Location & instance
  location        = local.location
  instance_number = 1

  # Vault configuration
  sku_name                   = "premium"
  enable_purge_protection    = true
  soft_delete_retention_days = 90

  # Observability
  log_analytics_workspace_id = azurerm_log_analytics_workspace.shared.id

  # Private networking
  enable_private_endpoint = true
  subnet_id               = azurerm_subnet.endpoints.id
  private_dns_zone_id     = azurerm_private_dns_zone.key_vault.id

  # RBAC — grant the payments API read access and the worker officer-level access
  rbac_assignments = [
    {
      principal_id = azurerm_user_assigned_identity.payments_api.principal_id
      role         = "Key Vault Secrets User"
    },
    {
      principal_id = azurerm_user_assigned_identity.payments_worker.principal_id
      role         = "Key Vault Secrets Officer"
    }
  ]

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.key_vault
  ]
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "key_vault_id" {
  description = "Resource ID of the Key Vault."
  value       = module.payments_kv.key_vault_id
}

output "key_vault_name" {
  description = "Name of the Key Vault."
  value       = module.payments_kv.key_vault_name
}

output "key_vault_uri" {
  description = "URI of the Key Vault."
  value       = module.payments_kv.key_vault_uri
}

output "resource_group_name" {
  description = "Name of the resource group created by the module."
  value       = module.payments_kv.resource_group_name
}

output "private_endpoint_id" {
  description = "Resource ID of the private endpoint."
  value       = module.payments_kv.private_endpoint_id
}

output "payments_api_identity_client_id" {
  description = "Client ID of the payments API managed identity."
  value       = azurerm_user_assigned_identity.payments_api.client_id
}
