# Apex Platform Contract

This document defines the stable interfaces that the Apex Platform team commits to maintaining. Application teams should treat these as the authoritative source of truth for integration.

## Module Versions

| Module | Current Version | Minimum Supported | Breaking Change Policy |
|---|---|---|---|
| `azure-container-app` | v0.1.0 | v0.1.0 | 90 days notice |
| `azure-key-vault` | v0.1.0 | v0.1.0 | 90 days notice |
| `azure-spoke-vnet` | v0.1.0 | v0.1.0 | 90 days notice |
| `azure-sql-database` | v0.1.0 | v0.1.0 | 90 days notice |
| `azure-function-app` | v0.1.0 | v0.1.0 | 90 days notice |
| `azure-static-web-app` | v0.1.0 | v0.1.0 | 90 days notice |
| `azure-budget` | v0.1.0 | v0.1.0 | 90 days notice |
| `azure-secret-rotation` | v0.1.0 | v0.1.0 | 90 days notice |
| `azure-landing-zone` | v0.1.0 | v0.1.0 | 90 days notice |

## Pipeline Template Versions

| Template | Current Version | Platform |
|---|---|---|
| `terraform-plan-apply` | v0.1.0 | Azure DevOps, GitLab |
| `dotnet-microservice` | v0.1.0 | Azure DevOps, GitLab |
| `python-api` | v0.1.0 | Azure DevOps, GitLab |
| `react-frontend` | v0.1.0 | Azure DevOps, GitLab |
| `drift-detection` | v0.1.0 | Azure DevOps, GitLab |

## Golden Path Template Versions

| Template | Current Version | Runtimes |
|---|---|---|
| `dotnet-microservice` | v0.1.0 | .NET 8 |
| `python-django-api` | v0.1.0 | Python 3.12 |
| `react-frontend` | v0.1.0 | Node 20, React 18 |

## SLA Commitments

| Commitment | Target |
|---|---|
| Module bug fix (P2) | Released within 5 business days |
| Security patch | Released within 24 hours of CVE disclosure |
| Breaking change notice | 90 days minimum |
| Golden path template update | Within 30 days of runtime LTS release |
| Pipeline template compatibility | Maintained for 2 major versions |

## Deprecation Policy

1. Deprecated modules are marked with a `# DEPRECATED` comment in `versions.tf` and a notice in `README.md`.
2. Deprecated modules receive security patches only; no new features.
3. After the deprecation period, the module directory is moved to `terraform/modules/deprecated/`.

## Change Log

All module changes are recorded in [CHANGELOG.md](CHANGELOG.md) using the [Keep a Changelog](https://keepachangelog.com/) format.
