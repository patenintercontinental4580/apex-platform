terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.80" }
  }
  backend "azurerm" {
    resource_group_name  = "rg-apex-platform-tfstate-uks"
    storage_account_name = "stapexplatformtfstate"
    container_name       = "tfstate"
    key                  = "production/python-django-api.tfstate"
  }
}

provider "azurerm" {
  features {}
}

module "key_vault" {
  source = "../../../terraform/modules/azure-key-vault"

  application_name = "orders-api"
  environment      = "production"
  location         = "uksouth"
  instance_number  = 1

  enable_private_endpoint = true
  subnet_id               = var.private_endpoint_subnet_id

  rbac_assignments = [
    {
      role                             = "Key Vault Secrets User"
      principal_id                     = module.function_app.managed_identity_principal_id
      skip_service_principal_aad_check = false
    }
  ]

  tags = {
    Team       = "platform-engineering"
    CostCentre = "PLATFORM-001"
  }
}

module "sql_database" {
  source = "../../../terraform/modules/azure-sql-database"

  application_name = "orders-api"
  environment      = "production"
  location         = "uksouth"
  instance_number  = 1

  administrator_login          = "apexadmin"
  administrator_login_password = var.sql_admin_password

  sku_name                = "GP_Gen5_2"
  max_size_gb             = 32
  backup_retention_days   = 35
  geo_redundant_backup    = true

  private_endpoint_subnet_id = var.private_endpoint_subnet_id

  tags = {
    Team       = "platform-engineering"
    CostCentre = "PLATFORM-001"
  }
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet ID for private endpoints"
}

variable "sql_admin_password" {
  type        = string
  sensitive   = true
  description = "SQL Server administrator password"
}

output "key_vault_uri" {
  value = module.key_vault.vault_uri
}

output "sql_server_fqdn" {
  value     = module.sql_database.server_fqdn
  sensitive = true
}
