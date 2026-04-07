# Shim so pytest can import generate-evidence-report.py (hyphenated filename).
# Replaces itself in sys.modules with the real module so that
# patch("generate_evidence_report.PolicyInsightsClient") targets
# the same namespace that main() reads from.
import importlib.util, pathlib, sys as _sys

_spec = importlib.util.spec_from_file_location(
    "generate_evidence_report",
    pathlib.Path(__file__).parent / "generate-evidence-report.py",
)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)
_sys.modules[__name__] = _mod
