output "sql_server_id" {
  description = "The resource ID of the Azure SQL Server."
  value       = azurerm_mssql_server.this.id
}

output "sql_server_name" {
  description = "The name of the Azure SQL Server."
  value       = azurerm_mssql_server.this.name
}

output "sql_server_fqdn" {
  description = "The fully qualified domain name (FQDN) of the Azure SQL Server, e.g. sql-orders-prod-uks-01.database.windows.net."
  value       = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "sql_database_id" {
  description = "The resource ID of the Azure SQL Database."
  value       = azurerm_mssql_database.this.id
}

output "sql_database_name" {
  description = "The name of the Azure SQL Database."
  value       = azurerm_mssql_database.this.name
}

output "resource_group_name" {
  description = "The name of the resource group containing all SQL resources."
  value       = azurerm_resource_group.this.name
}

output "private_endpoint_id" {
  description = "The resource ID of the private endpoint. Returns null when enable_private_endpoint is false or subnet_id is not provided."
  value       = length(azurerm_private_endpoint.this) > 0 ? azurerm_private_endpoint.this[0].id : null
}

output "sql_server_identity_principal_id" {
  description = "The principal (object) ID of the SQL Server's system-assigned managed identity. Use this to grant the server access to Key Vault or other Azure services."
  value       = azurerm_mssql_server.this.identity[0].principal_id
}
