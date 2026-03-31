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

  team              = "orders"
  environment       = "prod"
  subscription_id   = var.subscription_id
  monthly_budget    = 2000
  alert_emails      = ["orders-team@example.com"]
  escalation_emails = ["platform-team@example.com", "finance@example.com"]
  start_date        = "2024-01-01T00:00:00Z"
}

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID."
}

output "budget_id" {
  value = module.budget.budget_id
}

output "budget_name" {
  value = module.budget.budget_name
}
