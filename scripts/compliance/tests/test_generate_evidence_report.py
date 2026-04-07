"""Tests for generate-evidence-report.py"""
import json
from datetime import datetime, timezone
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

import pytest
import sys

# Make the compliance scripts importable
sys.path.insert(0, str(Path(__file__).parent.parent))

import generate_evidence_report as ger


# ─── Fixtures ────────────────────────────────────────────────────────────────

def make_state(resource_id, resource_type, compliance_state, policy_name="test-policy"):
    return SimpleNamespace(
        resource_id=resource_id,
        resource_type=resource_type,
        resource_location="uksouth",
        policy_definition_id=f"/providers/Microsoft.Authorization/policyDefinitions/{policy_name}",
        policy_assignment_id="/subscriptions/sub-id/providers/Microsoft.Authorization/policyAssignments/test",
        compliance_state=compliance_state,
        timestamp=datetime(2026, 1, 1, tzinfo=timezone.utc),
        policy_definition_name=policy_name,
        policy_assignment_name="test-assignment",
        policy_set_definition_id=None,
    )


# ─── build_summary ────────────────────────────────────────────────────────────

def test_build_summary_all_compliant():
    states = [
        {"resourceType": "Microsoft.Storage/storageAccounts", "complianceState": "Compliant"},
        {"resourceType": "Microsoft.Storage/storageAccounts", "complianceState": "Compliant"},
    ]
    summary = ger.build_summary(states)
    assert summary["total"] == 2
    assert summary["compliant"] == 2
    assert summary["nonCompliant"] == 0
    assert summary["compliancePercentage"] == 100.0


def test_build_summary_mixed():
    states = [
        {"resourceType": "Microsoft.KeyVault/vaults", "complianceState": "Compliant"},
        {"resourceType": "Microsoft.KeyVault/vaults", "complianceState": "NonCompliant"},
        {"resourceType": "Microsoft.Storage/storageAccounts", "complianceState": "NonCompliant"},
    ]
    summary = ger.build_summary(states)
    assert summary["total"] == 3
    assert summary["compliant"] == 1
    assert summary["nonCompliant"] == 2
    assert summary["compliancePercentage"] == 33.33


def test_build_summary_empty():
    summary = ger.build_summary([])
    assert summary["total"] == 0
    assert summary["compliancePercentage"] == 0


def test_build_summary_groups_by_resource_type():
    states = [
        {"resourceType": "Microsoft.KeyVault/vaults", "complianceState": "Compliant"},
        {"resourceType": "Microsoft.KeyVault/vaults", "complianceState": "NonCompliant"},
        {"resourceType": "Microsoft.Storage/storageAccounts", "complianceState": "Compliant"},
    ]
    summary = ger.build_summary(states)
    assert summary["byResourceType"]["Microsoft.KeyVault/vaults"]["Compliant"] == 1
    assert summary["byResourceType"]["Microsoft.KeyVault/vaults"]["NonCompliant"] == 1
    assert summary["byResourceType"]["Microsoft.Storage/storageAccounts"]["Compliant"] == 1


# ─── get_policy_states ────────────────────────────────────────────────────────

def test_get_policy_states_returns_all_when_no_filter():
    mock_client = MagicMock()
    mock_client.policy_states.list_query_results_for_subscription.return_value = [
        make_state("/sub/rg/kv1", "Microsoft.KeyVault/vaults", "Compliant"),
        make_state("/sub/rg/st1", "Microsoft.Storage/storageAccounts", "NonCompliant"),
    ]
    results = ger.get_policy_states(mock_client, "sub-id", None)
    assert len(results) == 2


def test_get_policy_states_filters_by_policy_set():
    mock_client = MagicMock()
    state_a = make_state("/sub/rg/kv1", "Microsoft.KeyVault/vaults", "Compliant")
    state_b = make_state("/sub/rg/st1", "Microsoft.Storage/storageAccounts", "NonCompliant")
    state_a.policy_set_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/apex-baseline"
    state_b.policy_set_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/other-policy-set"
    mock_client.policy_states.list_query_results_for_subscription.return_value = [state_a, state_b]

    results = ger.get_policy_states(mock_client, "sub-id", "apex-baseline")
    assert len(results) == 1
    assert results[0]["resourceType"] == "Microsoft.KeyVault/vaults"


# ─── main exit codes ─────────────────────────────────────────────────────────

def test_main_exits_1_when_non_compliant(tmp_path):
    output_file = tmp_path / "report.json"
    mock_states = [
        make_state("/sub/rg/kv1", "Microsoft.KeyVault/vaults", "NonCompliant"),
    ]

    with patch("generate_evidence_report.DefaultAzureCredential"), \
         patch("generate_evidence_report.PolicyInsightsClient") as mock_client_cls:
        mock_client = MagicMock()
        mock_client.policy_states.list_query_results_for_subscription.return_value = mock_states
        mock_client_cls.return_value = mock_client

        with pytest.raises(SystemExit) as exc_info:
            sys.argv = ["script", "--subscription-id", "sub-id", "--output", str(output_file)]
            ger.main()

    assert exc_info.value.code == 1


def test_main_exits_0_when_all_compliant(tmp_path):
    output_file = tmp_path / "report.json"
    mock_states = [
        make_state("/sub/rg/kv1", "Microsoft.KeyVault/vaults", "Compliant"),
    ]

    with patch("generate_evidence_report.DefaultAzureCredential"), \
         patch("generate_evidence_report.PolicyInsightsClient") as mock_client_cls:
        mock_client = MagicMock()
        mock_client.policy_states.list_query_results_for_subscription.return_value = mock_states
        mock_client_cls.return_value = mock_client

        with pytest.raises(SystemExit):
            sys.argv = ["script", "--subscription-id", "sub-id", "--output", str(output_file)]
            try:
                ger.main()
                exit_code = 0
            except SystemExit as e:
                exit_code = e.code

        assert exit_code == 0


def test_report_written_to_file(tmp_path):
    output_file = tmp_path / "report.json"
    mock_states = [
        make_state("/sub/rg/kv1", "Microsoft.KeyVault/vaults", "Compliant"),
    ]

    with patch("generate_evidence_report.DefaultAzureCredential"), \
         patch("generate_evidence_report.PolicyInsightsClient") as mock_client_cls:
        mock_client = MagicMock()
        mock_client.policy_states.list_query_results_for_subscription.return_value = mock_states
        mock_client_cls.return_value = mock_client

        try:
            sys.argv = ["script", "--subscription-id", "sub-id", "--output", str(output_file)]
            ger.main()
        except SystemExit:
            pass

    assert output_file.exists()
    report = json.loads(output_file.read_text())
    assert "summary" in report
    assert "states" in report
    assert report["subscriptionId"] == "sub-id"
