data "azurerm_client_config" "current" {}

# Provider configuration
provider "azurerm" {
  features {}
}

provider "azuread" {}

# Management Group Hierarchy
resource "azurerm_management_group" "apex_platform" {
  display_name               = "Apex Platform"
  parent_management_group_id = var.root_management_group_id
}

resource "azurerm_management_group" "platform" {
  display_name               = "Platform"
  parent_management_group_id = azurerm_management_group.apex_platform.id
}

resource "azurerm_management_group" "identity" {
  display_name               = "Identity"
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "management" {
  display_name               = "Management"
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "connectivity" {
  display_name               = "Connectivity"
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "landing_zones" {
  display_name               = "Landing Zones"
  parent_management_group_id = azurerm_management_group.apex_platform.id
}

resource "azurerm_management_group" "production" {
  display_name               = "Production"
  parent_management_group_id = azurerm_management_group.landing_zones.id
}

resource "azurerm_management_group" "non_production" {
  display_name               = "Non-Production"
  parent_management_group_id = azurerm_management_group.landing_zones.id
}

resource "azurerm_management_group" "sandbox" {
  display_name               = "Sandbox"
  parent_management_group_id = azurerm_management_group.apex_platform.id
}

# Security Groups via Azure AD
resource "azuread_group" "platform_admins" {
  display_name     = "sg-apex-platform-admins"
  security_enabled = true
  description      = "Platform administrators with full access to the Apex Platform management group."
}

resource "azuread_group" "platform_engineers" {
  display_name     = "sg-apex-platform-engineers"
  security_enabled = true
  description      = "Platform engineers with contributor access to deploy and manage platform resources."
}

resource "azuread_group" "platform_readers" {
  display_name     = "sg-apex-platform-readers"
  security_enabled = true
  description      = "Read-only access to all Apex Platform resources."
}

resource "azuread_group" "security_auditors" {
  display_name     = "sg-apex-security-auditors"
  security_enabled = true
  description      = "Security team with read access to audit all platform resources and policy compliance."
}

resource "azuread_group" "finops_readers" {
  display_name     = "sg-apex-finops-readers"
  security_enabled = true
  description      = "FinOps team with read access to cost management and billing resources."
}

# RBAC Assignments
resource "azurerm_role_assignment" "platform_admins_owner" {
  scope                = azurerm_management_group.apex_platform.id
  role_definition_name = "Management Group Contributor"
  principal_id         = azuread_group.platform_admins.object_id
}

resource "azurerm_role_assignment" "platform_engineers_contributor" {
  scope                = azurerm_management_group.landing_zones.id
  role_definition_name = "Contributor"
  principal_id         = azuread_group.platform_engineers.object_id
}

resource "azurerm_role_assignment" "platform_readers_reader" {
  scope                = azurerm_management_group.apex_platform.id
  role_definition_name = "Reader"
  principal_id         = azuread_group.platform_readers.object_id
}

resource "azurerm_role_assignment" "security_auditors_reader" {
  scope                = azurerm_management_group.apex_platform.id
  role_definition_name = "Reader"
  principal_id         = azuread_group.security_auditors.object_id
}

resource "azurerm_role_assignment" "security_auditors_policy_reader" {
  scope                = azurerm_management_group.apex_platform.id
  role_definition_name = "Resource Policy Contributor"
  principal_id         = azuread_group.security_auditors.object_id
}

resource "azurerm_role_assignment" "finops_cost_management" {
  scope                = azurerm_management_group.apex_platform.id
  role_definition_name = "Cost Management Reader"
  principal_id         = azuread_group.finops_readers.object_id
}

# Custom Policy Definitions
resource "azurerm_policy_definition" "require_mandatory_tags" {
  name         = "require-mandatory-tags"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require mandatory resource tags"
  description  = "Denies resources missing the CostCentre, Team, or Environment tags."
  management_group_id = azurerm_management_group.apex_platform.id

  metadata = jsonencode({
    version  = "1.0.0"
    category = "Tags"
  })

  parameters = jsonencode({
    effect = {
      type          = "String"
      metadata      = { displayName = "Effect" }
      allowedValues = ["Deny", "Audit", "Disabled"]
      defaultValue  = "Deny"
    }
  })

  policy_rule = jsonencode({
    if = {
      anyOf = [
        { field = "tags['CostCentre']", exists = "false" },
        { field = "tags['CostCentre']", equals = "" },
        { field = "tags['Team']", exists = "false" },
        { field = "tags['Team']", equals = "" },
        { field = "tags['Environment']", exists = "false" },
        { field = "tags['Environment']", notIn = ["dev", "staging", "prod"] }
      ]
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })
}

resource "azurerm_policy_definition" "deny_public_storage" {
  name         = "deny-public-storage"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Deny storage accounts with public network access"
  description  = "Denies the creation of storage accounts that have public network access enabled."
  management_group_id = azurerm_management_group.apex_platform.id

  metadata = jsonencode({
    version  = "1.0.0"
    category = "Storage"
  })

  parameters = jsonencode({
    effect = {
      type          = "String"
      metadata      = { displayName = "Effect" }
      allowedValues = ["Deny", "Audit", "Disabled"]
      defaultValue  = "Deny"
    }
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "Microsoft.Storage/storageAccounts" },
        { field = "Microsoft.Storage/storageAccounts/publicNetworkAccess", equals = "Enabled" }
      ]
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })
}

# Policy Assignments at Management Group Level
resource "azurerm_management_group_policy_assignment" "require_tags" {
  name                 = "require-tags"
  display_name         = "Require mandatory tags on all resources"
  policy_definition_id = azurerm_policy_definition.require_mandatory_tags.id
  management_group_id  = azurerm_management_group.apex_platform.id

  parameters = jsonencode({
    effect = { value = "Deny" }
  })
}

resource "azurerm_management_group_policy_assignment" "deny_public_ip" {
  name                 = "deny-public-ip"
  display_name         = "Deny creation of public IP addresses"
  # Built-in policy: Not allowed resource types (used to deny azurerm_public_ip)
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/9daedab3-fb2d-461e-b861-71790eead4f6"
  management_group_id  = azurerm_management_group.landing_zones.id

  parameters = jsonencode({
    listOfResourceTypesNotAllowed = {
      value = ["microsoft.network/publicipaddresses", "microsoft.network/publicipprefixes"]
    }
  })
}

resource "azurerm_management_group_policy_assignment" "deny_public_storage" {
  name                 = "deny-public-storage"
  display_name         = "Deny storage accounts with public access"
  policy_definition_id = azurerm_policy_definition.deny_public_storage.id
  management_group_id  = azurerm_management_group.landing_zones.id

  parameters = jsonencode({
    effect = { value = "Deny" }
  })
}

resource "azurerm_management_group_policy_assignment" "allowed_regions" {
  name                 = "allowed-regions"
  display_name         = "Restrict resources to allowed Azure regions"
  # Built-in: Allowed locations - policy definition ID
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  management_group_id  = azurerm_management_group.apex_platform.id

  parameters = jsonencode({
    listOfAllowedLocations = {
      value = var.allowed_regions
    }
  })
}
