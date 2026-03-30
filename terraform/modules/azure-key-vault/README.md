# Azure Key Vault Module

This Terraform module deploys a hardened Azure Key Vault for the Apex Platform, with RBAC authorisation, network access controls, optional private endpoint connectivity, and full diagnostic logging to Log Analytics.

## Resources Created

- **Resource Group** — scoped to the application and environment
- **Key Vault** — RBAC-enabled, with network ACLs defaulting to Deny and soft-delete configured
- **Role Assignments** — one per entry in `rbac_assignments`
- **Private Endpoint** — created only when `enable_private_endpoint = true` and `subnet_id` is provided
- **Private DNS Zone Group** — attached to the private endpoint only when `private_dns_zone_id` is provided
- **Monitor Diagnostic Setting** — forwards audit events and metrics to Log Analytics

## Naming Convention

All resources follow the Apex Platform naming standard:

```
{prefix}-{application_name}-{environment}-{region_short}-{instance_number}
```

For example, a Key Vault for `payments` in `prod` deployed to `uksouth` with instance number `1` would be named:

```
kv-payments-prod-uks-01
```

## Usage

### Basic Example (No Private Endpoint)

```hcl
module "payments_kv" {
  source = "../../modules/azure-key-vault"

  application_name           = "payments"
  environment                = "dev"
  team                       = "platform"
  cost_centre                = "CC-1234"
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-shared/providers/Microsoft.OperationalInsights/workspaces/law-shared-dev"

  enable_private_endpoint = false
  enable_purge_protection = false
}
```

### Production Example (Private Endpoint, RBAC, Purge Protection)

```hcl
module "payments_kv_prod" {
  source = "../../modules/azure-key-vault"

  application_name           = "payments"
  environment                = "prod"
  team                       = "platform-engineering"
  cost_centre                = "CC-5678"
  location                   = "uksouth"
  instance_number            = 1
  sku_name                   = "premium"
  enable_purge_protection    = true
  soft_delete_retention_days = 90
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-shared/providers/Microsoft.OperationalInsights/workspaces/law-shared-prod"

  enable_private_endpoint = true
  subnet_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-prod/subnets/snet-endpoints"
  private_dns_zone_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"

  rbac_assignments = [
    {
      principal_id = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
      role         = "Key Vault Secrets User"
    },
    {
      principal_id = "ffffffff-gggg-hhhh-iiii-jjjjjjjjjjjj"
      role         = "Key Vault Secrets Officer"
    }
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `application_name` | The name of the application. Must match `^[a-z][a-z0-9-]{2,23}$`. | `string` | — | Yes |
| `environment` | Deployment environment. One of: `dev`, `staging`, `prod`. | `string` | — | Yes |
| `team` | The name of the team that owns this application. | `string` | — | Yes |
| `cost_centre` | Cost centre code for billing. | `string` | — | Yes |
| `log_analytics_workspace_id` | Resource ID of the Log Analytics workspace. | `string` | — | Yes |
| `location` | Azure region for all resources. | `string` | `"uksouth"` | No |
| `instance_number` | Instance number, zero-padded in resource names. | `number` | `1` | No |
| `sku_name` | Key Vault SKU. One of: `standard`, `premium`. | `string` | `"standard"` | No |
| `enable_purge_protection` | Whether to enable purge protection. Mandatory for `prod`. | `bool` | `true` | No |
| `enable_private_endpoint` | Whether to create a private endpoint. Requires `subnet_id`. | `bool` | `true` | No |
| `subnet_id` | Subnet resource ID for the private endpoint. | `string` | `null` | No |
| `private_dns_zone_id` | Private DNS Zone resource ID for `privatelink.vaultcore.azure.net`. | `string` | `null` | No |
| `rbac_assignments` | List of `{ principal_id, role }` objects for Key Vault RBAC. | `list(object)` | `[]` | No |
| `soft_delete_retention_days` | Soft-delete retention period in days (7–90). | `number` | `90` | No |

## Outputs

| Name | Description |
|------|-------------|
| `key_vault_id` | The resource ID of the Key Vault. |
| `key_vault_name` | The name of the Key Vault. |
| `key_vault_uri` | The URI of the Key Vault (e.g. `https://kv-orders-prod-uks-01.vault.azure.net/`). |
| `resource_group_name` | The name of the resource group. |
| `private_endpoint_id` | The resource ID of the private endpoint, or `null` if not created. |

## Production Guardrails

This module enforces the following constraint at plan time:

- **Purge protection**: When `environment = "prod"`, `enable_purge_protection` must be `true`. Attempting to plan a production Key Vault without purge protection enabled will fail with an informative error message.

## Security Considerations

- The Key Vault uses **RBAC authorisation** exclusively. Access policies are not supported by this module.
- The default network ACL action is **Deny**. All access must be via an approved private endpoint or trusted Azure services.
- Soft-delete is always enabled and cannot be disabled in Azure Key Vault once enabled.
- For production workloads, use the `premium` SKU if HSM-backed keys are required for cryptographic operations.
- Diagnostic logs include `AuditEvent` entries, which capture all data plane access to the vault. These logs are essential for security incident investigation.
