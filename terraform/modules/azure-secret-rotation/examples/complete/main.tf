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

module "secret_rotation" {
  source = "../../"

  application_name           = "orders"
  environment                = "prod"
  location                   = "uksouth"
  key_vault_id               = var.key_vault_id
  key_vault_name             = var.key_vault_name
  rotation_function_name     = "RotateDatabasePassword"
  rotation_interval_days     = 30
  secret_types               = ["database-password", "storage-access-key"]
  log_analytics_workspace_id = var.log_analytics_workspace_id
}

variable "key_vault_id" {
  type        = string
  description = "The resource ID of the Key Vault whose secrets will be rotated."
}

variable "key_vault_name" {
  type        = string
  description = "The name of the Key Vault."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "The resource ID of the Log Analytics Workspace for diagnostics."
}

output "function_app_id" {
  value = module.secret_rotation.function_app_id
}

output "function_app_name" {
  value = module.secret_rotation.function_app_name
}

output "event_grid_topic_id" {
  value = module.secret_rotation.event_grid_topic_id
}

output "managed_identity_principal_id" {
  value = module.secret_rotation.managed_identity_principal_id
}
