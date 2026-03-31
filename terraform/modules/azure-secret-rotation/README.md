# azure-secret-rotation

Terraform module that provisions an automated **secret rotation** solution for Azure Key Vault on the Apex Platform. The module deploys a Linux Azure Function App (Python 3.11, Consumption plan) with a user-assigned managed identity, wires it to an Event Grid system topic that monitors `Microsoft.KeyVault.SecretNearExpiry` events, and assigns the minimum required RBAC roles.

## Architecture

```
Key Vault ──► Event Grid System Topic
                      │
                      │  SecretNearExpiry event
                      ▼
             Function App (webhook)
                      │
                      │  rotates secret via SDK
                      ▼
             Key Vault (new secret version)
```

The Function App authenticates to Key Vault using its **user-assigned managed identity**, which is granted the `Key Vault Secrets Officer` role. Function App storage is also accessed via managed identity (`Storage Blob Data Contributor`).

## Features

- Linux Consumption-plan Function App running Python 3.11
- User-assigned managed identity (no client secrets)
- `Key Vault Secrets Officer` role assignment on the target Key Vault
- Event Grid system topic subscribed to `SecretNearExpiry` events
- Configurable rotation interval and secret types via app settings
- Diagnostic settings forwarded to Log Analytics
- Consistent resource naming following Apex Platform conventions

## Usage

```hcl
module "secret_rotation" {
  source = "git::https://github.com/your-org/apex-platform.git//terraform/modules/azure-secret-rotation"

  application_name           = "orders"
  environment                = "prod"
  location                   = "uksouth"
  key_vault_id               = module.key_vault.key_vault_id
  key_vault_name             = module.key_vault.key_vault_name
  rotation_function_name     = "RotateDatabasePassword"
  rotation_interval_days     = 30
  secret_types               = ["database-password"]
  log_analytics_workspace_id = var.log_analytics_workspace_id
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `application_name` | The application name. Must be 3–24 chars, lowercase letters, numbers, hyphens. | `string` | — | Yes |
| `environment` | Deployment environment: `dev`, `staging`, or `prod`. | `string` | — | Yes |
| `location` | Azure region for all rotation resources. | `string` | `"uksouth"` | No |
| `key_vault_id` | Resource ID of the Key Vault whose secrets will be rotated. | `string` | — | Yes |
| `key_vault_name` | Name of the Key Vault (used to construct the vault URI). | `string` | — | Yes |
| `rotation_function_name` | Name of the Azure Function handling rotation (used as the webhook path). | `string` | — | Yes |
| `rotation_interval_days` | Number of days between rotations. Passed as an app setting. | `number` | `30` | No |
| `secret_types` | Types of secrets managed by this rotation function. | `list(string)` | `["database-password"]` | No |
| `log_analytics_workspace_id` | Resource ID of the Log Analytics Workspace for diagnostics. | `string` | — | Yes |

## Outputs

| Name | Description |
|------|-------------|
| `function_app_id` | The ID of the rotation Function App. |
| `function_app_name` | The name of the rotation Function App. |
| `event_grid_topic_id` | The ID of the Event Grid system topic. |
| `managed_identity_principal_id` | The principal ID of the managed identity. |
| `managed_identity_client_id` | The client ID of the managed identity. |

## Resource Naming

| Resource | Pattern | Example |
|----------|---------|---------|
| Resource Group | `rg-rot-<app>-<env>-<region>` | `rg-rot-orders-prod-uks` |
| Function App | `func-rot-<app>-<env>-<region>` | `func-rot-orders-prod-uks` |
| Service Plan | `asp-rot-<app>-<env>-<region>` | `asp-rot-orders-prod-uks` |
| Managed Identity | `id-rot-<app>-<env>-<region>` | `id-rot-orders-prod-uks` |
| Event Grid Topic | `evgt-rot-<app>-<env>-<region>` | `evgt-rot-orders-prod-uks` |
| Event Subscription | `evgs-rot-<app>-<env>-<region>` | `evgs-rot-orders-prod-uks` |
| Storage Account | `strot<app><env>` (max 24 chars) | `strotordersprod` |

## Notes

- The Function App code (the actual rotation logic) must be deployed separately using your CI/CD pipeline or the Azure Functions Core Tools. This module provisions the infrastructure only.
- Event Grid retries webhook delivery up to 30 times over 24 hours (`event_time_to_live = 1440` minutes).
- Key Vault sends the `SecretNearExpiry` event when a secret is within a configurable number of days of expiry (configured on the secret itself, not in this module).

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.5.0 |
| azurerm | ~> 3.80 |
