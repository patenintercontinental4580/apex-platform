output "function_app_id" {
  description = "The resource ID of the Linux Function App."
  value       = azurerm_linux_function_app.this.id
}

output "function_app_name" {
  description = "The name of the Linux Function App."
  value       = azurerm_linux_function_app.this.name
}

output "function_app_default_hostname" {
  description = "The default hostname of the Linux Function App."
  value       = azurerm_linux_function_app.this.default_hostname
}

output "resource_group_name" {
  description = "The name of the resource group containing all resources."
  value       = azurerm_resource_group.this.name
}

output "managed_identity_id" {
  description = "The resource ID of the user-assigned managed identity."
  value       = azurerm_user_assigned_identity.this.id
}

output "managed_identity_client_id" {
  description = "The client ID of the user-assigned managed identity."
  value       = azurerm_user_assigned_identity.this.client_id
}

output "managed_identity_principal_id" {
  description = "The principal (object) ID of the user-assigned managed identity."
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "storage_account_name" {
  description = "The name of the Storage Account used by the Function App."
  value       = azurerm_storage_account.this.name
}
