# Contributing to Apex Platform

Thank you for your interest in contributing to the Apex Platform. This document explains how to propose changes, raise issues, and submit pull requests, as well as the standards that all contributions must meet.

---

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Proposing Changes](#proposing-changes)
3. [Architectural Decisions](#architectural-decisions)
4. [Pull Request Process](#pull-request-process)
5. [Terraform Coding Standards](#terraform-coding-standards)
6. [Testing Requirements](#testing-requirements)
7. [Review SLA](#review-sla)
8. [Community of Practice](#community-of-practice)

---

## Code of Conduct

All contributors are expected to act professionally and respectfully. Harassment, discriminatory language, or personal attacks of any kind will not be tolerated.

---

## Proposing Changes

Before beginning any work, please **open a GitHub Issue** to describe the problem you are solving or the feature you wish to add. This ensures the team can provide early feedback and avoids wasted effort on work that may not be accepted.

When opening an issue, please include:

- **Context** — why is this change needed? What problem does it solve?
- **Proposed solution** — a brief description of your intended approach.
- **Alternatives considered** — any other approaches you evaluated and why you discarded them.
- **Impact** — which modules, pipelines, or consumers will be affected?

The maintainers will triage the issue and either approve it for development, request more information, or close it with an explanation.

---

## Architectural Decisions

Any change that affects platform-wide conventions, module interfaces, naming schemes, pipeline contracts, or security boundaries must be accompanied by an **Architecture Decision Record (ADR)**. ADRs live in `docs/adr/` and follow the [MADR](https://adr.github.io/madr/) template provided in `docs/adr/0000-template.md`.

To propose an architectural change:

1. Open a GitHub Issue tagged `adr` with a summary of the decision.
2. Discuss the proposal in the issue thread until the team reaches rough consensus.
3. Submit a pull request containing:
   - The new ADR file (`docs/adr/NNNN-short-title.md`).
   - Any corresponding code changes.

An ADR must be approved by at least two members of `@apex-platform/platform-team` before the associated code changes may be merged.

---

## Pull Request Process

### Branch Naming

All branches must use one of the following prefixes, followed by a short kebab-case description:

| Prefix   | Use case                                      |
|----------|-----------------------------------------------|
| `feat/`  | New features or new module additions          |
| `fix/`   | Bug fixes and corrections                     |
| `docs/`  | Documentation-only changes                    |
| `chore/` | Maintenance tasks (dependency bumps, CI tweaks, refactors without behaviour change) |

Examples:

```
feat/azure-redis-cache-module
fix/container-app-ingress-port-validation
docs/update-naming-convention-guide
chore/bump-terraform-azurerm-provider-3-90
```

### Creating a Pull Request

1. Ensure your branch is up to date with `main` before opening a PR.
2. Fill in all sections of the pull request template (`.github/PULL_REQUEST_TEMPLATE.md`).
3. **Link the PR to the issue** it resolves using a closing keyword in the PR description (e.g. `Closes #42`).
4. Ensure all status checks pass before requesting a review.
5. Assign the PR to yourself and request a review from the relevant CODEOWNER team.
6. Do not merge your own PR; a second approver from the owning team is required.

### Merge Strategy

All PRs are merged via **Squash and Merge**. Ensure your PR title follows the [Conventional Commits](https://www.conventionalcommits.org/) format, as it becomes the squash commit message:

```
feat(azure-container-app): add support for HTTP/2 ingress
fix(azure-key-vault): correct soft-delete retention days validation
docs: add on-boarding guide for new consumers
```

---

## Terraform Coding Standards

All Terraform code contributed to this repository must meet the following standards.

### Formatting

Run `terraform fmt -recursive` before every commit. The CI pipeline enforces this with `terraform fmt -check -recursive` and will fail if any file is not correctly formatted.

### Naming Convention

All Azure resource names must follow the platform naming convention:

```
{prefix}-{app}-{env}-{region}-{instance}
```

| Segment    | Description                                                    | Example      |
|------------|----------------------------------------------------------------|--------------|
| `prefix`   | Resource type abbreviation (e.g. `ca`, `kv`, `sql`, `vnet`)  | `ca`         |
| `app`      | Application or workload identifier (max 8 characters)         | `orders`     |
| `env`      | Environment (`dev`, `tst`, `uat`, `prd`)                       | `prd`        |
| `region`   | Azure region abbreviation (`uks`, `ukw`, `neu`, `weu`)        | `uks`        |
| `instance` | Zero-padded two-digit instance number                          | `01`         |

Full example: `ca-orders-prd-uks-01`

Module `locals` blocks must construct the resource name using this pattern so that consumers cannot accidentally supply a non-compliant name.

### Variable Declarations

- Every input variable **must** have a `description` attribute written in full sentences.
- Every input variable **must** have a `type` constraint.
- Every input variable **must** include a `validation` block that guards against invalid values. For string variables this should at minimum check that the value is non-empty. For enumerated values, use a `contains()` check.
- Variables that contain credentials, connection strings, keys, or other confidential data **must** be marked `sensitive = true`.

Example:

```hcl
variable "environment" {
  type        = string
  description = "Deployment environment. Permitted values are dev, tst, uat, and prd."

  validation {
    condition     = contains(["dev", "tst", "uat", "prd"], var.environment)
    error_message = "environment must be one of: dev, tst, uat, prd."
  }
}

variable "sql_admin_password" {
  type        = string
  sensitive   = true
  description = "Password for the SQL Server administrator login. Must be at least 16 characters and meet Azure complexity requirements."

  validation {
    condition     = length(var.sql_admin_password) >= 16
    error_message = "sql_admin_password must be at least 16 characters long."
  }
}
```

### Production Guardrails

Use `lifecycle` `precondition` blocks to enforce runtime guardrails, particularly for production environments. These checks run during `terraform plan` and provide clear error messages before any infrastructure is modified.

Example:

```hcl
resource "azurerm_key_vault" "this" {
  # ...

  lifecycle {
    precondition {
      condition     = var.environment != "prd" || var.purge_protection_enabled == true
      error_message = "purge_protection_enabled must be true in the prd environment."
    }

    precondition {
      condition     = var.environment != "prd" || var.soft_delete_retention_days >= 90
      error_message = "soft_delete_retention_days must be at least 90 in the prd environment."
    }
  }
}
```

### Secrets Management

Hardcoded secrets are strictly prohibited. All secrets must be sourced from one of the following:

- **Managed Identity** — preferred for Azure-to-Azure authentication.
- **Azure Key Vault** — for application secrets and certificates retrieved at runtime via Key Vault references or the `azurerm_key_vault_secret` data source.
- **Workload Identity Federation (WIF)** — for CI/CD pipelines authenticating to Azure without storing service principal credentials.

Any PR that introduces a hardcoded secret will be rejected immediately.

### Module Structure

Each module must follow this directory layout:

```
terraform/modules/{module-name}/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── README.md
└── examples/
    ├── basic/
    │   ├── main.tf
    │   └── variables.tf
    └── complete/
        ├── main.tf
        └── variables.tf
```

---

## Testing Requirements

### Examples

Every new or modified module must include or update the following example configurations:

- **`examples/basic/`** — the minimal configuration required to deploy the module with sensible defaults. This example must be deployable without any additional configuration beyond what is shown.
- **`examples/complete/`** — a configuration that exercises every significant optional feature of the module, demonstrating real-world usage patterns.

Both examples are validated by the CI pipeline (`terraform init -backend=false && terraform validate`).

### Variable Validation Tests

If you add new `validation` blocks to variables, add a corresponding test case in `tests/` (Terraform native testing framework, `*.tftest.hcl`) that exercises both the passing and failing conditions of each validation rule.

### Manual Testing

Before opening a PR, you should have successfully run `terraform plan` against the `dev` environment using the `examples/complete/` configuration to confirm the module produces a sensible plan.

---

## Review SLA

The platform team commits to providing an **initial response within 48 hours on business days** for all pull requests and issues. This response may be an approval, a request for changes, or a comment explaining that the review is in progress.

PRs that have been idle (no response to review comments) for more than **14 calendar days** may be closed. They can be reopened at any time by adding a comment.

---

## Community of Practice

The Apex Platform runs two recurring community touchpoints:

- **Monthly Platform Community of Practice Call** — held on the last Wednesday of each month. The agenda covers upcoming breaking changes, new module announcements, and open Q&A. Calendar invite and dial-in details are published in the `#apex-platform` Slack channel at least one week in advance.
- **Weekly Changelog Review** — every Monday, the `#apex-platform-changelog` Slack channel receives an automated summary of all merged PRs from the previous week. Team members are encouraged to comment with questions or feedback.

If you would like to present at the monthly call or suggest an agenda item, please post in `#apex-platform` at least five business days before the meeting.
