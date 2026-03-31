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

module "budget" {
  source = "../../"

  team            = "orders"
  environment     = "dev"
  subscription_id = "00000000-0000-0000-0000-000000000000"
  monthly_budget  = 500
  alert_emails    = ["orders-team@example.com"]
}

output "budget_id" {
  value = module.budget.budget_id
}

output "budget_name" {
  value = module.budget.budget_name
}
