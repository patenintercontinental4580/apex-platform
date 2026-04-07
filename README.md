# Apex Platform: A Production-Grade Internal Developer Platform on Azure

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Terraform](https://img.shields.io/badge/Terraform-≥1.5-blue.svg)](https://www.terraform.io/)
[![Azure Provider](https://img.shields.io/badge/Azure%20Provider-≥3.0-green.svg)](https://registry.terraform.io/providers/hashicorp/azurerm/latest)

> **The companion repository for the book "Platform Engineering on Azure" by Abhishek Bagde**

Apex Platform is a production-grade **Internal Developer Platform (IDP)** implemented on Microsoft Azure. It demonstrates enterprise-scale platform engineering practices using Infrastructure as Code (IaC), GitOps principles, and modern cloud-native architecture patterns.

## 📚 What is Apex Platform?

Apex Platform is a complete reference architecture for building an Internal Developer Platform that enables engineering teams to:

- **Self-serve infrastructure provisioning** through golden paths and scaffolder templates
- **Enforce organizational standards** via Azure Policies and OPA (Open Policy Agent)
- **Automate deployment pipelines** with reusable CI/CD templates for Azure DevOps and GitLab
- **Discover and manage services** through the Backstage Software Catalogue
- **Scale securely** with built-in compliance, tagging governance, and audit trails
- **Accelerate time-to-value** with curated starter templates for .NET, Python, and React applications

This repository contains **production-ready Terraform modules, pipeline templates, policy definitions, and documentation** — everything you need to build and operate a modern platform on Azure.

## 🎯 Key Features

### 🏗️ Infrastructure as Code (Terraform Modules)

Nine reusable, battle-tested Terraform modules for common Azure workloads:

- **`azure-container-app`** — Serverless containerized applications with auto-scaling, managed identity, Application Insights integration
- **`azure-function-app`** — Event-driven serverless compute with VNet integration and Key Vault references
- **`azure-key-vault`** — Secure secrets and encryption key management with RBAC and private endpoints
- **`azure-spoke-vnet`** — Hub-and-spoke network topology with NSGs, route tables, and bidirectional VNet peering
- **`azure-sql-database`** — Managed relational databases with private endpoint, geo-replication, and Entra auth
- **`azure-static-web-app`** — Globally distributed static sites with custom domains
- **`azure-budget`** — Cost governance with 50%/75%/90% alert thresholds
- **`azure-secret-rotation`** — Automated Key Vault secret rotation via Event Grid + Function App
- **`azure-landing-zone`** — Composes spoke VNet + budget + policy assignments for a team

All modules include:
- ✅ Input validation and guardrails
- ✅ Sensible defaults aligned with Microsoft Well-Architected Framework
- ✅ Tagging strategies for FinOps governance
- ✅ Diagnostic settings for compliance and observability
- ✅ Complete examples (basic and advanced configurations)
- ✅ Comprehensive README documentation

### 🚀 CI/CD Pipelines

Reusable pipeline templates for:

- **Azure DevOps** — Plan-on-PR, apply-on-merge workflows with Terraform linting and policy validation
- **GitLab CI** — Multi-stage pipelines with artifact caching and environment promotions
- Automated Terraform validation (`terraform fmt`, `terraform validate`, `tflint`, Checkov)
- Workload Identity Federation integration for keyless authentication
- Shared variable groups and secure credential management

### 📋 Platform Policies

Azure Policies and OPA rules to enforce:

- **Tagging standards** — Mandatory resource tags (team, cost-centre, environment, etc.)
- **SKU compliance** — Approved VM sizes, storage types, and database editions
- **Security controls** — Private endpoints, encryption at rest, RBAC requirements
- **Diagnostic settings** — Mandatory audit logging for compliance
- **Naming conventions** — Standardized resource names across the organization

### 🎨 Backstage Integration

**Backstage Software Catalogue** configuration including:

- Pre-built scaffolder templates for .NET, Python, and React golden paths
- Automatic service registration and documentation
- Custom Backstage actions for generating module skeletons
- TechDocs site for searchable platform documentation

### 🏆 Golden Path Templates

Starter skeletons for common application types:

- **`.NET 8 Microservice`** — Minimal container image with ASP.NET Core, health checks, structured logging
- **`Python Django API`** — Multi-stage Docker build, environment configuration, database migrations
- **`React/Vite Frontend`** — Client-side routing, environment variables, optimized builds for CDN deployment

### 📖 Documentation

Comprehensive documentation covering:

- **Architecture Decision Records (ADRs)** — Design rationale for platform patterns
- **Module Authoring Guide** — How to extend the platform with custom modules
- **Naming Convention Reference** — Resource naming patterns and region codes
- **On-boarding Guide** — Getting started for teams and consumers
- **FinOps Strategy** — Cost governance and tagging taxonomy
- **Operational Runbooks** — Troubleshooting and disaster recovery procedures

### ✅ Governance & Compliance

Built-in support for:

- **Azure Policy Initiative Assignments** — Enforce organizational standards
- **Cost Management Budgets** — Alert thresholds and spending governance
- **Diagnostic Settings** — Centralized logging to Log Analytics
- **RBAC** — Role-based access control with managed identities
- **Audit Trails** — Full traceability of infrastructure changes via Git history and Azure Activity Logs

## 🗂️ Repository Structure

```
apex-platform/
├── terraform/
│   ├── modules/                    # 9 reusable Terraform modules
│   │   ├── azure-container-app/
│   │   ├── azure-function-app/
│   │   ├── azure-key-vault/
│   │   ├── azure-spoke-vnet/
│   │   ├── azure-sql-database/
│   │   ├── azure-static-web-app/
│   │   ├── azure-budget/
│   │   ├── azure-secret-rotation/
│   │   └── azure-landing-zone/
│   ├── environments/
│   │   ├── global/                 # Management groups, AAD groups, policies
│   │   ├── connectivity/           # Hub VNet, Firewall, Bastion, DNS
│   │   └── landing-zones/
│   │       ├── production/orders/
│   │       └── non-production/orders/
│   └── tests/                      # Terratest + native TF tests
│
├── pipelines/
│   ├── templates/
│   │   ├── azure-devops/           # dotnet, python, react, terraform, drift-detection
│   │   └── gitlab-ci/              # mirrored GitLab CI templates
│   └── shared/steps/               # deploy-container-app, run-integration-tests, backup-state
│
├── backstage/
│   ├── templates/                  # dotnet-microservice, python-django-api, react-frontend
│   ├── catalog/                    # platform-systems.yaml
│   └── app-config.yaml
│
├── golden-paths/
│   ├── dotnet-microservice/        # .NET 8 + OpenTelemetry + MSAL
│   ├── python-django-api/          # Python 3.12 + Django + gunicorn
│   └── react-frontend/             # React 18 + Vite + MSAL
│
├── policies/
│   ├── azure-policy/               # require-mandatory-tags, enforce-diagnostic-settings,
│   │                               # deny-public-storage, allowed-regions
│   └── opa/                        # terraform-plan-policy.rego, pipeline-policy.rego
│
├── scripts/
│   ├── setup/                      # bootstrap.sh + bootstrap.ps1
│   ├── tools/                      # create-team-landing-zone.sh
│   └── compliance/                 # generate-evidence-report.py, audit-rbac-assignments.py
│
├── docs/
│   ├── adr/                        # 001-terraform-over-bicep, 002-backstage, 003-hub-spoke
│   ├── architecture/               # platform-overview, network-topology, identity-model
│   ├── runbooks/                   # drift-remediation, secret-rotation-failure, pipeline-triage
│   └── PLATFORM-CHARTER.md
│
├── .github/
│   ├── workflows/terraform-lint.yml
│   ├── CODEOWNERS
│   └── PULL_REQUEST_TEMPLATE.md
│
├── PLATFORM-CONTRACT.md            # Module/template versions and SLA commitments
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

## 🚀 Quick Start

### Prerequisites

- **Terraform** ≥ 1.5
- **Azure CLI** ≥ 2.50
- **Azure Subscription** with Owner or Contributor + User Access Administrator
- **Git**

### 1. Clone the Repository

```bash
git clone https://github.com/abhishekbagde/apex-platform.git
cd apex-platform
```

### 2. Bootstrap the Platform

The bootstrap script creates the Terraform state storage account, initialises the global environment, and prints next steps:

```bash
# Linux/macOS
chmod +x scripts/setup/bootstrap.sh
./scripts/setup/bootstrap.sh --subscription-id <your-subscription-id>

# Windows (PowerShell 7+)
.\scripts\setup\bootstrap.ps1 -SubscriptionId <your-subscription-id>
```

### 3. Deploy Connectivity

```bash
cd terraform/environments/connectivity
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### 4. Create a Team Landing Zone

```bash
# Scaffold a new landing zone
./scripts/tools/create-team-landing-zone.sh \
  --team orders \
  --env production \
  --vnet-cidr 10.10.0.0/22

cd terraform/environments/landing-zones/production/orders
terraform init && terraform apply
```

### 5. Explore the Modules

Each module in `terraform/modules/` includes:
- `main.tf` — Resource definitions
- `variables.tf` — Input validation and descriptions
- `outputs.tf` — Exported values
- `README.md` — Module documentation
- `examples/basic/main.tf` — Minimal example
- `examples/complete/main.tf` — Advanced example with all features

## 📋 Module Reference

| Module | Purpose | Key Features |
|--------|---------|--------------|
| `azure-container-app` | Serverless containers | Auto-scaling, managed identity, prod guardrail (min_replicas ≥ 2) |
| `azure-function-app` | Event-driven compute | Y1/EP1 plans, runtime switch, Key Vault refs |
| `azure-key-vault` | Secrets management | RBAC auth, private endpoint, `for_each` role assignments |
| `azure-spoke-vnet` | Network topology | 4 subnets via `cidrsubnet()`, NSGs, UDRs, bidirectional peering |
| `azure-sql-database` | Managed databases | Private endpoint, Entra admin, prod backup guardrail |
| `azure-static-web-app` | Static content delivery | `azurerm_static_site`, optional custom domain |
| `azure-budget` | Cost governance | 50%/75% actual + 90% forecast alerts |
| `azure-secret-rotation` | Automated rotation | Function App + Event Grid `SecretNearExpiry` subscription |
| `azure-landing-zone` | Team environment | Composes spoke-vnet + budget + policy assignments |

Each module follows these conventions:

### Naming Pattern

`{resource_prefix}-{application_name}-{environment}-{region_short}-{instance_number}`

Example: `ca-orders-prod-uks-01`

**Region short codes:** uksouth=uks, ukwest=ukw, westeurope=weu, northeurope=neu, eastus=eus, eastus2=eus2, westus2=wus2

**Resource prefixes:** ca=Container App, kv=Key Vault, sql=SQL Server, st=Storage Account, func=Function App, appi=Application Insights, log=Log Analytics, vnet=Virtual Network, snet=Subnet, nsg=NSG, pip=Public IP, fw=Firewall, acr=Container Registry, agw=Application Gateway, cae=Container App Environment, id=Managed Identity

### Built-in Guardrails

- **Production environments** must have min_replicas ≥ 2 for high availability
- **All resources** are automatically tagged with team, cost-centre, environment, and application name
- **Managed identities** are created automatically for secure Azure-to-Azure authentication
- **Diagnostic settings** route logs to a centralized Log Analytics workspace
- **Input validation** ensures resource names, SKUs, and CPU/memory combinations are valid

## 🔄 Pipeline Usage

### Azure DevOps

Reference pipeline templates in your `azure-pipelines.yml`:

```yaml
trigger:
  - main

stages:
  - stage: Validate
    jobs:
      - template: pipelines/templates/azure-devops/terraform-validate.yml
        parameters:
          terraformVersion: 1.5.7
          workingDirectory: terraform/modules/azure-container-app

  - stage: Deploy
    condition: eq(variables['Build.SourceBranch'], 'refs/heads/main')
    jobs:
      - template: pipelines/templates/azure-devops/terraform-apply.yml
        parameters:
          environmentName: prod
          workingDirectory: terraform/environments/prod
```

### GitLab CI

Include pipeline templates in your `.gitlab-ci.yml`:

```yaml
include:
  - local: pipelines/templates/gitlab-ci/terraform-validate.yml
  - local: pipelines/templates/gitlab-ci/terraform-deploy.yml

stages:
  - validate
  - deploy
```

## 📦 Using Backstage

The Backstage integration provides:

1. **Service Discovery** — Register all platform components in the Software Catalogue
2. **Scaffolder Templates** — Generate boilerplate code for new services
3. **TechDocs** — Searchable documentation site
4. **Component Relationships** — Dependency mapping and ownership

Add a service to the catalogue:

```yaml
# catalog-info.yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: my-service
  description: My awesome microservice
spec:
  type: service
  owner: platform-eng
  lifecycle: production
```

## 🛡️ Policies & Compliance

### Enforce Organizational Standards

Deploy Azure Policies and OPA rules to ensure:

```bash
# Apply Azure Policy definitions
cd policies/azure-policy
terraform apply

# Check OPA compliance
opa test opa/ -v
```

### Built-in Policy Examples

- ✅ Enforce mandatory tags (team, cost-centre, owner)
- ✅ Require encryption at rest for storage accounts
- ✅ Enforce private endpoints for Key Vault
- ✅ Restrict allowed VM SKUs
- ✅ Require diagnostic logging for all resources
- ✅ Enforce SQL Server auditing

## 📖 Documentation

### Architecture Decision Records (ADRs)

Located in `docs/adr/`:

| ADR | Decision |
|-----|---------|
| [001-terraform-over-bicep](docs/adr/001-terraform-over-bicep.md) | Terraform chosen for multi-cloud portability and ecosystem maturity |
| [002-backstage-for-portal](docs/adr/002-backstage-for-portal.md) | Backstage chosen over Cortex/Port for open source + plugin model |
| [003-hub-spoke-over-vwan](docs/adr/003-hub-spoke-over-vwan.md) | Hub-and-spoke chosen for deterministic routing and lower cost |

### On-Boarding Guide

New teams should follow `docs/onboarding/getting-started.md` to:

1. Register their service in Backstage
2. Create their first resource using a Terraform module
3. Set up their CI/CD pipeline
4. Configure alerts and monitoring

### Operational Runbooks

Located in `docs/runbooks/`:

- Disaster recovery procedures
- Troubleshooting guides
- Maintenance checklists
- Incident response playbooks

## 🧪 Testing

### Terraform Tests

Run Terratest integration tests:

```bash
cd terraform/tests
go test -v ./...
```

### Policy Tests

Validate Azure Policies:

```bash
cd policies/azure-policy
terraform validate
```

Test OPA rules:

```bash
cd policies/opa
opa test . -v
```

### Linting

Run all linters on pull requests:

```bash
# Format check
terraform fmt -recursive -check terraform/

# Static analysis
tflint --init
tflint terraform/

# Security scan
checkov -d terraform/
```

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for:

- Branch naming conventions
- Pull request process
- Code review expectations
- Terraform coding standards
- Testing requirements

### Quick Contribution Checklist

- [ ] Create an issue before starting work
- [ ] Follow branch naming: `feature/`, `bugfix/`, `docs/`
- [ ] Run `terraform fmt -recursive` and `terraform validate`
- [ ] Update documentation and README
- [ ] Add examples to new modules
- [ ] Run all tests locally
- [ ] Reference the issue in your pull request

## 📋 Platform Contract

The `PLATFORM-CONTRACT.md` file documents:

- Minimum and maximum Terraform module versions
- Supported environment names and locations
- Required tagging schema
- Pipeline template compatibility matrix

Keep this file up-to-date as the platform evolves.

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for release notes, features, and bug fixes.

Current stable release: **v0.1.0**

## 🎓 For Book Readers

This repository is the **hands-on companion** to "Platform Engineering on Azure":

- Each chapter corresponds to modules and patterns in this repository
- Code examples throughout the book reference specific files and directories
- Practical exercises build upon these reusable templates
- Real-world patterns and guardrails are production-tested

**Get the book:** Available at major online retailers. Includes detailed explanations of:

- Platform engineering principles and team structures
- Infrastructure as Code best practices
- Cloud-native architecture patterns
- CI/CD pipeline design
- Policy as Code and compliance
- Cost governance and FinOps
- Team enablement and golden paths

## 🔗 Resources

- [Microsoft Azure Documentation](https://docs.microsoft.com/azure)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [Backstage.io](https://backstage.io)
- [Open Policy Agent](https://www.openpolicyagent.org)
- [Azure DevOps](https://dev.azure.com)
- [GitLab CI/CD](https://docs.gitlab.com/ee/ci/)

## 📄 License

This repository is licensed under the **MIT License**. See [LICENSE](LICENSE) for details.

## 👥 Community & Support

- **GitHub Issues** — Report bugs or request features
- **Pull Requests** — Contribute improvements and bug fixes
- **Discussions** — Ask questions and share ideas
- **Code of Conduct** — See [CONTRIBUTING.md](CONTRIBUTING.md)

## 🙋 About the Author

**Abhishek Bagde** is a senior software engineer and cloud architect specializing in Azure, infrastructure automation, and internal developer platforms. This repository represents best practices learned from implementing platforms at scale in enterprise organizations.

---

**Star ⭐ this repository if you find it useful, and follow for updates!**

Made with ❤️ for the platform engineering community.
