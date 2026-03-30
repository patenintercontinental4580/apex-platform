data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.default_tags
}

# ---------------------------------------------------------------------------
# SQL Server
# ---------------------------------------------------------------------------

resource "azurerm_mssql_server" "this" {
  name                          = local.sql_server_name
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  version                       = "12.0"
  administrator_login           = var.admin_login
  administrator_login_password  = var.admin_password
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  tags                          = local.default_tags

  dynamic "azuread_administrator" {
    for_each = var.entra_admin_object_id != null ? [1] : []
    content {
      login_username = var.entra_admin_login != null ? var.entra_admin_login : "EntraAdmin"
      object_id      = var.entra_admin_object_id
      tenant_id      = data.azurerm_client_config.current.tenant_id
    }
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    precondition {
      condition     = !(var.environment == "prod" && var.backup_retention_days < 35)
      error_message = "Production SQL databases must have backup_retention_days set to 35."
    }

    precondition {
      condition     = !(var.environment == "prod" && !var.geo_redundant_backup)
      error_message = "Production SQL databases must have geo_redundant_backup = true."
    }
  }
}

# ---------------------------------------------------------------------------
# SQL Database
# ---------------------------------------------------------------------------

resource "azurerm_mssql_database" "this" {
  name               = local.sql_database_name
  server_id          = azurerm_mssql_server.this.id
  sku_name           = var.sku_name
  max_size_gb        = var.max_size_gb
  geo_backup_enabled = var.geo_redundant_backup
  tags               = local.default_tags

  short_term_retention_policy {
    retention_days           = var.backup_retention_days
    backup_interval_in_hours = 12
  }

  long_term_retention_policy {
    weekly_retention  = var.environment == "prod" ? "P4W" : "PT0S"
    monthly_retention = var.environment == "prod" ? "P12M" : "PT0S"
    yearly_retention  = var.environment == "prod" ? "P5Y" : "PT0S"
    week_of_year      = var.environment == "prod" ? 1 : null
  }
}

# ---------------------------------------------------------------------------
# Server Auditing
# ---------------------------------------------------------------------------

resource "azurerm_mssql_server_extended_auditing_policy" "this" {
  server_id              = azurerm_mssql_server.this.id
  log_monitoring_enabled = true
  retention_in_days      = 90
}

# ---------------------------------------------------------------------------
# Private Endpoint
# ---------------------------------------------------------------------------

resource "azurerm_private_endpoint" "this" {
  count               = var.enable_private_endpoint && var.subnet_id != null ? 1 : 0
  name                = local.private_endpoint_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  subnet_id           = var.subnet_id
  tags                = local.default_tags

  private_service_connection {
    name                           = "psc-${local.sql_server_name}"
    private_connection_resource_id = azurerm_mssql_server.this.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "pdnszg-${local.sql_server_name}"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }
}

# ---------------------------------------------------------------------------
# Diagnostic Settings — master database (captures server-level audit events)
# ---------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "this" {
  name                       = "diag-${local.sql_server_name}"
  target_resource_id         = "${azurerm_mssql_server.this.id}/databases/master"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "SQLSecurityAuditEvents"
  }

  metric {
    category = "Basic"
  }
}
