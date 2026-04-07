# Thin re-export shim so pytest can import generate-evidence-report.py
# The real module is generate-evidence-report.py
import importlib.util, pathlib

_spec = importlib.util.spec_from_file_location(
    "generate_evidence_report",
    pathlib.Path(__file__).parent / "generate-evidence-report.py",
)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)

from generate_evidence_report import *  # noqa: F401,F403
build_summary = _mod.build_summary
get_policy_states = _mod.get_policy_states
main = _mod.main
DefaultAzureCredential = _mod.DefaultAzureCredential
PolicyInsightsClient = _mod.PolicyInsightsClient
