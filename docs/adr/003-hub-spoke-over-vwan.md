# ADR-003: Hub-and-Spoke Topology over Azure Virtual WAN

**Status:** Accepted
**Date:** 2025-01-25
**Author:** Abhishek Bagde

## Context

The platform requires a network topology that provides centralised security inspection, controlled internet egress, and private connectivity between landing zones and shared services. The two main Azure networking topologies are traditional hub-and-spoke (with Azure Firewall) and Azure Virtual WAN.

## Decision

We will use a **traditional hub-and-spoke** topology with a single hub VNet (`10.0.0.0/16` in UK South), Azure Firewall, and spoke VNets peered bidirectionally to the hub.

## Consequences

### Positive
- **Deterministic routing.** User-defined routes (UDRs) on spoke subnets force all traffic through the hub firewall, giving us full visibility and control. vWAN routing is managed by Microsoft and can be harder to reason about.
- **Lower cost at our scale.** vWAN charges per routing unit and per connected unit. At fewer than ten spoke VNets, hub-and-spoke with a single Azure Firewall instance is considerably cheaper.
- **Simpler Terraform model.** Standard `azurerm_virtual_network_peering` resources are well-supported; vWAN requires `azurerm_virtual_hub` and `azurerm_virtual_hub_connection`, which are less mature.
- **Familiar operations.** Network engineers understand hub-and-spoke; vWAN introduces a new operational model.

### Negative
- **Manual peering management.** Each new spoke requires two peering resources (hub→spoke and spoke→hub). We automate this in the `azure-spoke-vnet` module.
- **Single region.** This design targets UK South; multi-region expansion would require additional hub VNets. vWAN handles multi-region more elegantly.

## Alternatives Considered

| Alternative | Reason Rejected |
|---|---|
| Azure Virtual WAN | Higher cost; routing less transparent; overkill at current scale |
| Flat VNet (no hub) | No centralised egress inspection; violates security baseline |

## References

- [Azure hub-spoke reference architecture](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [Azure Virtual WAN overview](https://learn.microsoft.com/en-us/azure/virtual-wan/virtual-wan-about)
