# Thin re-export shim so pytest can import audit-rbac-assignments.py
import importlib.util, pathlib

_spec = importlib.util.spec_from_file_location(
    "audit_rbac_assignments",
    pathlib.Path(__file__).parent / "audit-rbac-assignments.py",
)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)

flag_issues = _mod.flag_issues
get_role_assignments = _mod.get_role_assignments
main = _mod.main
DefaultAzureCredential = _mod.DefaultAzureCredential
AuthorizationManagementClient = _mod.AuthorizationManagementClient
