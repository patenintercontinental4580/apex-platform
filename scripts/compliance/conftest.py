import sys
from pathlib import Path

# Ensure the compliance scripts directory is on the path so that
# audit_rbac_assignments and generate_evidence_report can be imported
# by the test suite regardless of how pytest is invoked.
sys.path.insert(0, str(Path(__file__).parent))
