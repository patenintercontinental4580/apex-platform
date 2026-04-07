package pipeline_test

import future.keywords.if

# ─── Fixtures ────────────────────────────────────────────────────────────────

mock_pipeline_good := {
    "stages": [
        {"name": "Build"},
        {"name": "Scan"},
        {"name": "DeployStaging"},
        {"name": "DeployProd"}
    ],
    "test_coverage": 85
}

mock_pipeline_missing_scan := {
    "stages": [
        {"name": "Build"},
        {"name": "DeployStaging"},
        {"name": "DeployProd"}
    ],
    "test_coverage": 85
}

mock_pipeline_prod_without_staging := {
    "stages": [
        {"name": "Build"},
        {"name": "Scan"},
        {"name": "DeployProd"}
    ],
    "test_coverage": 85
}

mock_pipeline_low_coverage := {
    "stages": [
        {"name": "Build"},
        {"name": "Scan"},
        {"name": "DeployStaging"},
        {"name": "DeployProd"}
    ],
    "test_coverage": 65
}

# ─── Tests ───────────────────────────────────────────────────────────────────

test_good_pipeline_has_no_denies if {
    import data.pipeline
    msgs := pipeline.deny with input as mock_pipeline_good
    count(msgs) == 0
}

test_deny_missing_scan_stage if {
    import data.pipeline
    msgs := pipeline.deny with input as mock_pipeline_missing_scan
    count([m | m := msgs[_]; contains(m, "security scan")]) > 0
}

test_deny_prod_without_staging if {
    import data.pipeline
    msgs := pipeline.deny with input as mock_pipeline_prod_without_staging
    count([m | m := msgs[_]; contains(m, "staging")]) > 0
}

test_deny_low_coverage if {
    import data.pipeline
    msgs := pipeline.deny with input as mock_pipeline_low_coverage
    count([m | m := msgs[_]; contains(m, "coverage")]) > 0
}

test_staging_regex_matches_various_names if {
    import data.pipeline
    # UAT should count as staging
    pipeline_with_uat := {
        "stages": [
            {"name": "Build"},
            {"name": "SecurityScan"},
            {"name": "DeployUAT"},
            {"name": "DeployProd"}
        ],
        "test_coverage": 85
    }
    msgs := pipeline.deny with input as pipeline_with_uat
    count([m | m := msgs[_]; contains(m, "staging")]) == 0
}

test_scan_regex_matches_trivy if {
    import data.pipeline
    pipeline_with_trivy := {
        "stages": [
            {"name": "Build"},
            {"name": "TrivyScan"},
            {"name": "DeployStaging"},
            {"name": "DeployProd"}
        ],
        "test_coverage": 85
    }
    msgs := pipeline.deny with input as pipeline_with_trivy
    count([m | m := msgs[_]; contains(m, "security scan")]) == 0
}
