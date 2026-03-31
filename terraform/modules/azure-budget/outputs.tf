output "budget_id" {
  description = "The ID of the consumption budget."
  value       = azurerm_consumption_budget_subscription.this.id
}

output "budget_name" {
  description = "The name of the consumption budget."
  value       = azurerm_consumption_budget_subscription.this.name
}
