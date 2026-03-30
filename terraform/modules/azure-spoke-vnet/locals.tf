locals {
  region_short = {
    "uksouth"     = "uks"
    "ukwest"      = "ukw"
    "westeurope"  = "weu"
    "northeurope" = "neu"
    "eastus"      = "eus"
    "eastus2"     = "eus2"
    "westus2"     = "wus2"
  }

  region_short_code = lookup(local.region_short, var.location, "uks")

  resource_group_name = "rg-${var.spoke_name}-${var.environment}-${local.region_short_code}"
  vnet_name           = "vnet-${var.spoke_name}-${var.environment}-${local.region_short_code}"
  route_table_name    = "rt-${var.spoke_name}-${var.environment}-${local.region_short_code}"

  default_tags = {
    Environment = var.environment
    Team        = var.team
    CostCentre  = var.cost_centre
    ManagedBy   = "Terraform"
    Repository  = "apex-platform"
  }

  # Subnet CIDRs derived from address_space (assumes /22 base)
  # cidrsubnet("10.1.0.0/22", 2, 0) = 10.1.0.0/24 (ApplicationSubnet)
  # cidrsubnet("10.1.0.0/22", 2, 1) = 10.1.1.0/24 (DataSubnet)
  # cidrsubnet("10.1.0.0/22", 2, 2) = 10.1.2.0/24 (PrivateEndpointSubnet)
  # cidrsubnet("10.1.0.0/22", 3, 6) = 10.1.3.0/25 (IntegrationSubnet - /25)
  application_subnet_cidr      = cidrsubnet(var.address_space, 2, 0)
  data_subnet_cidr             = cidrsubnet(var.address_space, 2, 1)
  private_endpoint_subnet_cidr = cidrsubnet(var.address_space, 2, 2)
  integration_subnet_cidr      = cidrsubnet(var.address_space, 3, 6)
}
