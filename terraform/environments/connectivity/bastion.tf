resource "azurerm_public_ip" "bastion" {
  name                = "pip-bas-apex-hub-uks"
  resource_group_name = azurerm_resource_group.connectivity.name
  location            = azurerm_resource_group.connectivity.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = azurerm_resource_group.connectivity.tags
}

resource "azurerm_bastion_host" "hub" {
  name                = "bas-apex-hub-uks"
  resource_group_name = azurerm_resource_group.connectivity.name
  location            = azurerm_resource_group.connectivity.location
  sku                 = "Standard"
  tags                = azurerm_resource_group.connectivity.tags

  ip_configuration {
    name                 = "ipconfig-primary"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}
