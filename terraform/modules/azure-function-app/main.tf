resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.default_tags
}

resource "azurerm_user_assigned_identity" "this" {
  name                = local.managed_identity_name
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

  # Disable public access for Premium plan or production environments
  public_network_access_enabled = var.plan_type == "Consumption" && var.environment != "prod"

  tags = local.default_tags
}

resource "azurerm_service_plan" "this" {
  name                = local.service_plan_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  os_type             = "Linux"
  sku_name            = var.plan_type == "Consumption" ? "Y1" : "EP1"
  tags                = local.default_tags
}

resource "azurerm_linux_function_app" "this" {
  name                          = local.function_app_name
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  service_plan_id               = azurerm_service_plan.this.id
  storage_account_name          = azurerm_storage_account.this.name
  storage_uses_managed_identity = true
  virtual_network_subnet_id     = var.subnet_id
  tags                          = local.default_tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  site_config {
    application_stack {
      use_dotnet_isolated_runtime = var.runtime_stack == "dotnet-isolated" ? true : null
      dotnet_version              = var.runtime_stack == "dotnet-isolated" ? var.runtime_version : null
      python_version              = var.runtime_stack == "python" ? var.runtime_version : null
      node_version                = var.runtime_stack == "node" ? var.runtime_version : null
    }

    vnet_route_all_enabled = var.subnet_id != null
  }

  app_settings = merge(
    {
      "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.key_vault_name != null ? "@Microsoft.KeyVault(VaultName=${var.key_vault_name};SecretName=applicationinsights-connection-string)" : ""
      "AZURE_CLIENT_ID"                       = azurerm_user_assigned_identity.this.client_id
    },
    var.key_vault_id != null ? {
      "KEY_VAULT_URI" = "https://${var.key_vault_name}.vault.azure.net/"
    } : {}
  )

  depends_on = [
    azurerm_role_assignment.storage_contributor,
  ]
}

resource "azurerm_role_assignment" "storage_contributor" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

resource "azurerm_role_assignment" "key_vault_secrets_user" {
  count                = var.key_vault_id != null ? 1 : 0
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
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
    enabled  = true
  }
}
