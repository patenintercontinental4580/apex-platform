module "spoke_vnet" {
  source = "../azure-spoke-vnet"

  providers = {
    azurerm     = azurerm
    azurerm.hub = azurerm.hub
  }

  spoke_name              = var.team_name
  address_space           = var.address_space
  hub_vnet_id             = var.hub_vnet_id
  hub_vnet_name           = var.hub_vnet_name
  hub_resource_group      = var.hub_resource_group
  hub_firewall_private_ip = var.hub_firewall_private_ip
  environment             = var.environment
  team                    = var.team_name
  cost_centre             = var.cost_centre
  location                = var.location
}

module "budget" {
  source = "../azure-budget"

  team              = var.team_name
  environment       = var.environment
  subscription_id   = var.subscription_id
  monthly_budget    = var.monthly_budget
  alert_emails      = var.alert_emails
  escalation_emails = var.escalation_emails
  start_date        = var.budget_start_date
}
