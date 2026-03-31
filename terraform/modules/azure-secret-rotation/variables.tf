variable "application_name" {
  type        = string
  description = "The application name. Used in resource naming."
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,23}$", var.application_name))
    error_message = "application_name must be 3–24 characters, start with a lowercase letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  type        = string
  description = "The deployment environment."
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  type        = string
  default     = "uksouth"
  description = "The Azure region in which to deploy the secret rotation resources."
}

variable "key_vault_id" {
  type        = string
  description = "The resource ID of the Key Vault whose secrets will be rotated."
}

variable "key_vault_name" {
  type        = string
  description = "The name of the Key Vault. Used to construct the vault URI for the Function App."
}

variable "rotation_function_name" {
  type        = string
  description = "The name of the Azure Function that handles the rotation logic (used as the webhook endpoint path)."
}

variable "rotation_interval_days" {
  type        = number
  default     = 30
  description = "The number of days between secret rotations. Passed to the Function App as an environment variable."
}

variable "secret_types" {
  type        = list(string)
  default     = ["database-password"]
  description = "The types of secrets managed by this rotation function. Passed as a comma-separated environment variable."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "The resource ID of the Log Analytics Workspace for diagnostic settings."
}
