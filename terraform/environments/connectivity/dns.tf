locals {
  private_dns_zones = {
    sql      = "privatelink.database.windows.net"
    keyvault = "privatelink.vaultcore.azure.net"
    blob     = "privatelink.blob.core.windows.net"
    acr      = "privatelink.azurecr.io"
    websites = "privatelink.azurewebsites.net"
  }
}

resource "azurerm_private_dns_zone" "zones" {
  for_each            = local.private_dns_zones
  name                = each.value
  resource_group_name = azurerm_resource_group.connectivity.name
  tags                = azurerm_resource_group.connectivity.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub_links" {
  for_each              = local.private_dns_zones
  name                  = "link-${each.key}-to-hub"
  resource_group_name   = azurerm_resource_group.connectivity.name
  private_dns_zone_name = azurerm_private_dns_zone.zones[each.key].name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = azurerm_resource_group.connectivity.tags
}
