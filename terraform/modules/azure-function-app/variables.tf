variable "application_name" {
  type        = string
  description = "The name of the application. Used in resource naming. Must be lowercase alphanumeric with hyphens, 3-24 characters."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,23}$", var.application_name))
    error_message = "application_name must start with a lowercase letter, contain only lowercase letters, numbers, and hyphens, and be between 3 and 24 characters long."
  }
}

variable "environment" {
  type        = string
  description = "The deployment environment. Must be one of: dev, staging, prod."

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "team" {
  type        = string
  description = "The team responsible for this resource. Used for tagging."
}

variable "cost_centre" {
  type        = string
  description = "The cost centre code for billing allocation. Used for tagging."
}

variable "location" {
  type        = string
  description = "The Azure region in which to deploy the resources."
  default     = "uksouth"
}

variable "instance_number" {
  type        = number
  description = "The instance number for this deployment. Used in resource naming (zero-padded to two digits)."
  default     = 1
}

variable "runtime_stack" {
  type        = string
  description = "The runtime stack for the Function App. Must be one of: dotnet-isolated, python, node."

  validation {
    condition     = contains(["dotnet-isolated", "python", "node"], var.runtime_stack)
    error_message = "runtime_stack must be one of: dotnet-isolated, python, node."
  }
}

variable "runtime_version" {
  type        = string
  description = "The version of the runtime stack. For example: '8' for dotnet-isolated, '3.11' for python, '20' for node."
}

variable "plan_type" {
  type        = string
  description = "The App Service Plan type. Must be one of: Consumption, Premium."
  default     = "Consumption"

  validation {
    condition     = contains(["Consumption", "Premium"], var.plan_type)
    error_message = "plan_type must be one of: Consumption, Premium."
  }
}

variable "key_vault_id" {
  type        = string
  description = "The resource ID of the Azure Key Vault to grant the managed identity access to. Optional."
  default     = null
}

variable "key_vault_name" {
  type        = string
  description = "The name of the Azure Key Vault. Required when key_vault_id is set, used to construct Key Vault references in app settings."
  default     = null
}

variable "subnet_id" {
  type        = string
  description = "The resource ID of the subnet for VNet integration. Optional. When provided, all outbound traffic is routed through the VNet."
  default     = null
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "The resource ID of the Log Analytics Workspace to send diagnostic logs and metrics to."
}
