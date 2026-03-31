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
  environment                = "prod"
  team                       = "orders-team"
  cost_centre                = "CC-001"
  location                   = "uksouth"
  instance_number            = 1
  sku_name                   = "S2"
  max_size_gb                = 50
  admin_login                = "sqladmin"
  admin_password             = var.admin_password
  enable_private_endpoint    = true
  subnet_id                  = var.private_endpoint_subnet_id
  private_dns_zone_id        = var.sql_private_dns_zone_id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  backup_retention_days      = 35
  geo_redundant_backup       = true
  entra_admin_object_id      = var.entra_admin_object_id
  entra_admin_login          = "sg-orders-db-admins"
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "private_endpoint_subnet_id" {
  type = string
}

variable "sql_private_dns_zone_id" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "entra_admin_object_id" {
  type = string
}

output "sql_server_fqdn" {
  value = module.sql_database.sql_server_fqdn
}

output "sql_database_name" {
  value = module.sql_database.sql_database_name
}
