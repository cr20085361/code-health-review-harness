# Verification Matrix

Review ID: CHR-20260518-0117-code-health-review-harness

| Verification ID | Related Finding | Priority | Test Type | Target Area | Command/Method | Pass Criteria | Baseline | Target | Evidence Artifact | Owner | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|
| VER-20260518-001 | CHR-20260518-001 | P1 | GitHub Actions smoke gate | CI workflow behavior | Inspect .github/workflows/validate.yml and run scripts/verify-project.ps1 plus scripts/test-harness-smoke.ps1 locally to match the CI commands. | Workflow file includes both steps; local parity run passes. | CI previously ran only verify-project.ps1. | Structure and smoke are both part of the CI gate. | .github/workflows/validate.yml; command-log.md | maintainer | passed |
| VER-20260518-002 | CHR-20260518-002 | P1 | Integration/config | PowerShell safe-check discovery policy | Add a safe allowlist/config and run run-safe-checks.ps1 against a repository that declares at least one custom PowerShell validation script. | Custom safe PowerShell validation is discovered and executed or skipped by explicit policy. | Discovery is hardcoded to verify-project and test-harness-smoke. | Discovery is driven by repository policy rather than repo-specific code branches. | artifacts/safe-check-config-test.json | maintainer | pending |
| VER-20260518-003 | CHR-20260518-003 | P1 | Unit/Pester + schema | Helper functions and artifact contracts | Add Pester coverage for path resolution, ignore filters, discovery logic, plus JSON/schema validation for saved artifacts. | Tests pass on supported PowerShell versions and fail on contract drift. | Only end-to-end smoke covers these behaviors today. | Fine-grained regression checks exist alongside smoke. | tests/Pester output | maintainer | pending |
| VER-20260518-004 | CHR-20260518-004 | P2 | CI matrix | Cross-platform runtime support | Run verify-project and smoke on windows-latest plus at least one pwsh non-Windows runner, or narrow docs with rationale. | Cross-platform leg passes, or docs are deliberately reduced to match evidence. | Automation currently runs only on windows-latest. | Runtime support statement is backed by automation or intentionally narrowed. | GitHub Actions run summary | maintainer | pending |

Allowed Status: pending, running, passed, failed, blocked, accepted-risk. See references/status-taxonomy.md.

