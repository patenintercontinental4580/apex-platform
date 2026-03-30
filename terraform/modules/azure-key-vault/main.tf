data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.default_tags
}

resource "azurerm_key_vault" "this" {
  name                       = local.key_vault_name
  resource_group_name        = azurerm_resource_group.this.name
  location                   = azurerm_resource_group.this.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.sku_name
  enable_rbac_authorization  = true
  purge_protection_enabled   = var.enable_purge_protection
  soft_delete_retention_days = var.soft_delete_retention_days
  tags                       = local.default_tags

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
  }

  lifecycle {
    precondition {
      condition     = !(var.environment == "prod" && !var.enable_purge_protection)
      error_message = "Purge protection must be enabled for production Key Vaults."
    }
  }
}

resource "azurerm_role_assignment" "rbac" {
  for_each = { for assignment in var.rbac_assignments : "${assignment.principal_id}-${assignment.role}" => assignment }

  scope                = azurerm_key_vault.this.id
  role_definition_name = each.value.role
  principal_id         = each.value.principal_id
}

resource "azurerm_private_endpoint" "this" {
  count               = var.enable_private_endpoint && var.subnet_id != null ? 1 : 0
  name                = local.private_endpoint_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  subnet_id           = var.subnet_id
  tags                = local.default_tags

  private_service_connection {
    name                           = "psc-${local.key_vault_name}"
    private_connection_resource_id = azurerm_key_vault.this.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "pdnszg-${local.key_vault_name}"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  name                       = "diag-${local.key_vault_name}"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
  }
}
