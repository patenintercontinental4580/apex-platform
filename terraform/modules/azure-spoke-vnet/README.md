# azure-spoke-vnet

Terraform module that provisions a fully-configured spoke Virtual Network for the Apex Platform hub-and-spoke topology. The module creates the VNet, four purpose-built subnets with NSGs, a route table that forces all egress through the hub Azure Firewall, and bidirectional VNet peerings to the hub.

## Architecture

```
Hub VNet
  └── Azure Firewall (10.0.0.68)
        ↕ peering
Spoke VNet (e.g. 10.1.0.0/22)
  ├── ApplicationSubnet  (10.1.0.0/24) — App Services / Container Apps
  ├── DataSubnet         (10.1.1.0/24) — Reserved for data tier resources
  ├── PrivateEndpointSubnet (10.1.2.0/24) — Private Endpoints only
  └── IntegrationSubnet  (10.1.3.0/25) — Delegated to Microsoft.App/environments
```

All subnets except PrivateEndpointSubnet have a UDR that sends `0.0.0.0/0` to the hub firewall. Each subnet has a dedicated NSG with a terminal `DenyAllInbound` rule at priority 4096.

## Provider Aliases

This module **requires** two provider configurations from the caller:

| Alias | Purpose |
|-------|---------|
| *(default)* | Spoke subscription — creates the spoke VNet and spoke-to-hub peering |
| `azurerm.hub` | Hub subscription — creates the hub-to-spoke peering inside the hub resource group |

Without the `azurerm.hub` alias the module will fail to plan. See the example below for the required configuration.

## Usage

```hcl
provider "azurerm" {
  features {}
  subscription_id = "00000000-0000-0000-0000-000000000001" # spoke subscription
}

provider "azurerm" {
  alias           = "hub"
  features {}
  subscription_id = "00000000-0000-0000-0000-000000000000" # hub subscription
}

module "orders_spoke" {
  source = "../../terraform/modules/azure-spoke-vnet"

  providers = {
    azurerm     = azurerm
    azurerm.hub = azurerm.hub
  }

  spoke_name              = "orders"
  address_space           = "10.1.0.0/22"
  environment             = "prod"
  team                    = "Platform Engineering"
  cost_centre             = "CC-1234"
  location                = "uksouth"

  hub_vnet_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub-prod-uks/providers/Microsoft.Network/virtualNetworks/vnet-hub-prod-uks"
  hub_vnet_name           = "vnet-hub-prod-uks"
  hub_resource_group      = "rg-hub-prod-uks"
  hub_firewall_private_ip = "10.0.0.68"
}
```

## Inputs

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `spoke_name` | `string` | — | yes | Short name for the spoke, e.g. `orders` or `payments` |
| `address_space` | `string` | — | yes | CIDR block for the spoke VNet, e.g. `10.1.0.0/22` |
| `hub_vnet_id` | `string` | — | yes | Full resource ID of the hub VNet |
| `hub_vnet_name` | `string` | — | yes | Name of the hub VNet |
| `hub_resource_group` | `string` | — | yes | Resource group that contains the hub VNet |
| `hub_firewall_private_ip` | `string` | — | yes | Private IP of the Azure Firewall used as UDR next-hop |
| `environment` | `string` | — | yes | One of: `dev`, `staging`, `prod` |
| `team` | `string` | — | yes | Team name applied as a resource tag |
| `cost_centre` | `string` | — | yes | Cost centre code applied as a resource tag |
| `location` | `string` | `"uksouth"` | no | Azure region for all resources |

## Outputs

| Name | Description |
|------|-------------|
| `vnet_id` | Resource ID of the spoke VNet |
| `vnet_name` | Name of the spoke VNet |
| `resource_group_name` | Name of the spoke resource group |
| `application_subnet_id` | Resource ID of ApplicationSubnet |
| `data_subnet_id` | Resource ID of DataSubnet |
| `private_endpoint_subnet_id` | Resource ID of PrivateEndpointSubnet |
| `integration_subnet_id` | Resource ID of IntegrationSubnet |
| `route_table_id` | Resource ID of the route table |

## Subnet CIDR Allocation

The module derives all subnet CIDRs automatically from `address_space` using `cidrsubnet`. For a `/22` base block:

| Subnet | Offset | Size | Example CIDR |
|--------|--------|------|--------------|
| ApplicationSubnet | +2 bits, index 0 | /24 | 10.1.0.0/24 |
| DataSubnet | +2 bits, index 1 | /24 | 10.1.1.0/24 |
| PrivateEndpointSubnet | +2 bits, index 2 | /24 | 10.1.2.0/24 |
| IntegrationSubnet | +3 bits, index 6 | /25 | 10.1.3.0/25 |

## Resource Naming

All resources follow the Apex Platform naming convention: `{prefix}-{spoke_name}-{environment}-{region_short_code}`.

Example for `spoke_name = "orders"`, `environment = "prod"`, `location = "uksouth"`:

| Resource | Name |
|----------|------|
| Resource Group | `rg-orders-prod-uks` |
| VNet | `vnet-orders-prod-uks` |
| Route Table | `rt-orders-prod-uks` |
| Application NSG | `nsg-application-orders-prod-uks` |
| Data NSG | `nsg-data-orders-prod-uks` |
| Private Endpoint NSG | `nsg-pe-orders-prod-uks` |
| Integration NSG | `nsg-integration-orders-prod-uks` |

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.5.0 |
| azurerm | ~> 3.80 |
