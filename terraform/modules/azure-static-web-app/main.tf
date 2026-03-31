resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.default_tags
}

resource "azurerm_static_site" "this" {
  name                = local.static_site_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku_tier            = var.sku_tier
  sku_size            = var.sku_tier
  tags                = local.default_tags
}

resource "azurerm_static_site_custom_domain" "this" {
  count           = var.custom_domain != null ? 1 : 0
  static_site_id  = azurerm_static_site.this.id
  domain_name     = var.custom_domain
  validation_type = "cname-delegation"
}
