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

  region_short_code     = lookup(local.region_short, var.location, "uks")
  instance_padded       = format("%02d", var.instance_number)
  name_suffix           = "${var.application_name}-${var.environment}-${local.region_short_code}-${local.instance_padded}"
  resource_group_name   = "rg-${local.name_suffix}"
  function_app_name     = "func-${local.name_suffix}"
  service_plan_name     = "asp-${local.name_suffix}"
  managed_identity_name = "id-${local.name_suffix}"

  # Storage account names must be 3-24 chars, lowercase, no hyphens
  storage_account_name = substr(replace("st${var.application_name}${var.environment}${local.region_short_code}", "-", ""), 0, 24)

  default_tags = {
    ApplicationName = var.application_name
    Environment     = var.environment
    Team            = var.team
    CostCentre      = var.cost_centre
    ManagedBy       = "Terraform"
    Repository      = "apex-platform"
  }
}
