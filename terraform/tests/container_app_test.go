package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestContainerAppNamingConvention verifies the container app is created
// with the correct naming convention: ca-{app}-{env}-{region}-{instance}
func TestContainerAppNamingConvention(t *testing.T) {
	t.Parallel()

	subscriptionID := azure.GetTargetAzureSubscription(t)

	terraformOptions := &terraform.Options{
		TerraformDir: "../modules/azure-container-app/examples/basic",
		Vars: map[string]interface{}{
			"application_name":           "testapp",
			"environment":                "dev",
			"team":                       "platform-team",
			"cost_centre":                "CC-TEST",
			"container_image":            "nginx:1.25",
			"log_analytics_workspace_id": fmt.Sprintf("/subscriptions/%s/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/log-test", subscriptionID),
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	containerAppName := terraform.Output(t, terraformOptions, "container_app_name")
	assert.Equal(t, "ca-testapp-dev-uks-01", containerAppName,
		"Container App name must follow the naming convention ca-{app}-{env}-{region}-{instance}")
}

// TestContainerAppManagedIdentityAssigned verifies a user-assigned managed identity
// is created and associated with the container app.
func TestContainerAppManagedIdentityAssigned(t *testing.T) {
	t.Parallel()

	subscriptionID := azure.GetTargetAzureSubscription(t)

	terraformOptions := &terraform.Options{
		TerraformDir: "../modules/azure-container-app/examples/basic",
		Vars: map[string]interface{}{
			"application_name":           "identitytest",
			"environment":                "dev",
			"team":                       "platform-team",
			"cost_centre":                "CC-TEST",
			"container_image":            "nginx:1.25",
			"log_analytics_workspace_id": fmt.Sprintf("/subscriptions/%s/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/log-test", subscriptionID),
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	managedIdentityID := terraform.Output(t, terraformOptions, "managed_identity_id")
	require.NotEmpty(t, managedIdentityID, "Managed identity ID must not be empty")

	managedIdentityClientID := terraform.Output(t, terraformOptions, "managed_identity_client_id")
	require.NotEmpty(t, managedIdentityClientID, "Managed identity client ID must not be empty")
}

// TestContainerAppProdGuardrailMinReplicas verifies that applying with
// environment=prod and min_replicas=1 fails with the expected error.
func TestContainerAppProdGuardrailMinReplicas(t *testing.T) {
	t.Parallel()

	subscriptionID := azure.GetTargetAzureSubscription(t)

	terraformOptions := &terraform.Options{
		TerraformDir: "../modules/azure-container-app/examples/basic",
		Vars: map[string]interface{}{
			"application_name":           "guardrailtest",
			"environment":                "prod",
			"min_replicas":               1,
			"team":                       "platform-team",
			"cost_centre":                "CC-TEST",
			"container_image":            "nginx:1.25",
			"log_analytics_workspace_id": fmt.Sprintf("/subscriptions/%s/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/log-test", subscriptionID),
		},
		NoColor: true,
	}

	_, err := terraform.InitAndApplyE(t, terraformOptions)
	require.Error(t, err, "Apply should fail when environment=prod and min_replicas < 2")
	assert.Contains(t, err.Error(), "min_replicas",
		"Error message should mention min_replicas")
}
