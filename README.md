# Apex Platform

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5-blue.svg)](https://www.terraform.io/)
[![Azure Provider](https://img.shields.io/badge/azurerm-%3E%3D3.80-623CE4.svg)](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
[![Unit Tests](https://github.com/abhishekbagde/apex-platform/actions/workflows/unit-tests.yml/badge.svg)](https://github.com/abhishekbagde/apex-platform/actions/workflows/unit-tests.yml)

Apex Platform is a production-grade Internal Developer Platform (IDP) built on Microsoft Azure. It provides a set of reusable Terraform modules, CI/CD pipeline templates, policy definitions, and golden path starters that engineering teams can use to provision infrastructure, enforce organisational standards, and ship services faster without reinventing the wheel each time.

The design is opinionated where it needs to be — naming conventions, tagging, network topology, secret management — and flexible everywhere else.

## What is included

### Terraform Modules

Nine reusable modules covering the most common Azure workloads:

| Module | Purpose |
|--------|---------|
| `azure-container-app` | Containerised workloads with auto-scaling, managed identity, and Application Insights |
| `azure-function-app` | Event-driven compute with Key Vault references and VNet integration |
| `azure-key-vault` | Secrets and encryption keys with RBAC authorisation and private endpoints |
| `azure-spoke-vnet` | Hub-and-spoke networking with NSGs, route tables, and bidirectional VNet peering |
| `azure-sql-database` | Managed SQL with private endpoint, Entra admin option, and backup guardrails |
| `azure-static-web-app` | Globally distributed static sites with optional custom domain |
| `azure-budget` | Subscription cost budgets with 50%, 75%, and 90% alert thresholds |
| `azure-secret-rotation` | Automated Key Vault secret rotation via Event Grid and Function App |
| `azure-landing-zone` | Composes spoke VNet, budget, and policy assignments for a team environment |

Every module follows the same structure: `main.tf`, `variables.tf`, `outputs.tf`, `locals.tf`, `versions.tf`, a README, and working examples under `examples/`. Input validation and production guardrails (lifecycle preconditions) are built in.

### CI/CD Pipeline Templates

Reusable pipeline templates for both Azure DevOps and GitLab CI:

- Terraform plan-on-PR, apply-on-merge with state backup
- Drift detection on a cron schedule with Teams notification
- Application pipelines for .NET, Python, and React with Docker build, security scanning, and staged deployments
- Shared step libraries for common operations

### Policy as Code

- Azure Policy definitions for mandatory tagging, diagnostic settings, public storage denial, and region restrictions
- OPA policies for validating Terraform plans and CI/CD pipeline structure before they reach Azure

### Golden Path Templates

Working application starters for the three most common service types:

- `.NET 8 microservice` — ASP.NET Core, OpenTelemetry, health checks, MSAL, structured logging via Serilog
- `Python Django API` — Django REST Framework, gunicorn, Azure Identity for Key Vault, health checks
- `React/Vite frontend` — React 18, MSAL authentication, TypeScript, optimised builds for Static Web App

Each golden path includes a `catalog-info.yaml` for Backstage, an `azure-pipelines.yml`, a `.gitlab-ci.yml`, and a `terraform/` directory that calls the platform modules.

### Backstage Integration

Scaffolder templates for all three golden paths, a platform systems catalogue entry, and an `app-config.yaml` wiring up Microsoft auth, TechDocs, and Azure DevOps proxy.

### Compliance Scripts

Two Python scripts for ongoing compliance work:

- `audit-rbac-assignments.py` — Lists RBAC role assignments and flags direct User assignments (should be group-based)
- `generate-evidence-report.py` — Queries Azure Policy compliance states and produces a JSON evidence report

### Documentation

- Architecture Decision Records for the three main design choices (Terraform over Bicep, Backstage over alternatives, hub-and-spoke over vWAN)
- Architecture guides covering platform layers, network topology, and the identity model
- Operational runbooks for drift remediation, secret rotation failure, and pipeline triage
- A platform charter covering operating principles and support tiers

## Repository Structure

```
apex-platform/
├── terraform/
│   ├── modules/                    # 9 reusable Terraform modules
│   ├── environments/
│   │   ├── global/                 # Management groups, AAD groups, policies
│   │   ├── connectivity/           # Hub VNet, Firewall, Bastion, DNS
│   │   └── landing-zones/          # Production and non-production examples
│   └── tests/                      # Terratest integration tests (requires Azure)
│
├── pipelines/
│   ├── templates/
│   │   ├── azure-devops/
│   │   └── gitlab-ci/
│   └── shared/steps/
│
├── backstage/
│   ├── templates/
│   ├── catalog/
│   └── app-config.yaml
│
├── golden-paths/
│   ├── dotnet-microservice/
│   ├── python-django-api/
│   └── react-frontend/
│
├── policies/
│   ├── azure-policy/
│   └── opa/
│
├── scripts/
│   ├── setup/                      # bootstrap.sh, bootstrap.ps1
│   ├── tools/                      # create-team-landing-zone.sh
│   └── compliance/                 # generate-evidence-report.py, audit-rbac-assignments.py
│
├── docs/
│   ├── adr/
│   ├── architecture/
│   ├── runbooks/
│   └── PLATFORM-CHARTER.md
│
├── .github/
│   └── workflows/
│       ├── unit-tests.yml          # Terraform, OPA, Python, React tests
│       └── terraform-lint.yml
│
├── PLATFORM-CONTRACT.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

## Prerequisites

- Terraform >= 1.5
- Azure CLI >= 2.50
- An Azure subscription with Owner or Contributor + User Access Administrator
- Git

## Quick Start

**Clone the repository:**

```bash
git clone https://github.com/abhishekbagde/apex-platform.git
cd apex-platform
```

**Bootstrap the platform** (creates the Terraform state storage account and initialises the global environment):

```bash
# Linux/macOS
chmod +x scripts/setup/bootstrap.sh
./scripts/setup/bootstrap.sh --subscription-id <your-subscription-id>

# Windows (PowerShell 7+)
.\scripts\setup\bootstrap.ps1 -SubscriptionId <your-subscription-id>
```

**Deploy connectivity** (hub VNet, Firewall, Bastion, DNS):

```bash
cd terraform/environments/connectivity
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

**Create a team landing zone:**

```bash
./scripts/tools/create-team-landing-zone.sh \
  --team orders \
  --env production \
  --vnet-cidr 10.10.0.0/22

cd terraform/environments/landing-zones/production/orders
terraform init && terraform apply
```

## Naming Convention

All modules use the same pattern:

```
{prefix}-{application_name}-{environment}-{region_short}-{instance_number}
```

For example: `ca-orders-prod-uks-01`

**Region short codes:** `uksouth=uks`, `ukwest=ukw`, `westeurope=weu`, `northeurope=neu`, `eastus=eus`, `eastus2=eus2`, `westus2=wus2`

**Common prefixes:** `ca` Container App, `kv` Key Vault, `sql` SQL Server, `func` Function App, `vnet` Virtual Network, `snet` Subnet, `id` Managed Identity, `appi` Application Insights

## Running Tests

The CI pipeline runs four test suites on every pull request and push to main. You can run them locally without any Azure credentials.

**Terraform native tests** (mock provider, no real Azure calls):

```bash
cd terraform/modules/azure-container-app
terraform init -backend=false
terraform test
```

**OPA policy tests:**

```bash
opa test policies/opa/ -v
```

**Python compliance tests:**

```bash
pip install -r scripts/compliance/requirements-test.txt
pytest scripts/compliance/tests/ -v --cov=scripts/compliance --cov-fail-under=80
```

**React unit tests:**

```bash
cd golden-paths/react-frontend
npm install
npm test
npm run test:coverage
```

**Terratest integration tests** (require a real Azure subscription):

```bash
cd terraform/tests
go test -v ./... -timeout 30m
```

## Module Usage Example

```hcl
module "orders_api" {
  source = "../../modules/azure-container-app"

  application_name           = "orders"
  environment                = "prod"
  location                   = "uksouth"
  container_image            = "myregistry.azurecr.io/orders-api:1.2.3"
  log_analytics_workspace_id = module.connectivity.log_analytics_workspace_id

  team        = "orders-team"
  cost_centre = "ENG-001"

  min_replicas = 2   # enforced by guardrail in production
  max_replicas = 10
}
```

## Architecture Decisions

The three most consequential design decisions are documented in `docs/adr/`:

- [001 — Terraform over Bicep](docs/adr/001-terraform-over-bicep.md): chosen for multi-cloud portability and ecosystem maturity
- [002 — Backstage over alternatives](docs/adr/002-backstage-for-portal.md): open source with a strong plugin model
- [003 — Hub-and-spoke over vWAN](docs/adr/003-hub-spoke-over-vwan.md): deterministic routing, lower cost, easier to reason about

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for branch naming conventions, the pull request process, Terraform coding standards, and testing requirements.

Before opening a PR:

1. Run `terraform fmt -recursive terraform/` and `terraform validate` on any changed modules
2. Ensure all unit tests pass locally
3. Update the module README and examples if you changed inputs or outputs
4. Reference any related issue in the PR description

## Platform Contract

[PLATFORM-CONTRACT.md](PLATFORM-CONTRACT.md) documents the current module versions, supported environment names and locations, required tagging schema, and pipeline template compatibility. Update it when making breaking changes.

## License

MIT. See [LICENSE](LICENSE) for details.

## About

Built by [Abhishek Bagde](https://github.com/abhishekbagde) — cloud architect and platform engineer with a focus on Azure, infrastructure automation, and developer experience.

Issues and pull requests are welcome.
