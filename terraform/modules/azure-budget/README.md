# azure-budget

Terraform module that provisions an **Azure Consumption Budget** at subscription scope for the Apex Platform. The module creates a monthly budget with three alert thresholds — 50% actual, 75% actual, and 90% forecasted — and notifies the relevant team and escalation contacts via email.

## Features

- Monthly subscription-scoped consumption budget
- Three graduated alert notifications:
  - **50% Actual** — notifies the team
  - **75% Actual** — notifies the team and escalation contacts
  - **90% Forecasted** — notifies the team and escalation contacts
- Consistent budget naming following Apex Platform conventions (`budget-<team>-<env>`)

## Usage

### Basic

```hcl
module "budget" {
  source = "git::https://github.com/your-org/apex-platform.git//terraform/modules/azure-budget"

  team            = "orders"
  environment     = "dev"
  subscription_id = "00000000-0000-0000-0000-000000000000"
  monthly_budget  = 500
  alert_emails    = ["orders-team@example.com"]
}
```

### With escalation contacts

```hcl
module "budget" {
  source = "git::https://github.com/your-org/apex-platform.git//terraform/modules/azure-budget"

  team              = "orders"
  environment       = "prod"
  subscription_id   = var.subscription_id
  monthly_budget    = 2000
  alert_emails      = ["orders-team@example.com"]
  escalation_emails = ["platform-team@example.com", "finance@example.com"]
  start_date        = "2024-01-01T00:00:00Z"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `team` | The team that owns this budget. | `string` | — | Yes |
| `environment` | The deployment environment. Must be one of: `dev`, `staging`, `prod`. | `string` | — | Yes |
| `subscription_id` | The Azure subscription ID to apply the budget to. | `string` | — | Yes |
| `monthly_budget` | The monthly budget amount in GBP. Must be greater than 0. | `number` | — | Yes |
| `alert_emails` | List of email addresses to notify when budget thresholds are reached. | `list(string)` | — | Yes |
| `escalation_emails` | Optional list of additional email addresses for 75% and 90% threshold notifications. | `list(string)` | `[]` | No |
| `start_date` | The start date for the budget in RFC3339 format. | `string` | `"2024-01-01T00:00:00Z"` | No |

## Outputs

| Name | Description |
|------|-------------|
| `budget_id` | The ID of the consumption budget. |
| `budget_name` | The name of the consumption budget. |

## Alert Thresholds

| Threshold | Type | Recipients |
|-----------|------|-----------|
| 50% | Actual | `alert_emails` |
| 75% | Actual | `alert_emails` + `escalation_emails` |
| 90% | Forecasted | `alert_emails` + `escalation_emails` |

## Notes

- Azure Consumption Budgets do not block spending; they only send notifications.
- Budget amounts are evaluated in the currency configured for the subscription (typically GBP for UK subscriptions).
- The `start_date` must be the first day of a month in RFC3339 format.
- This module is consumed automatically by the `azure-landing-zone` composition module.

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.5.0 |
| azurerm | ~> 3.80 |
