# Shim so pytest can import audit-rbac-assignments.py (hyphenated filename).
# Replaces itself in sys.modules with the real module so that
# patch("audit_rbac_assignments.AuthorizationManagementClient") targets
# the same namespace that main() reads from.
import importlib.util, pathlib, sys as _sys

_spec = importlib.util.spec_from_file_location(
    "audit_rbac_assignments",
    pathlib.Path(__file__).parent / "audit-rbac-assignments.py",
)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)
_sys.modules[__name__] = _mod
