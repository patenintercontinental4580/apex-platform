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

variable "team" {
  type        = string
  description = "The team that owns this resource."
}

variable "cost_centre" {
  type        = string
  description = "The cost centre code for billing allocation."
}

variable "location" {
  type        = string
  default     = "westeurope"
  description = "The Azure region for the Static Web App resource."
}

variable "instance_number" {
  type        = number
  default     = 1
  description = "The instance number for naming uniqueness."
}

variable "sku_tier" {
  type        = string
  default     = "Standard"
  description = "The SKU tier for the Static Web App. Free tier does not support custom domains or SLA."
  validation {
    condition     = contains(["Free", "Standard"], var.sku_tier)
    error_message = "sku_tier must be either 'Free' or 'Standard'."
  }
}

variable "repository_url" {
  type        = string
  default     = null
  description = "Optional URL of the repository for CI/CD integration."
}

variable "branch" {
  type        = string
  default     = "main"
  description = "The repository branch to deploy from."
}

variable "app_location" {
  type        = string
  default     = "/"
  description = "The location of the application code within the repository."
}

variable "output_location" {
  type        = string
  default     = "dist"
  description = "The output folder produced by the build process, relative to app_location."
}

variable "custom_domain" {
  type        = string
  default     = null
  description = "Optional custom domain name to associate with the Static Web App."
}
