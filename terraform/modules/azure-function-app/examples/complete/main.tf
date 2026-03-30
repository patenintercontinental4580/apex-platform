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
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

data "azurerm_client_config" "current" {}

# Shared resource group for platform infrastructure
resource "azurerm_resource_group" "platform" {
  name     = "rg-platform-prod-uks-01"
  location = "uksouth"

  tags = {
    Environment = "prod"
    ManagedBy   = "Terraform"
    Repository  = "apex-platform"
  }
}

# Log Analytics Workspace for centralised observability
resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-platform-prod-uks-01"
  resource_group_name = azurerm_resource_group.platform.name
  location            = azurerm_resource_group.platform.location
  sku                 = "PerGB2018"
  retention_in_days   = 90

  tags = {
    Environment = "prod"
    ManagedBy   = "Terraform"
    Repository  = "apex-platform"
  }
}

# Virtual Network for VNet integration
resource "azurerm_virtual_network" "this" {
  name                = "vnet-platform-prod-uks-01"
  resource_group_name = azurerm_resource_group.platform.name
  location            = azurerm_resource_group.platform.location
  address_space       = ["10.0.0.0/16"]

  tags = {
    Environment = "prod"
    ManagedBy   = "Terraform"
    Repository  = "apex-platform"
  }
}

resource "azurerm_subnet" "integration" {
  name                 = "snet-integration-prod-uks-01"
  resource_group_name  = azurerm_resource_group.platform.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "func-delegation"

    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
      ]
    }
  }
}

# Key Vault for secrets management
resource "azurerm_key_vault" "this" {
  name                       = "kv-payments-prod-uks-01"
  resource_group_name        = azurerm_resource_group.platform.name
  location                   = azurerm_resource_group.platform.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  enable_rbac_authorization  = true
  purge_protection_enabled   = true
  soft_delete_retention_days = 90

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = []
  }

  tags = {
    Environment = "prod"
    ManagedBy   = "Terraform"
    Repository  = "apex-platform"
  }
}

# Grant the deploying principal Key Vault Administrator so it can create secrets
resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "app_insights_connection" {
  name         = "applicationinsights-connection-string"
  value        = "InstrumentationKey=00000000-0000-0000-0000-000000000000" # Replace with actual value
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [azurerm_role_assignment.kv_admin]
}

# Complete .NET isolated Function App on a Premium plan with Key Vault and VNet integration
module "payments_function" {
  source = "../../"

  application_name           = "payments"
  environment                = "prod"
  team                       = "platform"
  cost_centre                = "CC-5678"
  location                   = "uksouth"
  instance_number            = 1
  runtime_stack              = "dotnet-isolated"
  runtime_version            = "8"
  plan_type                  = "Premium"
  key_vault_id               = azurerm_key_vault.this.id
  key_vault_name             = azurerm_key_vault.this.name
  subnet_id                  = azurerm_subnet.integration.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  depends_on = [azurerm_key_vault_secret.app_insights_connection]
}

output "function_app_id" {
  description = "The resource ID of the deployed Function App."
  value       = module.payments_function.function_app_id
}

output "function_app_name" {
  description = "The name of the deployed Function App."
  value       = module.payments_function.function_app_name
}

output "function_app_default_hostname" {
  description = "The default hostname of the deployed Function App."
  value       = module.payments_function.function_app_default_hostname
}

output "managed_identity_client_id" {
  description = "The client ID of the managed identity — required for AZURE_CLIENT_ID in workload configuration."
  value       = module.payments_function.managed_identity_client_id
}

output "managed_identity_principal_id" {
  description = "The principal ID of the managed identity — used when granting additional RBAC roles."
  value       = module.payments_function.managed_identity_principal_id
}
