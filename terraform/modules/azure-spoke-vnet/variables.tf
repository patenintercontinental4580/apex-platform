variable "spoke_name" {
  type        = string
  description = "Short name for the spoke, e.g. 'orders' or 'payments'. Used in all resource names."
}

variable "address_space" {
  type        = string
  description = "The CIDR block for the spoke VNet, e.g. '10.1.0.0/22'. Must be a /22 for subnet calculations to work correctly."
}

variable "hub_vnet_id" {
  type        = string
  description = "The full resource ID of the hub VNet to peer with."
}

variable "hub_vnet_name" {
  type        = string
  description = "The name of the hub VNet. Required to create the hub-to-spoke peering resource."
}

variable "hub_resource_group" {
  type        = string
  description = "The resource group name that contains the hub VNet."
}

variable "hub_firewall_private_ip" {
  type        = string
  description = "Private IP address of the Azure Firewall in the hub VNet. Used as the next-hop for the default UDR route (0.0.0.0/0)."
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
  description = "Name of the team that owns this spoke. Applied as a resource tag."
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
