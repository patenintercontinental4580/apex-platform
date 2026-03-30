# Azure Container App Module

This Terraform module deploys a fully configured Azure Container App, along with all supporting infrastructure required to run a production-grade containerised workload on the Apex Platform.

## Resources Created

- **Resource Group** — scoped to the application and environment
- **User-Assigned Managed Identity** — for secure, credential-free access to Azure services
- **Application Insights** — workspace-based application performance monitoring
- **Container App Environment** — shared compute plane (created only when no existing environment ID is supplied)
- **Container App** — the running containerised application with ingress, scaling, and health checks configured
- **Monitor Diagnostic Setting** — forwards Container App logs and metrics to Log Analytics

## Naming Convention

All resources follow the Apex Platform naming standard:

```
{prefix}-{application_name}-{environment}-{region_short}-{instance_number}
```

For example, a Container App for `orders` in `prod` deployed to `uksouth` with instance number `1` would be named:

```
ca-orders-prod-uks-01
```

## Usage

### Basic Example

```hcl
module "orders_api" {
  source = "../../modules/azure-container-app"

  application_name           = "orders"
  environment                = "dev"
  team                       = "platform"
  cost_centre                = "CC-1234"
  container_image            = "myacr.azurecr.io/orders:1.0.0"
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-shared/providers/Microsoft.OperationalInsights/workspaces/law-shared-dev"
}
```

### Production Example (High Availability)

```hcl
module "orders_api_prod" {
  source = "../../modules/azure-container-app"

  application_name           = "orders"
  environment                = "prod"
  team                       = "platform"
  cost_centre                = "CC-1234"
  container_image            = "myacr.azurecr.io/orders:2.3.1"
  location                   = "uksouth"
  instance_number            = 1
  cpu                        = 1.0
  memory                     = "2Gi"
  min_replicas               = 2
  max_replicas               = 10
  target_port                = 8080
  health_check_path          = "/healthz"
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-shared/providers/Microsoft.OperationalInsights/workspaces/law-shared-prod"
  subnet_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-prod/subnets/snet-apps"

  environment_variables = {
    ASPNETCORE_ENVIRONMENT = "Production"
    OTEL_SERVICE_NAME      = "orders-api"
  }

  secrets = {
    db-connection-string = "Server=tcp:myserver.database.windows.net;..."
    api-key              = "supersecretvalue"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `application_name` | The name of the application. Must match `^[a-z][a-z0-9-]{2,23}$`. | `string` | — | Yes |
| `environment` | Deployment environment. One of: `dev`, `staging`, `prod`. | `string` | — | Yes |
| `team` | The name of the team that owns this application. | `string` | — | Yes |
| `cost_centre` | Cost centre code for billing. | `string` | — | Yes |
| `container_image` | Full container image reference including tag. | `string` | — | Yes |
| `log_analytics_workspace_id` | Resource ID of the Log Analytics workspace. | `string` | — | Yes |
| `location` | Azure region for all resources. | `string` | `"uksouth"` | No |
| `instance_number` | Instance number, zero-padded in resource names. | `number` | `1` | No |
| `cpu` | vCPUs allocated to the container. One of: `0.25`, `0.5`, `1.0`, `2.0`, `4.0`. | `number` | `0.5` | No |
| `memory` | Memory allocated to the container. One of: `0.5Gi`, `1Gi`, `2Gi`, `4Gi`. | `string` | `"1Gi"` | No |
| `min_replicas` | Minimum number of replicas. Production requires `>= 2`. | `number` | `0` | No |
| `max_replicas` | Maximum number of replicas. | `number` | `5` | No |
| `target_port` | Port the container listens on. | `number` | `8080` | No |
| `environment_variables` | Map of non-sensitive environment variables. | `map(string)` | `{}` | No |
| `secrets` | Map of sensitive environment variables (marked sensitive). | `map(string)` | `{}` | No |
| `subnet_id` | Subnet resource ID for VNet integration. | `string` | `null` | No |
| `custom_domain` | Optional custom domain for the ingress. | `string` | `null` | No |
| `health_check_path` | HTTP path for liveness and readiness probes. | `string` | `"/healthz"` | No |
| `container_app_environment_id` | Resource ID of an existing Container App Environment to use. | `string` | `null` | No |

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| `container_app_id` | The resource ID of the Container App. | No |
| `container_app_name` | The name of the Container App. | No |
| `container_app_fqdn` | The fully-qualified domain name of the Container App ingress. | No |
| `resource_group_name` | The name of the resource group. | No |
| `managed_identity_id` | The resource ID of the user-assigned managed identity. | No |
| `managed_identity_client_id` | The client ID of the user-assigned managed identity. | No |
| `managed_identity_principal_id` | The principal ID of the user-assigned managed identity. | No |
| `application_insights_connection_string` | The Application Insights connection string. | Yes |
| `application_insights_instrumentation_key` | The Application Insights instrumentation key. | Yes |

## Production Guardrails

This module enforces the following constraints at plan time:

- **High availability**: When `environment = "prod"`, `min_replicas` must be `>= 2`. Deploying a production Container App with a minimum of fewer than two replicas will cause `terraform plan` to fail with an informative error message.

## Notes

- Secrets are injected into the container both as Container App secrets and as environment variables. The environment variable name is the secret map key uppercased with hyphens replaced by underscores. For example, a secret named `db-connection-string` becomes the environment variable `DB_CONNECTION_STRING`.
- When `container_app_environment_id` is provided, no new Container App Environment is created. This is recommended when multiple Container Apps share a single environment for cost efficiency.
- The module always creates a new resource group. If you need to deploy into an existing resource group, fork this module and remove the `azurerm_resource_group` resource.
