# Tests for azure-function-app module — runs with `terraform test` (no Azure needed)
mock_provider "azurerm" {}

variables {
  application_name           = "orders"
  environment                = "dev"
  team                       = "platform-engineering"
  cost_centre                = "PLATFORM-001"
  location                   = "uksouth"
  instance_number            = 1
  runtime_stack              = "dotnet-isolated"
  runtime_version            = "8"
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/log-platform"
}

run "naming_follows_convention" {
  command = plan

  assert {
    condition     = output.function_app_name == "func-orders-dev-uks-01"
    error_message = "Function App name incorrect: got ${output.function_app_name}"
  }
}

run "rejects_invalid_runtime" {
  command = plan

  variables {
    runtime_stack = "java"
  }

  expect_failures = [var.runtime_stack]
}

run "rejects_invalid_plan_type" {
  command = plan

  variables {
    plan_type = "Basic"
  }

  expect_failures = [var.plan_type]
}

run "rejects_invalid_environment" {
  command = plan

  variables {
    environment = "production"
  }

  expect_failures = [var.environment]
}
