terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.80" }
  }
  backend "azurerm" {
    resource_group_name  = "rg-apex-platform-tfstate-uks"
    storage_account_name = "stapexplatformtfstate"
    container_name       = "tfstate"
    key                  = "production/react-frontend.tfstate"
  }
}

provider "azurerm" {
  features {}
}

module "static_web_app" {
  source = "../../../terraform/modules/azure-static-web-app"

  application_name = "apex-frontend"
  environment      = "production"
  location         = "uksouth"
  instance_number  = 1

  sku_tier = "Standard"
  sku_size = "Standard"

  custom_domain_name = var.custom_domain_name

  tags = {
    Team        = "platform-engineering"
    CostCentre  = "PLATFORM-001"
  }
}

variable "custom_domain_name" {
  type    = string
  default = null
}

output "static_web_app_url" {
  value = module.static_web_app.default_host_name
}
