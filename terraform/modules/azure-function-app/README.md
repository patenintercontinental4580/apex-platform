# azure-function-app

Terraform module for deploying an Azure Linux Function App with supporting infrastructure, including a user-assigned managed identity, storage account, App Service Plan, role assignments, and diagnostic settings.

## Features

- Linux Function App with support for .NET (isolated), Python, and Node.js runtimes
- Consumption or Premium (Elastic Premium) App Service Plan
- User-assigned managed identity with `Storage Blob Data Contributor` role on the backing storage account
- Optional Key Vault integration via `Key Vault Secrets User` role assignment and Key Vault reference app settings
- Optional VNet integration via subnet association
- Public network access disabled automatically for Premium plan or production environments
- Diagnostic logs and metrics forwarded to a Log Analytics Workspace
- Consistent resource naming following the Apex Platform convention: `{prefix}-{app}-{env}-{region}-{instance}`

## Resource Naming

| Resource | Pattern | Example |
|---|---|---|
| Resource Group | `rg-{app}-{env}-{region}-{instance}` | `rg-orders-dev-uks-01` |
| Function App | `func-{app}-{env}-{region}-{instance}` | `func-orders-dev-uks-01` |
| App Service Plan | `asp-{app}-{env}-{region}-{instance}` | `asp-orders-dev-uks-01` |
| Managed Identity | `id-{app}-{env}-{region}-{instance}` | `id-orders-dev-uks-01` |
| Storage Account | `st{app}{env}{region}` (max 24 chars) | `stordersdevuks` |

## Usage

### Basic (Python, Consumption plan)

```hcl
module "orders_function" {
  source = "../../modules/azure-function-app"

  application_name           = "orders"
  environment                = "dev"
  team                       = "platform"
  cost_centre                = "CC-1234"
  runtime_stack              = "python"
  runtime_version            = "3.11"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.core.id
}
```

### Complete (.NET isolated, Premium plan with Key Vault)

```hcl
module "payments_function" {
  source = "../../modules/azure-function-app"

  application_name           = "payments"
  environment                = "prod"
  team                       = "platform"
  cost_centre                = "CC-5678"
  location                   = "uksouth"
  instance_number            = 1
  runtime_stack              = "dotnet-isolated"
  runtime_version            = "8"
  plan_type                  = "Premium"
  key_vault_id               = azurerm_key_vault.this.id
  key_vault_name             = azurerm_key_vault.this.name
  subnet_id                  = azurerm_subnet.integration.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.core.id
}
```

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.80 |

## Providers

| Name | Version |
|---|---|
| azurerm | ~> 3.80 |

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `application_name` | Name of the application. Lowercase alphanumeric with hyphens, 3–24 chars. | `string` | n/a | yes |
| `environment` | Deployment environment. One of: `dev`, `staging`, `prod`. | `string` | n/a | yes |
| `team` | Owning team. Used for tagging. | `string` | n/a | yes |
| `cost_centre` | Cost centre code. Used for tagging. | `string` | n/a | yes |
| `location` | Azure region for deployment. | `string` | `"uksouth"` | no |
| `instance_number` | Instance number (zero-padded in naming). | `number` | `1` | no |
| `runtime_stack` | Function runtime. One of: `dotnet-isolated`, `python`, `node`. | `string` | n/a | yes |
| `runtime_version` | Runtime version, e.g. `8`, `3.11`, `20`. | `string` | n/a | yes |
| `plan_type` | App Service Plan type. One of: `Consumption`, `Premium`. | `string` | `"Consumption"` | no |
| `key_vault_id` | Resource ID of Azure Key Vault for managed identity access. | `string` | `null` | no |
| `key_vault_name` | Name of the Azure Key Vault for app setting references. | `string` | `null` | no |
| `subnet_id` | Subnet resource ID for VNet integration. | `string` | `null` | no |
| `log_analytics_workspace_id` | Resource ID of the Log Analytics Workspace for diagnostics. | `string` | n/a | yes |

## Outputs

| Name | Description |
|---|---|
| `function_app_id` | Resource ID of the Linux Function App. |
| `function_app_name` | Name of the Linux Function App. |
| `function_app_default_hostname` | Default hostname of the Linux Function App. |
| `resource_group_name` | Name of the resource group. |
| `managed_identity_id` | Resource ID of the user-assigned managed identity. |
| `managed_identity_client_id` | Client ID of the managed identity. |
| `managed_identity_principal_id` | Principal ID of the managed identity. |
| `storage_account_name` | Name of the backing storage account. |

## Notes

- Storage account public access is automatically restricted when `plan_type = "Premium"` or `environment = "prod"`. Ensure private endpoints or VNet service endpoints are configured before applying in those scenarios.
- When enabling Key Vault integration, ensure the Key Vault has RBAC authorisation mode enabled (not access policies), as this module assigns the `Key Vault Secrets User` role via `azurerm_role_assignment`.
- The `storage_uses_managed_identity` flag is always enabled; the managed identity requires the `Storage Blob Data Owner` or `Storage Blob Data Contributor` role, which is assigned automatically by this module.
