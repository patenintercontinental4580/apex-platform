"""Tests for audit-rbac-assignments.py"""
import json
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

import pytest
import sys

sys.path.insert(0, str(Path(__file__).parent.parent))

import audit_rbac_assignments as ara


# ─── Fixtures ────────────────────────────────────────────────────────────────

OWNER_ROLE_ID = "/subscriptions/sub/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635"
CONTRIBUTOR_ROLE_ID = "/subscriptions/sub/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
READER_ROLE_ID = "/subscriptions/sub/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
UAA_ROLE_ID = "/subscriptions/sub/providers/Microsoft.Authorization/roleDefinitions/18d7d88d-d35e-4fb5-a5c3-7773c20a72d9"


def make_assignment(principal_type, role_def_id, scope="/subscriptions/sub-id"):
    return SimpleNamespace(
        id="/subscriptions/sub-id/providers/Microsoft.Authorization/roleAssignments/some-guid",
        principal_id="00000000-0000-0000-0000-000000000000",
        principal_type=principal_type,
        role_definition_id=role_def_id,
        scope=scope,
    )


# ─── flag_issues ─────────────────────────────────────────────────────────────

def test_direct_user_owner_is_high_severity():
    issues = ara.flag_issues([make_assignment("User", OWNER_ROLE_ID)])
    assert len(issues) == 1
    assert issues[0]["severity"] == "HIGH"
    assert issues[0]["type"] == "DirectUserAssignment"


def test_direct_user_uaa_is_high_severity():
    issues = ara.flag_issues([make_assignment("User", UAA_ROLE_ID)])
    assert len(issues) == 1
    assert issues[0]["severity"] == "HIGH"


def test_direct_user_contributor_is_medium_severity():
    issues = ara.flag_issues([make_assignment("User", CONTRIBUTOR_ROLE_ID)])
    assert len(issues) == 1
    assert issues[0]["severity"] == "MEDIUM"


def test_direct_user_reader_is_medium():
    issues = ara.flag_issues([make_assignment("User", READER_ROLE_ID)])
    assert len(issues) == 1
    assert issues[0]["severity"] == "MEDIUM"


def test_group_assignment_not_flagged():
    issues = ara.flag_issues([make_assignment("Group", OWNER_ROLE_ID)])
    assert len(issues) == 0


def test_service_principal_not_flagged():
    issues = ara.flag_issues([make_assignment("ServicePrincipal", CONTRIBUTOR_ROLE_ID)])
    assert len(issues) == 0


def test_mixed_assignments():
    assignments = [
        make_assignment("User", OWNER_ROLE_ID),
        make_assignment("Group", OWNER_ROLE_ID),
        make_assignment("User", CONTRIBUTOR_ROLE_ID),
        make_assignment("ServicePrincipal", CONTRIBUTOR_ROLE_ID),
    ]
    issues = ara.flag_issues(assignments)
    assert len(issues) == 2
    severities = {i["severity"] for i in issues}
    assert "HIGH" in severities
    assert "MEDIUM" in severities


def test_no_assignments_no_issues():
    assert ara.flag_issues([]) == []


# ─── main exit codes ─────────────────────────────────────────────────────────

def test_main_exits_1_when_issues_found():
    with patch("audit_rbac_assignments.DefaultAzureCredential"), \
         patch("audit_rbac_assignments.AuthorizationManagementClient") as mock_cls:
        mock_client = MagicMock()
        mock_client.role_assignments.list_for_scope.return_value = [
            make_assignment("User", OWNER_ROLE_ID)
        ]
        mock_cls.return_value = mock_client

        with pytest.raises(SystemExit) as exc_info:
            sys.argv = ["script", "--subscription-id", "sub-id"]
            ara.main()

    assert exc_info.value.code == 1


def test_main_exits_0_when_no_issues():
    with patch("audit_rbac_assignments.DefaultAzureCredential"), \
         patch("audit_rbac_assignments.AuthorizationManagementClient") as mock_cls:
        mock_client = MagicMock()
        mock_client.role_assignments.list_for_scope.return_value = [
            make_assignment("Group", OWNER_ROLE_ID)
        ]
        mock_cls.return_value = mock_client

        exit_code = None
        try:
            sys.argv = ["script", "--subscription-id", "sub-id"]
            ara.main()
            exit_code = 0
        except SystemExit as e:
            exit_code = e.code

    assert exit_code == 0


def test_main_writes_output_file(tmp_path):
    output_file = tmp_path / "rbac-report.json"

    with patch("audit_rbac_assignments.DefaultAzureCredential"), \
         patch("audit_rbac_assignments.AuthorizationManagementClient") as mock_cls:
        mock_client = MagicMock()
        mock_client.role_assignments.list_for_scope.return_value = []
        mock_cls.return_value = mock_client

        try:
            sys.argv = ["script", "--subscription-id", "sub-id", "--output", str(output_file)]
            ara.main()
        except SystemExit:
            pass

    assert output_file.exists()
    report = json.loads(output_file.read_text())
    assert "issues" in report
    assert report["subscriptionId"] == "sub-id"
    assert "totalAssignments" in report
