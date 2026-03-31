locals {
  region_short = {
    "uksouth"    = "uks"
    "ukwest"     = "ukw"
    "westeurope" = "weu"
    "northeurope" = "neu"
    "eastus"     = "eus"
    "eastus2"    = "eus2"
    "westus2"    = "wus2"
  }
  region_short_code    = lookup(local.region_short, var.location, "uks")
  resource_group_name  = "rg-rot-${var.application_name}-${var.environment}-${local.region_short_code}"
  function_app_name    = "func-rot-${var.application_name}-${var.environment}-${local.region_short_code}"
  service_plan_name    = "asp-rot-${var.application_name}-${var.environment}-${local.region_short_code}"
  identity_name        = "id-rot-${var.application_name}-${var.environment}-${local.region_short_code}"
  topic_name           = "evgt-rot-${var.application_name}-${var.environment}-${local.region_short_code}"
  subscription_name    = "evgs-rot-${var.application_name}-${var.environment}-${local.region_short_code}"
  storage_account_name = substr(replace("strot${var.application_name}${var.environment}", "-", ""), 0, 24)
  default_tags = {
    ApplicationName = var.application_name
    Environment     = var.environment
    ManagedBy       = "Terraform"
    Repository      = "apex-platform"
  }
}
