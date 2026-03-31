resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.default_tags
}

resource "azurerm_user_assigned_identity" "this" {
  name                = local.identity_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = local.default_tags
}

resource "azurerm_storage_account" "this" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = local.default_tags
}

resource "azurerm_service_plan" "this" {
  name                = local.service_plan_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  os_type             = "Linux"
  sku_name            = "Y1"
  tags                = local.default_tags
}

resource "azurerm_linux_function_app" "this" {
  name                          = local.function_app_name
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  service_plan_id               = azurerm_service_plan.this.id
  storage_account_name          = azurerm_storage_account.this.name
  storage_uses_managed_identity = true
  tags                          = local.default_tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

  app_settings = {
    "KEY_VAULT_URI"          = "https://${var.key_vault_name}.vault.azure.net/"
    "ROTATION_INTERVAL_DAYS" = tostring(var.rotation_interval_days)
    "SECRET_TYPES"           = join(",", var.secret_types)
    "AZURE_CLIENT_ID"        = azurerm_user_assigned_identity.this.client_id
  }
}

resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

resource "azurerm_role_assignment" "storage_contributor" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

resource "azurerm_eventgrid_system_topic" "this" {
  name                   = local.topic_name
  resource_group_name    = azurerm_resource_group.this.name
  location               = azurerm_resource_group.this.location
  source_arm_resource_id = var.key_vault_id
  topic_type             = "Microsoft.KeyVault.vaults"
  tags                   = local.default_tags
}

resource "azurerm_eventgrid_system_topic_event_subscription" "this" {
  name                = local.subscription_name
  system_topic        = azurerm_eventgrid_system_topic.this.name
  resource_group_name = azurerm_resource_group.this.name

  included_event_types = ["Microsoft.KeyVault.SecretNearExpiry"]

  webhook_endpoint {
    url = "https://${azurerm_linux_function_app.this.default_hostname}/api/${var.rotation_function_name}"
  }

  retry_policy {
    max_delivery_attempts = 30
    event_time_to_live    = 1440
  }
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  name                       = "diag-${local.function_app_name}"
  target_resource_id         = azurerm_linux_function_app.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "FunctionAppLogs"
  }

  metric {
    category = "AllMetrics"
  }
}
