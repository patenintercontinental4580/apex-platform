variable "application_name" {
  type        = string
  description = "Short application name used in resource names, e.g. 'orders' or 'payments'. Must be lowercase alphanumeric with hyphens only."

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.application_name))
    error_message = "application_name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment. Must be one of: dev, staging, prod."

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "team" {
  type        = string
  description = "Name of the team that owns this database. Applied as a resource tag."
}

variable "cost_centre" {
  type        = string
  description = "Cost centre code for billing attribution. Applied as a resource tag."
}

variable "location" {
  type        = string
  description = "Azure region in which to deploy all resources."
  default     = "uksouth"
}

variable "instance_number" {
  type        = number
  description = "Instance number used to differentiate multiple deployments of the same application. Zero-padded to two digits in resource names."
  default     = 1
}

variable "sku_name" {
  type        = string
  description = "SKU for the Azure SQL Database. Examples: S0, S1, S2, GP_Gen5_2, BC_Gen5_4."
  default     = "S0"
}

variable "max_size_gb" {
  type        = number
  description = "Maximum data storage size in gigabytes for the database."
  default     = 10
}

variable "admin_login" {
  type        = string
  description = "SQL Server administrator login username. Must not be a reserved name such as 'admin', 'sa', or 'root'."
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "SQL Server administrator login password. Must meet Azure complexity requirements. Store this value in a Key Vault or CI secret — never in source control."
}

variable "enable_private_endpoint" {
  type        = bool
  description = "When true, a private endpoint is created to expose the SQL Server on the specified subnet. Requires subnet_id to be set."
  default     = true
}

variable "subnet_id" {
  type        = string
  description = "Resource ID of the subnet in which to place the private endpoint. Required when enable_private_endpoint is true."
  default     = null
}

variable "private_dns_zone_id" {
  type        = string
  description = "Resource ID of the privatelink.database.windows.net Private DNS Zone. When provided, a DNS zone group is created on the private endpoint so SQL FQDNs resolve correctly."
  default     = null
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Resource ID of the Log Analytics Workspace used for diagnostic settings and auditing."
}

variable "backup_retention_days" {
  type        = number
  description = "Point-in-time restore retention period in days. Must be between 1 and 35. Production environments require a minimum of 35 days (enforced via lifecycle precondition)."
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "backup_retention_days must be between 1 and 35."
  }
}

variable "geo_redundant_backup" {
  type        = bool
  description = "When true, geo-redundant backups are enabled. Production environments require this to be true (enforced via lifecycle precondition)."
  default     = false
}

variable "entra_admin_object_id" {
  type        = string
  description = "Object ID of the Microsoft Entra ID user, group, or service principal to set as the SQL Server Entra administrator. When null, no Entra admin is configured."
  default     = null
}

variable "entra_admin_login" {
  type        = string
  description = "Display name of the Entra administrator. Used as the login_username in the azuread_administrator block. Defaults to 'EntraAdmin' when not provided."
  default     = null
}
