variable "root_management_group_id" {
  type        = string
  description = "The ID of the root management group (Tenant Root Group)"
}

variable "subscription_id" {
  type        = string
  description = "The subscription ID used for provider authentication."
}

variable "allowed_regions" {
  type        = list(string)
  description = "List of Azure regions where resources are permitted to be deployed."
  default     = ["uksouth", "ukwest", "westeurope"]
}

variable "platform_admin_emails" {
  type        = list(string)
  description = "List of email addresses for platform administrators to receive alerts and notifications."
  default     = []
}
