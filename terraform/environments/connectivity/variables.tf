variable "subscription_id" {
  type        = string
  description = "The subscription ID where connectivity resources are deployed."
}

variable "location" {
  type        = string
  description = "The Azure region where connectivity resources will be deployed."
  default     = "uksouth"
}

variable "hub_address_space" {
  type        = string
  description = "The address space CIDR block for the hub virtual network."
  default     = "10.0.0.0/16"
}

variable "log_retention_days" {
  type        = number
  description = "The number of days to retain logs in the Log Analytics workspace."
  default     = 365
}
