# azure-sql-database

Terraform module that provisions a production-ready Azure SQL Server and Database for the Apex Platform. The module covers the full data tier stack: SQL Server with a system-assigned managed identity, SQL Database with configurable backup policies, server-level auditing to Log Analytics, and an optional private endpoint with DNS zone group registration.

## Features

- Azure SQL Server 12.0 with TLS 1.2 enforced and public network access disabled
- System-assigned managed identity on the SQL Server
- Optional Microsoft Entra ID (formerly Azure AD) administrator
- Configurable SKU, maximum size, and short-term point-in-time restore retention
- Long-term retention (weekly, monthly, yearly) automatically enabled for production
- Server-level extended auditing policy forwarded to Log Analytics
- Optional private endpoint with DNS zone group for seamless FQDN resolution
- Diagnostic settings on the `master` database capturing `SQLSecurityAuditEvents`

## Production Guardrails

The module enforces two `lifecycle` preconditions on the SQL Server resource that will cause `terraform plan` to fail when the production environment is misconfigured:

| Condition | Requirement | Error Message |
|-----------|------------|---------------|
| `environment == "prod"` | `backup_retention_days` must equal 35 | `Production SQL databases must have backup_retention_days set to 35.` |
| `environment == "prod"` | `geo_redundant_backup` must be `true` | `Production SQL databases must have geo_redundant_backup = true.` |

These guardrails are intentional and cannot be overridden at plan time. If you genuinely need to bypass them — for example during a disaster recovery drill — you must modify the module source and peer-review the change before applying.

## Usage

```hcl
provider "azurerm" {
  features {}
}

module "orders_db" {
  source = "../../terraform/modules/azure-sql-database"

  application_name           = "orders"
  environment                = "prod"
  team                       = "Orders Team"
  cost_centre                = "CC-1234"
  location                   = "uksouth"
  instance_number            = 1

  sku_name                   = "GP_Gen5_2"
  max_size_gb                = 100
  backup_retention_days      = 35
  geo_redundant_backup       = true

  admin_login                = "sqladmin"
  admin_password             = var.sql_admin_password   # sourced from Key Vault or CI secret

  enable_private_endpoint    = true
  subnet_id                  = module.orders_spoke.private_endpoint_subnet_id
  private_dns_zone_id        = azurerm_private_dns_zone.sql.id

  log_analytics_workspace_id = module.log_analytics.workspace_id

  entra_admin_object_id      = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
  entra_admin_login          = "dba-group@example.com"
}
```

## Inputs

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `application_name` | `string` | — | yes | Lowercase alphanumeric name with hyphens, e.g. `orders` |
| `environment` | `string` | — | yes | One of: `dev`, `staging`, `prod` |
| `team` | `string` | — | yes | Team name applied as a resource tag |
| `cost_centre` | `string` | — | yes | Cost centre code applied as a resource tag |
| `location` | `string` | `"uksouth"` | no | Azure region for all resources |
| `instance_number` | `number` | `1` | no | Instance index; zero-padded to two digits in resource names |
| `sku_name` | `string` | `"S0"` | no | SQL Database SKU, e.g. `S0`, `GP_Gen5_2` |
| `max_size_gb` | `number` | `10` | no | Maximum database size in gigabytes |
| `admin_login` | `string` | — | yes | SQL Server administrator username |
| `admin_password` | `string` (sensitive) | — | yes | SQL Server administrator password |
| `enable_private_endpoint` | `bool` | `true` | no | Create a private endpoint for the SQL Server |
| `subnet_id` | `string` | `null` | no | Subnet resource ID for the private endpoint |
| `private_dns_zone_id` | `string` | `null` | no | `privatelink.database.windows.net` DNS zone ID |
| `log_analytics_workspace_id` | `string` | — | yes | Log Analytics Workspace resource ID for auditing |
| `backup_retention_days` | `number` | `7` | no | PITR retention in days (1–35). Production requires 35 |
| `geo_redundant_backup` | `bool` | `false` | no | Enable geo-redundant backups. Production requires `true` |
| `entra_admin_object_id` | `string` | `null` | no | Object ID of the Entra ID SQL administrator |
| `entra_admin_login` | `string` | `null` | no | Display name of the Entra ID SQL administrator |

## Outputs

| Name | Description |
|------|-------------|
| `sql_server_id` | Resource ID of the Azure SQL Server |
| `sql_server_name` | Name of the Azure SQL Server |
| `sql_server_fqdn` | FQDN of the SQL Server, e.g. `sql-orders-prod-uks-01.database.windows.net` |
| `sql_database_id` | Resource ID of the SQL Database |
| `sql_database_name` | Name of the SQL Database |
| `resource_group_name` | Name of the containing resource group |
| `private_endpoint_id` | Resource ID of the private endpoint, or `null` if not created |
| `sql_server_identity_principal_id` | Object ID of the SQL Server system-assigned managed identity |

## Resource Naming

All resources follow the Apex Platform naming convention: `{prefix}-{application_name}-{environment}-{region_short_code}-{instance_padded}`.

Example for `application_name = "orders"`, `environment = "prod"`, `location = "uksouth"`, `instance_number = 1`:

| Resource | Name |
|----------|------|
| Resource Group | `rg-orders-prod-uks-01` |
| SQL Server | `sql-orders-prod-uks-01` |
| SQL Database | `sqldb-orders-prod-uks-01` |
| Private Endpoint | `pe-sql-orders-prod-uks-01` |

## Security Notes

- `public_network_access_enabled = false` is set unconditionally. Access is only possible via the private endpoint.
- `minimum_tls_version = "1.2"` is enforced on all environments.
- The administrator password is marked `sensitive = true`. Avoid passing it as a plain `tfvars` value — prefer Azure Key Vault references or a CI/CD secret store.
- The system-assigned managed identity principal ID is exposed via `sql_server_identity_principal_id` so callers can grant the server access to Key Vault for transparent data encryption keys or other integrations.

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.5.0 |
| azurerm | ~> 3.80 |
