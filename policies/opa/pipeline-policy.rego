package pipeline

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# Deny pipelines that deploy to production without a staging environment
deny contains msg if {
    has_prod_stage(input)
    not has_staging_stage(input)
    msg := "Pipeline deploys to production without a staging/pre-production stage. Add a staging deployment before production."
}

# Deny pipelines missing a security scan stage
deny contains msg if {
    not has_scan_stage(input)
    msg := "Pipeline is missing a security scan stage (Trivy, SonarQube, or OWASP dependency check required)."
}

# Deny pipelines with test coverage below threshold
deny contains msg if {
    coverage := input.test_coverage
    coverage < 80
    msg := sprintf(
        "Test coverage is %v%%, which is below the required threshold of 80%%.",
        [coverage]
    )
}

# Helper rules
has_prod_stage(pipeline) if {
    stage := pipeline.stages[_]
    regex.match("(?i)prod", stage.name)
}

has_staging_stage(pipeline) if {
    stage := pipeline.stages[_]
    regex.match("(?i)(staging|preprod|pre-prod|uat)", stage.name)
}

has_scan_stage(pipeline) if {
    stage := pipeline.stages[_]
    regex.match("(?i)(scan|security|sast|dast|trivy|sonar)", stage.name)
}
