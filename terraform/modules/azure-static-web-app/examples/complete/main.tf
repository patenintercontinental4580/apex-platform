terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.80" }
  }
}

provider "azurerm" { features {} }

module "static_web_app" {
  source = "../../"

  application_name = "portal"
  environment      = "prod"
  team             = "platform-team"
  cost_centre      = "CC-PLATFORM"
  location         = "uksouth"
  instance_number  = 1
  sku_tier         = "Standard"
  custom_domain    = var.custom_domain
}

variable "custom_domain" {
  type        = string
  description = "The custom domain name to associate with the Static Web App."
}

output "static_site_id" {
  value = module.static_web_app.static_site_id
}

output "default_host_name" {
  value = module.static_web_app.static_site_default_host_name
}

output "resource_group_name" {
  value = module.static_web_app.resource_group_name
}
