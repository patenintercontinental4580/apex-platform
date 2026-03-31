# azure-landing-zone

Terraform **composition module** that provisions a complete team landing zone on the Apex Platform. It combines the `azure-spoke-vnet` and `azure-budget` child modules to deliver a self-contained, network-connected, cost-governed environment for a single team in a single Azure subscription.

## What It Provisions

| Component | Module | Description |
|-----------|--------|-------------|
| Spoke VNet | `azure-spoke-vnet` | Peered spoke VNet with four subnets and UDR routing traffic via the hub firewall |
| Consumption Budget | `azure-budget` | Monthly subscription budget with 50%/75%/90% alerts |

## Architecture

```
Hub Subscription                   Team Subscription
┌─────────────────┐               ┌──────────────────────────────┐
│  Hub VNet       │◄──Peering────►│  Spoke VNet (this module)    │
│  Azure Firewall │               │  ├── ApplicationSubnet        │
└─────────────────┘               │  ├── DataSubnet               │
                                  │  ├── PrivateEndpointSubnet    │
                                  │  └── IntegrationSubnet        │
                                  └──────────────────────────────┘
                                  ┌──────────────────────────────┐
                                  │  Consumption Budget          │
                                  │  50% / 75% / 90% alerts      │
                                  └──────────────────────────────┘
```

## Usage

```hcl
module "orders_landing_zone" {
  source = "git::https://github.com/your-org/apex-platform.git//terraform/modules/azure-landing-zone"

  providers = {
    azurerm     = azurerm
    azurerm.hub = azurerm.hub
  }

  team_name               = "orders"
  environment             = "prod"
  address_space           = "10.1.0.0/22"
  hub_vnet_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-apex-connectivity/providers/Microsoft.Network/virtualNetworks/vnet-apex-hub-uks"
  hub_vnet_name           = "vnet-apex-hub-uks"
  hub_resource_group      = "rg-apex-connectivity"
  hub_firewall_private_ip = "10.0.0.4"
  monthly_budget          = 2000
  alert_emails            = ["orders-team@example.com"]
  escalation_emails       = ["platform-team@example.com"]
  cost_centre             = "CC-ORDERS"
  subscription_id         = var.orders_subscription_id
}
```

> **Note:** This module requires two provider configurations — `azurerm` (for the team subscription) and `azurerm.hub` (for the hub subscription). Both must be passed explicitly via the `providers` meta-argument.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `team_name` | The name of the team that owns this landing zone. | `string` | — | Yes |
| `environment` | Deployment environment: `dev`, `staging`, or `prod`. | `string` | — | Yes |
| `address_space` | CIDR address space for the spoke VNet (e.g. `10.1.0.0/22`). | `string` | — | Yes |
| `hub_vnet_id` | Resource ID of the hub VNet to peer with. | `string` | — | Yes |
| `hub_vnet_name` | Name of the hub VNet. | `string` | — | Yes |
| `hub_resource_group` | Resource group of the hub VNet. | `string` | — | Yes |
| `hub_firewall_private_ip` | Private IP of the hub Azure Firewall (default route next hop). | `string` | — | Yes |
| `monthly_budget` | Monthly budget amount in GBP. | `number` | — | Yes |
| `alert_emails` | Email addresses to notify at all budget thresholds. | `list(string)` | — | Yes |
| `escalation_emails` | Additional email addresses for 75% and 90% alerts. | `list(string)` | `[]` | No |
| `location` | Azure region for landing zone resources. | `string` | `"uksouth"` | No |
| `cost_centre` | Cost centre code for billing allocation. | `string` | — | Yes |
| `subscription_id` | Azure subscription ID for the consumption budget. | `string` | — | Yes |
| `budget_start_date` | Budget start date in RFC3339 format. | `string` | `"2024-01-01T00:00:00Z"` | No |

## Outputs

| Name | Description |
|------|-------------|
| `vnet_id` | The ID of the spoke VNet. |
| `vnet_name` | The name of the spoke VNet. |
| `application_subnet_id` | The ID of the ApplicationSubnet. |
| `data_subnet_id` | The ID of the DataSubnet. |
| `private_endpoint_subnet_id` | The ID of the PrivateEndpointSubnet. |
| `integration_subnet_id` | The ID of the IntegrationSubnet. |
| `budget_id` | The ID of the consumption budget. |

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.5.0 |
| azurerm | ~> 3.80 |
