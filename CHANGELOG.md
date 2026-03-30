# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2024-01-15

### Added

- `terraform/modules/azure-container-app` — Reusable Terraform module for provisioning Azure Container Apps with support for ingress configuration, scaling rules, managed identity, and environment variable injection from Key Vault references.
- `terraform/modules/azure-key-vault` — Reusable Terraform module for provisioning Azure Key Vault instances with configurable access policies, private endpoint support, soft-delete and purge-protection settings, and diagnostic log routing.
- `terraform/modules/azure-sql-database` — Reusable Terraform module for provisioning Azure SQL Database with elastic pool support, geo-redundant backup configuration, Active Directory administrator assignment, and auditing to a Storage Account.
- `terraform/modules/azure-spoke-vnet` — Reusable Terraform module for provisioning spoke Virtual Networks including subnet delegation, Network Security Group association, and peering to a hub VNet via Azure Virtual Network Manager.
- `terraform/modules/azure-function-app` — Reusable Terraform module for provisioning Azure Function Apps (Flex Consumption plan) with managed identity, VNET integration, Key Vault secret references, and Application Insights instrumentation.
- `terraform/modules/azure-static-web-app` — Reusable Terraform module for provisioning Azure Static Web Apps with custom domain support, linked back-end API routing, and enterprise-edge CDN configuration.
- `terraform/modules/azure-budget` — Reusable Terraform module for provisioning Azure Cost Management budgets with configurable time-grain, alert thresholds, and action-group notification targets for FinOps governance.
- `policies/` — Azure Policy definitions and initiative assignments for enforcing tagging standards, permitted SKUs, private endpoint requirements, and diagnostic settings across all subscriptions in the platform landing zone.
- `backstage/` — Backstage Software Catalogue configuration including `catalog-info.yaml` templates for all platform modules, a custom Scaffolder action for generating new module skeletons, and TechDocs site configuration.
- `pipelines/` — Reusable Azure DevOps YAML pipeline templates for module validation (`terraform fmt`, `terraform validate`, `tflint`, Checkov), plan-on-PR, and apply-on-merge workflows, together with a Workload Identity Federation service connection bootstrap script.
- `docs/` — Platform architecture decision records (ADRs), module authoring guide, naming convention reference, on-boarding guide for new consumers, and the FinOps tagging strategy document.
- `.github/workflows/terraform-lint.yml` — GitHub Actions workflow that runs `terraform fmt`, `terraform validate`, `tflint`, and Checkov against all Terraform source on every pull request targeting paths under `terraform/**`.
- `.github/CODEOWNERS` — Code ownership assignments mapping each module directory to the responsible platform sub-team, ensuring the correct reviewers are automatically requested on every pull request.
- `CONTRIBUTING.md` — Contribution guidelines covering branch naming, pull-request process, Terraform coding standards, testing requirements, and community-of-practice cadence.
- `LICENSE` — MIT licence covering all content in this repository.

[Unreleased]: https://github.com/apex-platform/apex-platform/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/apex-platform/apex-platform/releases/tag/v0.1.0
