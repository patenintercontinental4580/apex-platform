# Tests for azure-budget module — runs with `terraform test` (no Azure needed)
mock_provider "azurerm" {}

variables {
  team            = "platform-engineering"
  environment     = "prod"
  subscription_id = "00000000-0000-0000-0000-000000000000"
  monthly_budget  = 1000
  alert_emails    = ["platform@example.com"]
}

run "budget_name_follows_convention" {
  command = plan

  assert {
    condition     = output.budget_name != ""
    error_message = "budget_name output should not be empty"
  }
}

run "rejects_zero_budget" {
  command = plan

  variables {
    monthly_budget = 0
  }

  expect_failures = [var.monthly_budget]
}

run "rejects_invalid_environment" {
  command = plan

  variables {
    environment = "production"
  }

  expect_failures = [var.environment]
}
