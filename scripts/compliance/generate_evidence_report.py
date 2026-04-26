#!/usr/bin/env python3
"""
generate_evidence_report.py — Generate a compliance evidence report from Azure Policy.

Usage:
    python3 scripts/compliance/generate_evidence_report.py \
        --subscription-id <id> \
        --output report.json
"""
import argparse
import json
import sys
from datetime import datetime, timezone

from azure.identity import DefaultAzureCredential
from azure.mgmt.policyinsights import PolicyInsightsClient
from azure.mgmt.policyinsights.models import QueryOptions


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate Azure Policy compliance evidence report")
    parser.add_argument("--subscription-id", required=True, help="Azure subscription ID")
    parser.add_argument("--output", default="compliance-report.json", help="Output file path")
    parser.add_argument(
        "--policy-set",
        default=None,
        help="Filter by policy set definition name (optional)",
    )
    return parser.parse_args()


def get_policy_states(client: PolicyInsightsClient, subscription_id: str, policy_set: str | None) -> list[dict]:
    query_options = QueryOptions(top=1000)
    states = client.policy_states.list_query_results_for_subscription(
        policy_states_resource="latest",
        subscription_id=subscription_id,
        query_options=query_options,
    )

    results = []
    for state in states:
        record = {
            "resourceId": state.resource_id,
            "resourceType": state.resource_type,
            "resourceLocation": state.resource_location,
            "policyDefinitionId": state.policy_definition_id,
            "policyAssignmentId": state.policy_assignment_id,
            "complianceState": state.compliance_state,
            "timestamp": state.timestamp.isoformat() if state.timestamp else None,
            "policyDefinitionName": state.policy_definition_name,
            "policyAssignmentName": state.policy_assignment_name,
        }
        if policy_set and state.policy_set_definition_id:
            if policy_set.lower() not in (state.policy_set_definition_id or "").lower():
                continue
        results.append(record)
    return results


def build_summary(states: list[dict]) -> dict:
    total = len(states)
    compliant = sum(1 for s in states if s["complianceState"] == "Compliant")
    non_compliant = sum(1 for s in states if s["complianceState"] == "NonCompliant")

    by_type: dict[str, dict[str, int]] = {}
    for state in states:
        rtype = state["resourceType"] or "Unknown"
        if rtype not in by_type:
            by_type[rtype] = {"Compliant": 0, "NonCompliant": 0, "Unknown": 0}
        cs = state["complianceState"] or "Unknown"
        by_type[rtype][cs] = by_type[rtype].get(cs, 0) + 1

    return {
        "total": total,
        "compliant": compliant,
        "nonCompliant": non_compliant,
        "compliancePercentage": round((compliant / total * 100), 2) if total else 0,
        "byResourceType": by_type,
    }


def main() -> None:
    args = parse_args()

    credential = DefaultAzureCredential()
    client = PolicyInsightsClient(credential, args.subscription_id)

    print(f"Querying policy compliance for subscription {args.subscription_id}...", file=sys.stderr)
    states = get_policy_states(client, args.subscription_id, args.policy_set)

    report = {
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "subscriptionId": args.subscription_id,
        "summary": build_summary(states),
        "states": states,
    }

    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)

    summary = report["summary"]
    print(f"Report written to {args.output}", file=sys.stderr)
    print(
        f"Compliance: {summary['compliant']}/{summary['total']} "
        f"({summary['compliancePercentage']}%)",
        file=sys.stderr,
    )

    if summary["nonCompliant"] > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
