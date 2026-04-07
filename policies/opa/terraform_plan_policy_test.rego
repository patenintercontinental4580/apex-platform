package terraform.plan_test

import future.keywords.if

# ─── Fixtures ────────────────────────────────────────────────────────────────

mock_plan_with_public_ip := {
    "resource_changes": [{
        "address": "azurerm_public_ip.bastion",
        "type":    "azurerm_public_ip",
        "change": {
            "actions": ["create"],
            "after": {
                "allocation_method": "Static",
                "tags": {
                    "ApplicationName": "orders",
                    "Environment":     "production",
                    "Team":            "platform",
                    "CostCentre":      "PLATFORM-001"
                }
            }
        }
    }]
}

mock_plan_missing_tags := {
    "resource_changes": [{
        "address": "azurerm_resource_group.this",
        "type":    "azurerm_resource_group",
        "change": {
            "actions": ["create"],
            "after": {
                "tags": {
                    "ApplicationName": "orders"
                }
            }
        }
    }]
}

mock_plan_owner_at_subscription := {
    "resource_changes": [{
        "address": "azurerm_role_assignment.owner",
        "type":    "azurerm_role_assignment",
        "change": {
            "actions": ["create"],
            "after": {
                "role_definition_name": "Owner",
                "scope": "/subscriptions/00000000-0000-0000-0000-000000000000",
                "tags": {}
            }
        }
    }]
}

mock_plan_compliant := {
    "resource_changes": [{
        "address": "azurerm_resource_group.this",
        "type":    "azurerm_resource_group",
        "change": {
            "actions": ["create"],
            "after": {
                "tags": {
                    "ApplicationName": "orders",
                    "Environment":     "production",
                    "Team":            "platform",
                    "CostCentre":      "PLATFORM-001"
                }
            }
        }
    }]
}

# ─── Tests ───────────────────────────────────────────────────────────────────

test_deny_public_ip if {
    import data.terraform.plan
    msgs := plan.deny with input as mock_plan_with_public_ip
    count([m | m := msgs[_]; contains(m, "Public IP")]) > 0
}

test_deny_missing_tags if {
    import data.terraform.plan
    msgs := plan.deny with input as mock_plan_missing_tags
    count([m | m := msgs[_]; contains(m, "missing required tags")]) > 0
}

test_deny_owner_at_subscription if {
    import data.terraform.plan
    msgs := plan.deny with input as mock_plan_owner_at_subscription
    count([m | m := msgs[_]; contains(m, "Owner role assignment")]) > 0
}

test_compliant_plan_has_no_denies if {
    import data.terraform.plan
    msgs := plan.deny with input as mock_plan_compliant
    count(msgs) == 0
}

test_warn_public_storage if {
    import data.terraform.plan
    plan_with_public_storage := {
        "resource_changes": [{
            "address": "azurerm_storage_account.this",
            "type":    "azurerm_storage_account",
            "change": {
                "actions": ["create"],
                "after": {
                    "public_network_access_enabled": true,
                    "tags": {
                        "ApplicationName": "orders",
                        "Environment":     "production",
                        "Team":            "platform",
                        "CostCentre":      "PLATFORM-001"
                    }
                }
            }
        }]
    }
    msgs := plan.warn with input as plan_with_public_storage
    count([m | m := msgs[_]; contains(m, "public network access")]) > 0
}
