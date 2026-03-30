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
# Prerequisites — shared infrastructure consumed by the Container App module.
# In a real deployment these resources would typically live in a separate
# Terraform root module (e.g. a "platform" or "networking" module) and their
# IDs would be passed in via remote state or data sources.
# ---------------------------------------------------------------------------

locals {
  location    = "uksouth"
  environment = "staging"
  common_tags = {
    ManagedBy = "Terraform"
    Team      = "platform"
  }
}

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
  address_space       = ["10.0.0.0/16"]
  tags                = local.common_tags
}

resource "azurerm_subnet" "container_apps" {
  name                 = "snet-containerapps"
  resource_group_name  = azurerm_resource_group.prereqs.name
  virtual_network_name = azurerm_virtual_network.example.name
  # Container App Environments require a /23 or larger subnet
  address_prefixes = ["10.0.0.0/23"]

  delegation {
    name = "delegation-containerapps"
    service_delegation {
      name = "Microsoft.App/environments"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# ---------------------------------------------------------------------------
# Shared Container App Environment
# The environment is created outside the module so that multiple Container
# Apps can share it, avoiding the cost of running a dedicated environment per
# application.
# ---------------------------------------------------------------------------

resource "azurerm_container_app_environment" "shared" {
  name                       = "cae-shared-${local.environment}-uks-01"
  resource_group_name        = azurerm_resource_group.prereqs.name
  location                   = azurerm_resource_group.prereqs.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.shared.id
  infrastructure_subnet_id   = azurerm_subnet.container_apps.id
  tags                       = local.common_tags
}

# ---------------------------------------------------------------------------
# Container App — complete configuration with all optional features enabled.
# ---------------------------------------------------------------------------

module "orders_api" {
  source = "../../"

  # Identity
  application_name = "orders"
  environment      = local.environment
  team             = "platform-engineering"
  cost_centre      = "CC-5678"

  # Location & instance
  location        = local.location
  instance_number = 1

  # Container
  container_image = "myacr.azurecr.io/orders-api:2.3.1"
  cpu             = 1.0
  memory          = "2Gi"
  target_port     = 8080

  # Scaling
  min_replicas = 1
  max_replicas = 10

  # Health checks
  health_check_path = "/healthz"

  # Observability
  log_analytics_workspace_id = azurerm_log_analytics_workspace.shared.id

  # Networking — reuse the shared environment and the pre-existing VNet subnet
  container_app_environment_id = azurerm_container_app_environment.shared.id
  subnet_id                    = azurerm_subnet.container_apps.id

  # Non-sensitive runtime configuration
  environment_variables = {
    ASPNETCORE_ENVIRONMENT     = "Staging"
    OTEL_SERVICE_NAME          = "orders-api"
    OTEL_EXPORTER_OTLP_ENDPOINT = "https://otel-collector.internal:4317"
    LOG_LEVEL                  = "Information"
    FEATURE_FLAG_NEW_CHECKOUT  = "true"
  }

  # Sensitive credentials — stored as Container App secrets and surfaced as
  # environment variables (e.g. db-connection-string → DB_CONNECTION_STRING)
  secrets = {
    db-connection-string = "Server=tcp:orders-sql.database.windows.net,1433;Initial Catalog=orders;Authentication=Active Directory Managed Identity;"
    redis-connection     = "orders-redis.redis.cache.windows.net:6380,password=REDACTED,ssl=True,abortConnect=False"
    servicebus-conn      = "Endpoint=sb://orders-sb.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=REDACTED"
  }
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "container_app_id" {
  description = "Resource ID of the deployed Container App."
  value       = module.orders_api.container_app_id
}

output "container_app_fqdn" {
  description = "Public FQDN of the Container App ingress."
  value       = module.orders_api.container_app_fqdn
}

output "resource_group_name" {
  description = "Name of the resource group created by the module."
  value       = module.orders_api.resource_group_name
}

output "managed_identity_client_id" {
  description = "Client ID of the user-assigned managed identity."
  value       = module.orders_api.managed_identity_client_id
}

output "managed_identity_principal_id" {
  description = "Principal ID of the user-assigned managed identity. Use this for role assignments."
  value       = module.orders_api.managed_identity_principal_id
}

output "application_insights_connection_string" {
  description = "Application Insights connection string (sensitive)."
  value       = module.orders_api.application_insights_connection_string
  sensitive   = true
}
