# Runbook: Key Vault Secret Rotation Failure

**Severity:** High
**Trigger:** Event Grid subscription dead-letter queue has messages, or Function App error rate > 0 on the `secret-rotation` function.

## Symptoms

- Azure Monitor alert: "SecretRotationFailed" fires on the `func-secret-rotation-*` Function App.
- Key Vault audit logs show `SecretNearExpiry` events without corresponding `SecretSet` events.
- Application errors caused by expired secrets.

## Triage

1. **Check Function App logs:**
   ```bash
   az monitor app-insights query \
     --app <app-insights-name> \
     --analytics-query "exceptions | where timestamp > ago(1h) | project timestamp, outerMessage, details" \
     --output table
   ```

2. **Check Event Grid dead-letter queue:**
   ```bash
   az storage blob list \
     --account-name <storage-account> \
     --container-name <dead-letter-container> \
     --output table
   ```

3. **Verify the Function App managed identity has the required role:**
   ```bash
   az role assignment list \
     --assignee <function-app-principal-id> \
     --scope /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<kv> \
     --query "[].{role:roleDefinitionName, scope:scope}" \
     -o table
   ```
   The managed identity requires `Key Vault Secrets Officer`.

## Remediation

### Manual rotation (emergency)

```bash
# Generate a new secret value
NEW_SECRET=$(openssl rand -base64 32)

# Set the new version in Key Vault
az keyvault secret set \
  --vault-name <vault-name> \
  --name <secret-name> \
  --value "$NEW_SECRET"

# Update the dependent application configuration
# (varies by service — see service runbook)
```

### Redeploy the rotation function

```bash
cd terraform/modules/azure-secret-rotation
terraform plan -out=rotation.tfplan
terraform apply rotation.tfplan
```

### Replay dead-lettered events

Download dead-letter blobs, inspect the event payload, and re-publish to the Event Grid topic:

```bash
az eventgrid event publish \
  --topic-endpoint <topic-endpoint> \
  --events @dead-letter-event.json
```

## Post-Remediation

1. Confirm the secret has a new version with a future expiry date.
2. Restart affected applications to pick up the new secret version.
3. Confirm the rotation function invocation succeeded in App Insights.
4. Review and resolve the root cause (missing RBAC, network connectivity, Function App crash).
