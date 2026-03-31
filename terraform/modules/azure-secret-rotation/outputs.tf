output "function_app_id" {
  description = "The ID of the rotation Function App."
  value       = azurerm_linux_function_app.this.id
}

output "function_app_name" {
  description = "The name of the rotation Function App."
  value       = azurerm_linux_function_app.this.name
}

output "event_grid_topic_id" {
  description = "The ID of the Event Grid system topic monitoring the Key Vault."
  value       = azurerm_eventgrid_system_topic.this.id
}

output "managed_identity_principal_id" {
  description = "The principal ID of the user-assigned managed identity used by the rotation function."
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "managed_identity_client_id" {
  description = "The client ID of the user-assigned managed identity used by the rotation function."
  value       = azurerm_user_assigned_identity.this.client_id
}
