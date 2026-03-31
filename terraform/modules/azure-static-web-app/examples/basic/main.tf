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
  environment      = "dev"
  team             = "platform-team"
  cost_centre      = "CC-001"
}

output "default_host_name" {
  value = module.static_web_app.static_site_default_host_name
}
