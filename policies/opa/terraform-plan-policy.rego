package terraform.plan

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# Deny public IP addresses on virtual machines
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "azurerm_public_ip"
    resource.change.after.allocation_method != null
    msg := sprintf(
        "Public IP '%s' is not permitted. Use private IPs and route through the hub firewall.",
        [resource.address]
    )
}

# Deny resources missing mandatory tags
required_tags := {"ApplicationName", "Environment", "Team", "CostCentre"}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.change.actions[_] in ["create", "update"]
    resource.change.after != null
    tags := object.get(resource.change.after, "tags", {})
    missing := required_tags - {tag | tags[tag]}
    count(missing) > 0
    msg := sprintf(
        "Resource '%s' is missing required tags: %v",
        [resource.address, missing]
    )
}

# Deny Owner role assignment at subscription scope
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "azurerm_role_assignment"
    resource.change.after.role_definition_name == "Owner"
    startswith(resource.change.after.scope, "/subscriptions/")
    not contains(resource.change.after.scope, "/resourceGroups/")
    msg := sprintf(
        "Owner role assignment at subscription scope is not permitted for '%s'. Use a more specific scope or a less privileged role.",
        [resource.address]
    )
}

# Warn on storage accounts without private endpoints
warn contains msg if {
    resource := input.resource_changes[_]
    resource.type == "azurerm_storage_account"
    resource.change.after.public_network_access_enabled == true
    msg := sprintf(
        "Storage account '%s' has public network access enabled. Consider using private endpoints.",
        [resource.address]
    )
}
