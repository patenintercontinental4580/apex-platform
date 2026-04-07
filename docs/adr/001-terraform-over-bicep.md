# ADR-001: Terraform over Bicep for Infrastructure as Code

**Status:** Accepted
**Date:** 2025-01-15
**Author:** Abhishek Bagde

## Context

The Apex Platform requires a consistent, auditable, and repeatable way to define and deploy Azure infrastructure. The two primary candidates are HashiCorp Terraform and Microsoft Bicep.

## Decision

We will use **Terraform** (with the `azurerm` provider) as the Infrastructure as Code (IaC) toolchain for the Apex Platform.

## Consequences

### Positive
- **Multi-cloud portability.** Although the platform targets Azure today, Terraform modules can be extended to AWS or GCP without retooling the entire IaC estate. Bicep is Azure-only.
- **Rich ecosystem.** Terraform Registry hosts thousands of community modules. Tooling (tflint, checkov, Terratest, Infracost) is mature and widely adopted.
- **Declarative state management.** The Terraform state file and `plan`/`apply` workflow provide explicit drift detection that is trivial to integrate into pipelines.
- **Consistent developer experience.** Most platform engineers already know Terraform; Bicep would require retraining.

### Negative
- **State management overhead.** Terraform requires a remote state backend (Azure Blob Storage), which Bicep does not. We mitigate this with the `stapexplatformtfstate` storage account and a bootstrap script.
- **Provider lag.** New Azure resources occasionally appear in Bicep before the `azurerm` provider. We accept minor delays to new-resource adoption.

## Alternatives Considered

| Alternative | Reason Rejected |
|---|---|
| Bicep | Azure-only; limited ecosystem; no mature test framework |
| Pulumi | Smaller community; licensing considerations for enterprise use |
| ARM Templates | Verbose JSON; no native plan/preview workflow |

## References

- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Bicep vs Terraform comparison — Microsoft Docs](https://learn.microsoft.com/en-us/azure/developer/terraform/comparing-terraform-and-bicep)
