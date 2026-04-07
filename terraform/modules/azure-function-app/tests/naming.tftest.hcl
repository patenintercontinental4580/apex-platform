# Tests for azure-function-app module — runs with `terraform test` (no Azure needed)
mock_provider "azurerm" {}

variables {
  application_name           = "orders"
  environment                = "development"
  location                   = "uksouth"
  instance_number            = 1
  storage_account_name       = "stordersfuncdevuks01"
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-connectivity/providers/Microsoft.OperationalInsights/workspaces/log-platform"
}

run "naming_follows_convention" {
  command = plan

  assert {
    condition     = output.function_app_name == "func-orders-development-uks-01"
    error_message = "Function App name does not follow naming convention: got ${output.function_app_name}"
  }
}

run "consumption_plan_naming" {
  command = plan

  variables {
    plan_sku = "Y1"
  }

  assert {
    condition     = output.service_plan_name == "plan-orders-development-uks-01"
    error_message = "Service plan name incorrect: got ${output.service_plan_name}"
  }
}

run "rejects_invalid_runtime" {
  command = plan

  variables {
    runtime_stack = "java"
  }

  expect_failures = [var.runtime_stack]
}

run "rejects_invalid_sku" {
  command = plan

  variables {
    plan_sku = "B1"
  }

  expect_failures = [var.plan_sku]
}
