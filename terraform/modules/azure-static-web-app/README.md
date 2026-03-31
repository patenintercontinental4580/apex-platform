# azure-static-web-app

Terraform module that provisions an **Azure Static Web App** for hosting React, Angular, Vue, and other modern frontend frameworks. The module creates a dedicated resource group, the Static Web App resource, and optionally associates a custom domain.

## Features

- Provisions an `azurerm_static_site` with configurable SKU (Free or Standard)
- Creates a dedicated resource group with consistent naming and tagging
- Optional custom domain association via CNAME delegation
- Consistent resource naming following Apex Platform conventions (`stapp-<app>-<env>-<region>-<nn>`)
- Default tags applied to all resources for cost allocation and governance

## Usage

### Basic (Free tier, dev environment)

```hcl
module "static_web_app" {
  source = "git::https://github.com/your-org/apex-platform.git//terraform/modules/azure-static-web-app"

  application_name = "portal"
  environment      = "dev"
  team             = "platform-team"
  cost_centre      = "CC-001"
}
```

### Standard tier with custom domain (production)

```hcl
module "static_web_app" {
  source = "git::https://github.com/your-org/apex-platform.git//terraform/modules/azure-static-web-app"

  application_name = "portal"
  environment      = "prod"
  team             = "platform-team"
  cost_centre      = "CC-PLATFORM"
  location         = "uksouth"
  sku_tier         = "Standard"
  custom_domain    = "portal.example.com"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `application_name` | The application name. Used in resource naming. Must be 3–24 characters, start with a lowercase letter, and contain only lowercase letters, numbers, and hyphens. | `string` | — | Yes |
| `environment` | The deployment environment. Must be one of: `dev`, `staging`, `prod`. | `string` | — | Yes |
| `team` | The team that owns this resource. | `string` | — | Yes |
| `cost_centre` | The cost centre code for billing allocation. | `string` | — | Yes |
| `location` | The Azure region for the Static Web App resource. | `string` | `"westeurope"` | No |
| `instance_number` | The instance number for naming uniqueness. | `number` | `1` | No |
| `sku_tier` | The SKU tier for the Static Web App. `Free` tier does not support custom domains or SLA. Must be `Free` or `Standard`. | `string` | `"Standard"` | No |
| `repository_url` | Optional URL of the repository for CI/CD integration. | `string` | `null` | No |
| `branch` | The repository branch to deploy from. | `string` | `"main"` | No |
| `app_location` | The location of the application code within the repository. | `string` | `"/"` | No |
| `output_location` | The output folder produced by the build process, relative to `app_location`. | `string` | `"dist"` | No |
| `custom_domain` | Optional custom domain name to associate with the Static Web App. | `string` | `null` | No |

## Outputs

| Name | Description |
|------|-------------|
| `static_site_id` | The ID of the Static Web App. |
| `static_site_name` | The name of the Static Web App. |
| `static_site_default_host_name` | The default host name of the Static Web App. |
| `static_site_api_key` | The API key for deploying to the Static Web App. Marked sensitive. |
| `resource_group_name` | The name of the resource group. |

## Resource Naming

Resources follow the Apex Platform naming convention using `application_name`, `environment`, region short code, and a zero-padded instance number:

| Resource | Pattern | Example |
|----------|---------|---------|
| Resource Group | `rg-<app>-<env>-<region>-<nn>` | `rg-portal-prod-uks-01` |
| Static Web App | `stapp-<app>-<env>-<region>-<nn>` | `stapp-portal-prod-uks-01` |

## Notes

- The **Free** tier has no SLA, does not support custom domains, and is limited to 100 GB bandwidth per month. Use **Standard** for production workloads.
- Custom domain association uses CNAME delegation. Ensure the DNS CNAME record pointing to the Static Web App's default hostname is created before or shortly after applying.
- The `static_site_api_key` output is marked sensitive and is used by your CI/CD pipeline to authenticate deployments (e.g., via the Azure Static Web Apps GitHub Action or the SWA CLI).

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.5.0 |
| azurerm | ~> 3.80 |
