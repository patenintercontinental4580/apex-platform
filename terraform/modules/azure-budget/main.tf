resource "azurerm_consumption_budget_subscription" "this" {
  name            = local.budget_name
  subscription_id = var.subscription_id
  amount          = var.monthly_budget
  time_grain      = "Monthly"

  time_period {
    start_date = var.start_date
  }

  notification {
    enabled        = true
    threshold      = 50
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = var.alert_emails
  }

  notification {
    enabled        = true
    threshold      = 75
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = concat(var.alert_emails, var.escalation_emails)
  }

  notification {
    enabled        = true
    threshold      = 90
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = concat(var.alert_emails, var.escalation_emails)
  }
}
