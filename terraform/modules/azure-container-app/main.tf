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

resource "azurerm_application_insights" "this" {
  name                = local.app_insights_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  workspace_id        = var.log_analytics_workspace_id
  application_type    = "web"
  tags                = local.default_tags
}

resource "azurerm_container_app_environment" "this" {
  count                      = var.container_app_environment_id == null ? 1 : 0
  name                       = local.container_app_env_name
  resource_group_name        = azurerm_resource_group.this.name
  location                   = azurerm_resource_group.this.location
  log_analytics_workspace_id = var.log_analytics_workspace_id
  infrastructure_subnet_id   = var.subnet_id
  tags                       = local.default_tags
}

locals {
  effective_cae_id = var.container_app_environment_id != null ? var.container_app_environment_id : azurerm_container_app_environment.this[0].id
}

resource "azurerm_container_app" "this" {
  name                         = local.container_app_name
  resource_group_name          = azurerm_resource_group.this.name
  container_app_environment_id = local.effective_cae_id
  revision_mode                = "Single"
  tags                         = local.default_tags

  lifecycle {
    precondition {
      condition     = !(var.environment == "prod" && var.min_replicas < 2)
      error_message = "Production Container Apps must have min_replicas >= 2 to ensure high availability."
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  dynamic "secret" {
    for_each = var.secrets
    content {
      name  = secret.key
      value = secret.value
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = var.application_name
      image  = var.container_image
      cpu    = var.cpu
      memory = var.memory

      dynamic "env" {
        for_each = var.environment_variables
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = var.secrets
        content {
          name        = upper(replace(env.key, "-", "_"))
          secret_name = env.key
        }
      }

      liveness_probe {
        transport = "HTTP"
        path      = var.health_check_path
        port      = var.target_port
      }

      readiness_probe {
        transport = "HTTP"
        path      = var.health_check_path
        port      = var.target_port
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = var.target_port

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  name                       = "diag-${local.container_app_name}"
  target_resource_id         = azurerm_container_app.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ContainerAppConsoleLogs"
  }

  enabled_log {
    category = "ContainerAppSystemLogs"
  }

  metric {
    category = "AllMetrics"
  }
}
