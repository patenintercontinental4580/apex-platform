terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-apex-platform-tfstate-uks"
    storage_account_name = "stapexplatformtfstate"
    container_name       = "tfstate"
    key                  = "services/${{ values.serviceName }}/${var.environment}/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

variable "environment" {
  type        = string
  description = "The deployment environment (dev, staging, prod)."
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}

variable "container_image" {
  type        = string
  description = "The container image to deploy, including tag."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "The resource ID of the Log Analytics workspace."
}

locals {
  team        = "${{ values.owningTeam }}"
  cost_centre = upper(replace("${{ values.owningTeam }}", "-", ""))
}

module "key_vault" {
  source = "../../../../terraform/modules/azure-key-vault"

  application_name           = "${{ values.serviceName }}"
  environment                = var.environment
  team                       = local.team
  cost_centre                = local.cost_centre
  log_analytics_workspace_id = var.log_analytics_workspace_id
  enable_purge_protection    = var.environment == "prod"
  enable_private_endpoint    = false # Set to true and provide subnet_id for VNet-integrated deployments
}

module "container_app" {
  source = "../../../../terraform/modules/azure-container-app"

  application_name           = "${{ values.serviceName }}"
  environment                = var.environment
  team                       = local.team
  cost_centre                = local.cost_centre
  container_image            = var.container_image
  log_analytics_workspace_id = var.log_analytics_workspace_id
  min_replicas               = var.environment == "prod" ? 2 : 0
  max_replicas               = var.environment == "prod" ? 10 : 3
  health_check_path          = "/healthz"

  environment_variables = {
    "ASPNETCORE_ENVIRONMENT" = var.environment == "prod" ? "Production" : "Development"
    "KeyVault__Uri"          = module.key_vault.key_vault_uri
  }
}

# Grant the Container App managed identity access to Key Vault secrets
resource "azurerm_role_assignment" "container_app_kv_reader" {
  scope                = module.key_vault.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.container_app.managed_identity_principal_id
}

output "container_app_fqdn" {
  description = "The FQDN of the deployed Container App."
  value       = module.container_app.container_app_fqdn
}

output "key_vault_uri" {
  description = "The URI of the Key Vault."
  value       = module.key_vault.key_vault_uri
}
