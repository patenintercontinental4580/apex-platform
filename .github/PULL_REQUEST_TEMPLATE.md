## Description

<!-- Explain *what* this PR changes and *why* the change is needed.
     Include relevant context, links to design documents or ADRs, and
     any trade-offs or limitations of the chosen approach.
     Link to the issue this PR resolves using a closing keyword, e.g.:
     Closes #123 -->



## Type of Change

<!-- Tick all that apply. -->

- [ ] Bug fix (non-breaking change that resolves an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing consumers to behave differently)
- [ ] Documentation update only

## Checklist

<!-- All items must be ticked before requesting a review.
     If an item is genuinely not applicable, replace [ ] with [N/A] and add a brief note. -->

- [ ] **Tests added or updated** — `examples/basic/` and `examples/complete/` have been added or updated for any new or modified module, and both pass `terraform validate`.
- [ ] **Documentation updated** — `README.md` in the affected module directory reflects all new and changed inputs, outputs, and usage examples.
- [ ] **Naming conventions followed** — all Azure resource names are constructed using the `{prefix}-{app}-{env}-{region}-{instance}` pattern via a `locals` block in the module.
- [ ] **Validation blocks added** — every new or modified input variable includes a `validation` block with a meaningful `error_message`.
- [ ] **Sensitive variables marked** — all variables that carry credentials, keys, or connection strings have `sensitive = true`.
- [ ] **No hardcoded secrets** — authentication uses Managed Identity, Azure Key Vault references, or Workload Identity Federation. No plaintext secrets appear in any `.tf` file or example.
- [ ] **`terraform fmt` passes** — `terraform fmt -check -recursive` produces no output against the changed files.
- [ ] **`terraform validate` passes** — `terraform init -backend=false && terraform validate` succeeds for the module and both examples.
- [ ] **Production guardrails implemented** — `lifecycle` `precondition` blocks are in place for any constraint that must be enforced in `prd` (e.g. purge protection, geo-redundant backup, private endpoint requirement).
- [ ] **British English used** — all comments, descriptions, variable `description` attributes, and documentation are written in British English.
