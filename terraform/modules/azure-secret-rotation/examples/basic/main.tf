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
  environment                = "dev"
  key_vault_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-orders-dev-uks/providers/Microsoft.KeyVault/vaults/kv-orders-dev-uks"
  key_vault_name             = "kv-orders-dev-uks"
  rotation_function_name     = "RotateDatabasePassword"
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-platform-shared/providers/Microsoft.OperationalInsights/workspaces/log-platform-uks"
}

output "function_app_name" {
  value = module.secret_rotation.function_app_name
}
