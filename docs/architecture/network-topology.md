# Network Topology

## Overview

The Apex Platform uses a hub-and-spoke topology. All egress traffic routes through the hub Azure Firewall, and all spoke VNets peer bidirectionally with the hub.

## CIDR Allocation

| Network | CIDR | Purpose |
|---|---|---|
| Hub VNet | `10.0.0.0/16` | Centralised connectivity services |
| AzureFirewallSubnet | `10.0.0.0/26` | Azure Firewall (requires /26 minimum) |
| AzureBastionSubnet | `10.0.1.0/26` | Azure Bastion |
| GatewaySubnet | `10.0.2.0/27` | VPN/ExpressRoute gateway (reserved) |
| ManagementSubnet | `10.0.3.0/24` | Management and monitoring tools |
| DnsInboundSubnet | `10.0.4.0/28` | Azure DNS Private Resolver inbound |
| Orders spoke (prod) | `10.10.0.0/22` | Production landing zone for Orders team |
| Orders spoke (dev) | `10.11.0.0/22` | Non-production landing zone for Orders team |

## Spoke Subnet Design

Each `/22` spoke VNet is divided into four subnets using `cidrsubnet()`:

| Subnet | Size | Purpose |
|---|---|---|
| ApplicationSubnet | `/24` | Container Apps, App Service Environments |
| DataSubnet | `/24` | Databases, Redis Cache |
| PrivateEndpointSubnet | `/24` | Private endpoints for PaaS services |
| IntegrationSubnet | `/25` | VNet Integration for App Service / Functions |

## DNS Flow

1. Azure resources use the hub VNet DNS server (`168.63.129.16`) via DNS forwarding.
2. The hub hosts private DNS zones linked to the hub VNet.
3. On spoke creation, the spoke is linked to the relevant private DNS zones in the hub.
4. Public DNS resolves via Azure-provided DNS; private DNS resolves via the private zones.

## Private DNS Zones

| Zone | Used By |
|---|---|
| `privatelink.blob.core.windows.net` | Storage accounts |
| `privatelink.vaultcore.azure.net` | Key Vault |
| `privatelink.database.windows.net` | Azure SQL |
| `privatelink.azurecr.io` | Container Registry |
| `privatelink.azurewebsites.net` | App Service / Functions |

## Egress Firewall Rules

All internet egress traverses the hub Azure Firewall. The following application rule collections are pre-configured:

### `platform-core`
| FQDN | Port | Purpose |
|---|---|---|
| `*.microsoft.com` | 443 | Azure management |
| `*.azure.com` | 443 | Azure services |
| `time.windows.com` | 123/UDP | NTP |
| `*.cloudflare-dns.com` | 443 | DNS over HTTPS |

### `development-tools`
| FQDN | Port | Purpose |
|---|---|---|
| `api.nuget.org`, `*.nuget.org` | 443 | .NET package restore |
| `pypi.org`, `files.pythonhosted.org` | 443 | Python package install |
| `registry.npmjs.org` | 443 | Node.js package install |
| `registry-1.docker.io`, `auth.docker.io` | 443 | Docker Hub pull |
| `github.com`, `*.github.com` | 443 | GitHub access |
