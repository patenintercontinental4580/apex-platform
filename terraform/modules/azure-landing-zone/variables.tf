variable "team_name" {
  type        = string
  description = "The name of the team that owns this landing zone. Used in resource naming and tagging."
}

variable "environment" {
  type        = string
  description = "The deployment environment."
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "address_space" {
  type        = string
  description = "The CIDR address space for the spoke VNet (e.g. '10.1.0.0/22')."
}

variable "hub_vnet_id" {
  type        = string
  description = "The resource ID of the hub VNet to peer with."
}

variable "hub_vnet_name" {
  type        = string
  description = "The name of the hub VNet."
}

variable "hub_resource_group" {
  type        = string
  description = "The resource group name of the hub VNet."
}

variable "hub_firewall_private_ip" {
  type        = string
  description = "The private IP address of the hub Azure Firewall, used as the default route next hop."
}

variable "monthly_budget" {
  type        = number
  description = "The monthly budget amount in GBP for the subscription."
}

variable "alert_emails" {
  type        = list(string)
  description = "List of email addresses to notify when budget thresholds are reached."
}

variable "escalation_emails" {
  type        = list(string)
  default     = []
  description = "Optional list of additional email addresses for escalation notifications at 75% and 90% thresholds."
}

variable "location" {
  type        = string
  default     = "uksouth"
  description = "The Azure region in which to deploy the landing zone resources."
}

variable "cost_centre" {
  type        = string
  description = "The cost centre code for billing allocation."
}

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID for the consumption budget."
}

variable "budget_start_date" {
  type        = string
  default     = "2024-01-01T00:00:00Z"
  description = "The start date for the budget in RFC3339 format."
}
