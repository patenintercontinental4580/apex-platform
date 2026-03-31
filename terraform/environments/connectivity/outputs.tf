output "hub_resource_group_name" {
  description = "The name of the hub connectivity resource group."
  value       = azurerm_resource_group.connectivity.name
}

output "hub_vnet_id" {
  description = "The ID of the hub virtual network."
  value       = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  description = "The name of the hub virtual network."
  value       = azurerm_virtual_network.hub.name
}

output "firewall_private_ip" {
  description = "The private IP address of the Azure Firewall, used as the next hop for spoke UDRs."
  value       = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}

output "firewall_id" {
  description = "The resource ID of the Azure Firewall."
  value       = azurerm_firewall.hub.id
}

output "log_analytics_workspace_id" {
  description = "The resource ID of the platform Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.platform.id
}

output "log_analytics_workspace_name" {
  description = "The name of the platform Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.platform.name
}

output "private_dns_zone_ids" {
  description = "Map of private DNS zone names to their resource IDs."
  value       = { for k, v in azurerm_private_dns_zone.zones : k => v.id }
}

output "bastion_host_id" {
  description = "The resource ID of the Azure Bastion host."
  value       = azurerm_bastion_host.hub.id
}
