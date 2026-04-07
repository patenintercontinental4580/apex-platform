mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      client_id       = "00000000-0000-0000-0000-000000000001"
      tenant_id       = "00000000-0000-0000-0000-000000000002"
      subscription_id = "00000000-0000-0000-0000-000000000003"
      object_id       = "00000000-0000-0000-0000-000000000004"
    }
  }
}

# Test 1: Valid configuration produces correct naming output
run "valid_naming_convention" {
  command = plan

  variables {
    application_name           = "orders"
    environment                = "dev"
    team                       = "orders-team"
    cost_centre                = "CC-001"
    container_image            = "nginx:1.25"
    log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/log-test"
    location                   = "uksouth"
    instance_number            = 1
  }

  assert {
    condition     = output.container_app_name == "ca-orders-dev-uks-01"
    error_message = "Container App name must follow ca-{app}-{env}-{region}-{instance}. Got: ${output.container_app_name}"
  }

  assert {
    condition     = output.resource_group_name == "rg-orders-dev-uks-01"
    error_message = "Resource group name must follow rg-{app}-{env}-{region}-{instance}. Got: ${output.resource_group_name}"
  }
}

# Test 2: Invalid application_name is rejected
run "invalid_application_name_rejected" {
  command = plan

  variables {
    application_name           = "INVALID_NAME!"
    environment                = "dev"
    team                       = "orders-team"
    cost_centre                = "CC-001"
    container_image            = "nginx:1.25"
    log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/log-test"
  }

  expect_failures = [
    var.application_name,
  ]
}

# Test 3: Invalid environment is rejected
run "invalid_environment_rejected" {
  command = plan

  variables {
    application_name           = "orders"
    environment                = "production"
    team                       = "orders-team"
    cost_centre                = "CC-001"
    container_image            = "nginx:1.25"
    log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/log-test"
  }

  expect_failures = [
    var.environment,
  ]
}

# Test 4: Production environment with min_replicas < 2 is rejected
run "prod_min_replicas_guardrail" {
  command = plan

  variables {
    application_name           = "orders"
    environment                = "prod"
    min_replicas               = 1
    team                       = "orders-team"
    cost_centre                = "CC-001"
    container_image            = "nginx:1.25"
    log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/log-test"
  }

  expect_failures = [
    azurerm_container_app.this,
  ]
}

# Test 5: westeurope region produces correct short code
run "region_short_code_westeurope" {
  command = plan

  variables {
    application_name           = "orders"
    environment                = "staging"
    team                       = "orders-team"
    cost_centre                = "CC-001"
    container_image            = "nginx:1.25"
    log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/log-test"
    location                   = "westeurope"
    instance_number            = 2
  }

  assert {
    condition     = output.container_app_name == "ca-orders-staging-weu-02"
    error_message = "Container App name with westeurope must use 'weu' region code. Got: ${output.container_app_name}"
  }
}
