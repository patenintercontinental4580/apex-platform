# ADR-002: Backstage as the Internal Developer Portal

**Status:** Accepted
**Date:** 2025-01-20
**Author:** Abhishek Bagde

## Context

Teams need a single pane of glass to discover services, scaffold new projects using golden paths, access runbooks, and view platform health. We evaluated open-source and commercial Internal Developer Portal (IDP) options.

## Decision

We will use **Spotify Backstage** as the Internal Developer Portal for the Apex Platform.

## Consequences

### Positive
- **Open source with no per-seat licensing.** Cortex and Port charge per developer seat; Backstage is free to host.
- **Plugin model.** The extensive plugin catalogue covers TechDocs, GitHub, Azure DevOps, Cost Insights, and more. Custom plugins can be written in TypeScript.
- **Scaffolder golden paths.** The `@backstage/plugin-scaffolder` integrates directly with our golden path templates, enabling self-service project creation with guardrails.
- **CNCF project.** Large community, long-term viability, and a clear governance model.

### Negative
- **Operational overhead.** We host and maintain the Backstage instance. This requires a Kubernetes deployment and ongoing upgrades.
- **TypeScript required for plugins.** Platform engineers unfamiliar with React/TypeScript will face a learning curve when writing custom plugins.

## Alternatives Considered

| Alternative | Reason Rejected |
|---|---|
| Cortex | Commercial; per-developer pricing scales poorly |
| Port | Commercial; SaaS-only option limits data sovereignty |
| Custom-built portal | Prohibitive build and maintenance cost |

## References

- [Backstage.io](https://backstage.io)
- [Backstage Scaffolder documentation](https://backstage.io/docs/features/software-templates/)
