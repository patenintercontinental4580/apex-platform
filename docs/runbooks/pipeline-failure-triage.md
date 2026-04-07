# Runbook: CI/CD Pipeline Failure Triage

**Severity:** Medium
**Trigger:** Pipeline run fails in Azure DevOps or GitLab CI.

## Common Failure Modes

### 1. Terraform `init` failure

**Symptoms:** `Error: Failed to install provider` or `Error: Backend initialisation required`.

**Resolution:**
```bash
# Clear cached providers and reinitialise
rm -rf .terraform .terraform.lock.hcl
terraform init -reconfigure -upgrade
```

Check that the Terraform state storage account `stapexplatformtfstate` is accessible and that the pipeline service principal has `Storage Blob Data Contributor` on it.

### 2. Terraform `validate` failure

**Symptoms:** `Error: Invalid reference` or `Error: Unsupported argument`.

**Resolution:** Run `terraform validate` locally. Fix the HCL syntax error. Common causes: renamed variable, incorrect module output reference, provider version mismatch.

### 3. Checkov policy failure

**Symptoms:** `FAILED for resource: <address>` in the checkov stage.

**Resolution:**
```bash
checkov -d terraform/modules/<module> --framework terraform --compact
```

Either fix the resource configuration or add a `#checkov:skip=CKV_AZURE_XXX:reason` comment if the check is a false positive (requires team lead approval).

### 4. Docker build failure

**Symptoms:** `Error response from daemon` or `failed to solve`.

**Resolution:**
- Check the Dockerfile syntax: `docker build --no-cache .`
- Verify base image availability (Docker Hub rate limits apply; use ACR mirror in production).
- Check firewall rules allow outbound access to `registry-1.docker.io` (development-tools rule collection).

### 5. Integration test failure

**Symptoms:** `dotnet test` exits with code 1 in the `DeployStaging` stage.

**Resolution:**
1. Check the test output in the pipeline artefacts (`TestResults/*.trx`).
2. Run the failing tests locally against the staging endpoint:
   ```bash
   dotnet test --filter "FullyQualifiedName~IntegrationTests" \
     -- TestRunParameters.Parameter\(name=\"BaseUrl\",value=\"https://...\"\)
   ```
3. If the failure is environmental (database not seeded, external service down), re-run the pipeline.
4. If the failure is a genuine regression, revert the commit and investigate.

### 6. Canary deployment stuck

**Symptoms:** Pipeline is waiting at the 10% → 50% canary step indefinitely.

**Resolution:**
- Check Container App revision traffic weights in the Azure portal.
- Check Application Insights for error rate on the new revision.
- If error rate > 1%, roll back:
  ```bash
  az containerapp revision deactivate \
    --name <app-name> \
    --resource-group <rg> \
    --revision <new-revision-name>
  ```

## Escalation

| Condition | Escalate To |
|---|---|
| Production deployment blocked > 2 hours | Platform Engineering on-call |
| Security scan failures in prod pipeline | Security team |
| Unrecoverable state corruption | Platform Engineering lead + Azure support |
