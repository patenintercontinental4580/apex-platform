output "apex_platform_management_group_id" {
  description = "The ID of the Apex Platform root management group."
  value       = azurerm_management_group.apex_platform.id
}

output "landing_zones_management_group_id" {
  description = "The ID of the Landing Zones management group."
  value       = azurerm_management_group.landing_zones.id
}

output "production_management_group_id" {
  description = "The ID of the Production management group."
  value       = azurerm_management_group.production.id
}

output "non_production_management_group_id" {
  description = "The ID of the Non-Production management group."
  value       = azurerm_management_group.non_production.id
}

output "platform_admins_group_object_id" {
  description = "The object ID of the platform admins security group."
  value       = azuread_group.platform_admins.object_id
}

output "platform_engineers_group_object_id" {
  description = "The object ID of the platform engineers security group."
  value       = azuread_group.platform_engineers.object_id
}

output "require_mandatory_tags_policy_id" {
  description = "The ID of the require-mandatory-tags policy definition."
  value       = azurerm_policy_definition.require_mandatory_tags.id
}
