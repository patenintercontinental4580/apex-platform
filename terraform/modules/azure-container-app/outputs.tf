output "container_app_id" {
  description = "The ID of the Container App."
  value       = azurerm_container_app.this.id
}

output "container_app_name" {
  description = "The name of the Container App."
  value       = azurerm_container_app.this.name
}

output "container_app_fqdn" {
  description = "The FQDN of the Container App ingress."
  value       = azurerm_container_app.this.ingress[0].fqdn
}

output "resource_group_name" {
  description = "The name of the resource group."
  value       = azurerm_resource_group.this.name
}

output "managed_identity_id" {
  description = "The ID of the user-assigned managed identity."
  value       = azurerm_user_assigned_identity.this.id
}

output "managed_identity_client_id" {
  description = "The client ID of the user-assigned managed identity."
  value       = azurerm_user_assigned_identity.this.client_id
}

output "managed_identity_principal_id" {
  description = "The principal ID of the user-assigned managed identity."
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "application_insights_connection_string" {
  description = "The Application Insights connection string."
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}

output "application_insights_instrumentation_key" {
  description = "The Application Insights instrumentation key."
  value       = azurerm_application_insights.this.instrumentation_key
  sensitive   = true
}
