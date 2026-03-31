variable "team" {
  type        = string
  description = "The team that owns this budget."
}

variable "environment" {
  type        = string
  description = "The deployment environment."
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID to apply the budget to."
}

variable "monthly_budget" {
  type        = number
  description = "The monthly budget amount in GBP."
  validation {
    condition     = var.monthly_budget > 0
    error_message = "monthly_budget must be greater than 0."
  }
}

variable "alert_emails" {
  type        = list(string)
  description = "List of email addresses to notify when budget thresholds are reached."
}

variable "escalation_emails" {
  type        = list(string)
  default     = []
  description = "Optional list of additional email addresses to include in escalation notifications at 75% and 90% thresholds."
}

variable "start_date" {
  type        = string
  default     = "2024-01-01T00:00:00Z"
  description = "The start date for the budget in RFC3339 format."
}
