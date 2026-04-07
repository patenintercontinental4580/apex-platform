#!/usr/bin/env python3
"""
audit-rbac-assignments.py — Audit Azure RBAC assignments and flag direct User assignments.

Usage:
    python3 scripts/compliance/audit-rbac-assignments.py \
        --subscription-id <id> \
        [--output report.json]
"""
import argparse
import json
import sys
from datetime import datetime, timezone

from azure.identity import DefaultAzureCredential
from azure.mgmt.authorization import AuthorizationManagementClient


PRIVILEGED_ROLES = {
    "8e3af657-a8ff-443c-a75c-2fe8c4bcb635": "Owner",
    "b24988ac-6180-42a0-ab88-20f7382dd24c": "Contributor",
    "18d7d88d-d35e-4fb5-a5c3-7773c20a72d9": "User Access Administrator",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Audit Azure RBAC role assignments")
    parser.add_argument("--subscription-id", required=True, help="Azure subscription ID")
    parser.add_argument("--output", default=None, help="Optional JSON output file path")
    return parser.parse_args()


def get_role_assignments(client: AuthorizationManagementClient, subscription_id: str) -> list[dict]:
    scope = f"/subscriptions/{subscription_id}"
    assignments = client.role_assignments.list_for_scope(scope, filter="atScope()")
    return list(assignments)


def flag_issues(assignments: list) -> list[dict]:
    issues = []
    for assignment in assignments:
        issue = None
        role_id = assignment.role_definition_id.split("/")[-1]
        role_name = PRIVILEGED_ROLES.get(role_id, "")

        # Flag direct User principal assignments
        if assignment.principal_type == "User":
            severity = "HIGH" if role_name in ("Owner", "User Access Administrator") else "MEDIUM"
            issue = {
                "severity": severity,
                "type": "DirectUserAssignment",
                "message": f"Direct User assignment for role '{role_name or role_id}'. "
                           f"Use group-based assignments instead.",
                "principalId": assignment.principal_id,
                "principalType": assignment.principal_type,
                "roleDefinitionId": assignment.role_definition_id,
                "roleName": role_name or role_id,
                "scope": assignment.scope,
                "assignmentId": assignment.id,
            }

        if issue:
            issues.append(issue)

    return issues


def main() -> None:
    args = parse_args()

    credential = DefaultAzureCredential()
    client = AuthorizationManagementClient(credential, args.subscription_id)

    print(f"Auditing RBAC assignments for subscription {args.subscription_id}...", file=sys.stderr)
    assignments = get_role_assignments(client, args.subscription_id)
    issues = flag_issues(assignments)

    report = {
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "subscriptionId": args.subscription_id,
        "totalAssignments": len(assignments),
        "issuesFound": len(issues),
        "issues": issues,
    }

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2)
        print(f"Report written to {args.output}", file=sys.stderr)

    print(f"Total assignments: {len(assignments)}", file=sys.stderr)
    print(f"Issues found: {len(issues)}", file=sys.stderr)

    for issue in issues:
        print(f"  [{issue['severity']}] {issue['message']}", file=sys.stderr)

    if issues:
        sys.exit(1)


if __name__ == "__main__":
    main()
