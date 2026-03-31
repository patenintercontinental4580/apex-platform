provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "connectivity" {
  name     = "rg-apex-connectivity"
  location = var.location
  tags = {
    ManagedBy   = "Terraform"
    Repository  = "apex-platform"
    Environment = "platform"
    Team        = "platform-team"
    CostCentre  = "CC-PLATFORM"
  }
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "platform" {
  name                = "log-apex-platform-uks-01"
  resource_group_name = azurerm_resource_group.connectivity.name
  location            = azurerm_resource_group.connectivity.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = azurerm_resource_group.connectivity.tags
}

# Hub VNet
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-apex-hub-uks"
  resource_group_name = azurerm_resource_group.connectivity.name
  location            = azurerm_resource_group.connectivity.location
  address_space       = [var.hub_address_space]
  tags                = azurerm_resource_group.connectivity.tags
}

# Subnets
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.connectivity.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [cidrsubnet(var.hub_address_space, 10, 0)] # 10.0.0.0/26
}

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.connectivity.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.1.0/27"]
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.connectivity.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.2.0/27"]
}

resource "azurerm_subnet" "shared_services" {
  name                 = "SharedServicesSubnet"
  resource_group_name  = azurerm_resource_group.connectivity.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.4.0/24"]
}

resource "azurerm_subnet" "management" {
  name                 = "ManagementSubnet"
  resource_group_name  = azurerm_resource_group.connectivity.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.5.0/24"]
}
