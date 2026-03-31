output "vnet_id" {
  description = "The ID of the spoke VNet."
  value       = module.spoke_vnet.vnet_id
}

output "vnet_name" {
  description = "The name of the spoke VNet."
  value       = module.spoke_vnet.vnet_name
}

output "application_subnet_id" {
  description = "The ID of the ApplicationSubnet."
  value       = module.spoke_vnet.application_subnet_id
}

output "data_subnet_id" {
  description = "The ID of the DataSubnet."
  value       = module.spoke_vnet.data_subnet_id
}

output "private_endpoint_subnet_id" {
  description = "The ID of the PrivateEndpointSubnet."
  value       = module.spoke_vnet.private_endpoint_subnet_id
}

output "integration_subnet_id" {
  description = "The ID of the IntegrationSubnet."
  value       = module.spoke_vnet.integration_subnet_id
}

output "budget_id" {
  description = "The ID of the consumption budget."
  value       = module.budget.budget_id
}
