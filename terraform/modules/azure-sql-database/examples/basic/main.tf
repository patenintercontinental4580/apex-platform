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

module "sql_database" {
  source = "../../"

  application_name           = "orders"
  environment                = "dev"
  team                       = "orders-team"
  cost_centre                = "CC-001"
  admin_login                = "sqladmin"
  admin_password             = "P@ssw0rd1234!"  # In production, use Key Vault
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-example/providers/Microsoft.OperationalInsights/workspaces/log-example"
  enable_private_endpoint    = false
  backup_retention_days      = 7
  geo_redundant_backup       = false
}

output "sql_server_fqdn" {
  value = module.sql_database.sql_server_fqdn
}
