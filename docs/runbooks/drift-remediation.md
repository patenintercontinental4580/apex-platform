# Runbook: Terraform Drift Remediation

**Severity:** Medium–High
**Trigger:** Drift detection pipeline exits with code 2 (changes detected)

## Symptoms

- The `drift-detection` pipeline sends a Teams/Slack alert with "Infrastructure drift detected".
- `terraform plan` output shows resources to be added, changed, or destroyed.

## Triage

1. **Open the pipeline run** in Azure DevOps or GitLab CI and expand the `drift-detection` stage.
2. **Read the plan output.** Determine whether the drift is:
   - **Benign metadata drift** — tags, descriptions, or properties changed by Azure automatically. Usually safe to revert.
   - **Manual change** — someone made a change outside Terraform. Investigate why.
   - **Module update drift** — a new module version changed a property. Review the module changelog.

3. **Check recent activity** in the Azure portal:
   ```bash
   az monitor activity-log list \
     --resource-group <rg-name> \
     --start-time $(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ) \
     --query "[].{time:eventTimestamp, caller:caller, operation:operationName.localizedValue, status:status.value}" \
     -o table
   ```

## Remediation

### Option A: Revert drift (recommended for manual changes)

```bash
cd terraform/environments/<env>
terraform init
terraform plan -out=remediation.tfplan
# Review the plan carefully
terraform apply remediation.tfplan
```

### Option B: Accept the change (update Terraform state)

If the drift represents a valid change that should be preserved:

```bash
terraform import <resource.address> <azure-resource-id>
# or update variables/locals to match the new state
```

### Option C: Escalate

If the drift involves:
- Security group membership changes
- RBAC role assignment additions
- Firewall rule modifications

Escalate to the **Platform Engineering team lead** before remediating.

## Post-Remediation

1. Re-run the drift detection pipeline and confirm exit code 0.
2. Update the Terraform code if the drift was caused by a module gap.
3. File an incident report if the drift was caused by an unauthorised manual change.

## Prevention

- Enable Azure Policy `deny` effects where possible to block out-of-band changes.
- Restrict contributor access on production resource groups to the CI/CD service principal only.
- Review `az activity-log` alerts in Azure Monitor for resource modifications.
