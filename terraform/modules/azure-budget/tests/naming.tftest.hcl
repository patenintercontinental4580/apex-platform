# Tests for azure-budget module — runs with `terraform test` (no Azure needed)
mock_provider "azurerm" {}

variables {
  application_name = "orders"
  environment      = "production"
  location         = "uksouth"
  instance_number  = 1
  amount           = 1000
  contact_emails   = ["platform@example.com"]
  subscription_id  = "00000000-0000-0000-0000-000000000000"
}

run "budget_name_follows_convention" {
  command = plan

  assert {
    condition     = output.budget_name == "budget-orders-production-uks-01"
    error_message = "Budget name does not follow naming convention: got ${output.budget_name}"
  }
}

run "rejects_zero_amount" {
  command = plan

  variables {
    amount = 0
  }

  expect_failures = [var.amount]
}

run "rejects_empty_contact_emails" {
  command = plan

  variables {
    contact_emails = []
  }

  expect_failures = [var.contact_emails]
}
