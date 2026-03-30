output "vnet_id" {
  description = "The resource ID of the spoke VNet."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "The name of the spoke VNet."
  value       = azurerm_virtual_network.this.name
}

output "resource_group_name" {
  description = "The name of the resource group containing all spoke resources."
  value       = azurerm_resource_group.this.name
}

output "application_subnet_id" {
  description = "The resource ID of the ApplicationSubnet."
  value       = azurerm_subnet.application.id
}

output "data_subnet_id" {
  description = "The resource ID of the DataSubnet."
  value       = azurerm_subnet.data.id
}

output "private_endpoint_subnet_id" {
  description = "The resource ID of the PrivateEndpointSubnet."
  value       = azurerm_subnet.private_endpoint.id
}

output "integration_subnet_id" {
  description = "The resource ID of the IntegrationSubnet (delegated to Microsoft.App/environments)."
  value       = azurerm_subnet.integration.id
}

output "route_table_id" {
  description = "The resource ID of the route table attached to the application, data, and integration subnets."
  value       = azurerm_route_table.this.id
}
