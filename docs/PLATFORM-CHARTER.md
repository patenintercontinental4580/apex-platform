# Apex Platform Charter

## Mission

The Apex Platform exists to **reduce the time from idea to production** for application teams by providing a curated, secure, and opinionated set of infrastructure building blocks, pipeline templates, and golden path project templates on Azure.

## Platform Metrics

| Metric | Target | Measurement |
|---|---|---|
| Time to first deployment (new service) | < 2 hours | Backstage golden path completion time |
| Infrastructure provisioning time | < 15 minutes | Terraform apply duration P95 |
| Pipeline success rate | > 95% | Azure DevOps/GitLab pipeline pass rate |
| Security policy compliance | > 99% | Azure Policy compliance dashboard |
| Mean time to recover (MTTR) | < 4 hours | Incident management system |
| Cost vs budget variance | < 5% | Azure Cost Management |

## Operating Principles

1. **Security by default.** All modules enforce encryption at rest, private endpoints, managed identity, and mandatory tagging. Teams cannot opt out of security controls.
2. **Golden paths, not golden cages.** The platform provides the paved road; teams can bring custom infrastructure for justified edge cases via the RFC process.
3. **Modules over scripts.** All infrastructure is expressed as reusable Terraform modules. One-off scripts are not permitted in production environments.
4. **Shift-left compliance.** Checkov, OPA, and tflint run in every PR pipeline. Policy violations block merges; they do not alert post-deployment.
5. **You build it, you own it.** Platform Engineering owns the modules and templates. Application teams own their landing zones and workloads.

## Support Tiers

| Tier | Response SLA | Examples |
|---|---|---|
| **P1 — Production outage** | 30 minutes | Platform-wide networking failure, Key Vault unavailable |
| **P2 — Production degraded** | 2 hours | Slow pipeline, single module defect |
| **P3 — Non-production** | 1 business day | Dev environment issue, documentation gap |
| **P4 — Enhancement** | Roadmap review | New module request, golden path addition |

## Module Versioning

All modules follow [Semantic Versioning](https://semver.org/). Breaking changes increment the major version. Teams must upgrade within 90 days of a major version release.

## Review Cadence

| Review | Frequency | Participants |
|---|---|---|
| Platform roadmap review | Monthly | Platform Engineering leads, product owners |
| Security posture review | Quarterly | Platform Engineering, Security team |
| Cost governance review | Monthly | Platform Engineering, FinOps |
| Golden path feedback | Sprint retrospective | Platform Engineering, application teams |

## Contact

- **Slack:** `#platform-engineering`
- **Email:** `platform-engineering@example.com`
- **Backstage:** [Apex Platform system](https://backstage.example.com/catalog/default/system/apex-platform)
- **On-call:** PagerDuty escalation policy `apex-platform-oncall`
