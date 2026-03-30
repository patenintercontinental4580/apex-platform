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
  instance_padded   = format("%02d", var.instance_number)
  name_suffix       = "${var.application_name}-${var.environment}-${local.region_short_code}-${local.instance_padded}"

  resource_group_name    = "rg-${local.name_suffix}"
  container_app_name     = "ca-${local.name_suffix}"
  managed_identity_name  = "id-${local.name_suffix}"
  app_insights_name      = "appi-${local.name_suffix}"
  container_app_env_name = "cae-${local.name_suffix}"

  default_tags = {
    ApplicationName = var.application_name
    Environment     = var.environment
    Team            = var.team
    CostCentre      = var.cost_centre
    ManagedBy       = "Terraform"
    Repository      = "apex-platform"
  }
}
