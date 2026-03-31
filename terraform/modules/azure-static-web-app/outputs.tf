output "static_site_id" {
  description = "The ID of the Static Web App."
  value       = azurerm_static_site.this.id
}

output "static_site_name" {
  description = "The name of the Static Web App."
  value       = azurerm_static_site.this.name
}

output "static_site_default_host_name" {
  description = "The default host name of the Static Web App."
  value       = azurerm_static_site.this.default_host_name
}

output "static_site_api_key" {
  description = "The API key for deploying to the Static Web App."
  value       = azurerm_static_site.this.api_key
  sensitive   = true
}

output "resource_group_name" {
  description = "The name of the resource group."
  value       = azurerm_resource_group.this.name
}
