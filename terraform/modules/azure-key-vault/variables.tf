variable "application_name" {
  description = "The name of the application. Used in all resource names and tags."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,23}$", var.application_name))
    error_message = "application_name must start with a lowercase letter, contain only lowercase letters, numbers, and hyphens, and be between 3 and 24 characters long."
  }
}

variable "environment" {
  description = "The deployment environment. Must be one of: dev, staging, prod."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "team" {
  description = "The name of the team that owns this application. Used in tags."
  type        = string
}

variable "cost_centre" {
  description = "The cost centre code for billing. Used in tags."
  type        = string
}

variable "location" {
  description = "The Azure region in which to deploy all resources."
  type        = string
  default     = "uksouth"
}

variable "instance_number" {
  description = "The instance number, zero-padded to two digits in resource names. Used to differentiate multiple Key Vaults for the same application and environment."
  type        = number
  default     = 1
}

variable "sku_name" {
  description = "The SKU for the Key Vault. Use 'premium' if HSM-backed keys are required; otherwise 'standard' is sufficient."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "sku_name must be one of: standard, premium."
  }
}

variable "enable_purge_protection" {
  description = "Whether to enable purge protection on the Key Vault. When enabled, a deleted vault and its contents cannot be purged during the retention period. Mandatory for production environments."
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Whether to create a private endpoint for the Key Vault. Requires subnet_id to be set."
  type        = bool
  default     = true
}

variable "subnet_id" {
  description = "The resource ID of the subnet in which to place the private endpoint. Required when enable_private_endpoint is true."
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "The resource ID of the Private DNS Zone (privatelink.vaultcore.azure.net) to link to the private endpoint. If null, no DNS zone group is created and DNS must be managed separately."
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "The resource ID of the Log Analytics workspace to which diagnostic logs and metrics are sent."
  type        = string
}

variable "rbac_assignments" {
  description = "A list of RBAC role assignments to create on the Key Vault. Each object requires a principal_id (object ID of the assignee) and a role (built-in role definition name, e.g. 'Key Vault Secrets User')."
  type = list(object({
    principal_id = string
    role         = string
  }))
  default = []
}

variable "soft_delete_retention_days" {
  description = "The number of days that soft-deleted vaults and vault objects are retained. Must be between 7 and 90."
  type        = number
  default     = 90

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "soft_delete_retention_days must be between 7 and 90 inclusive."
  }
}
