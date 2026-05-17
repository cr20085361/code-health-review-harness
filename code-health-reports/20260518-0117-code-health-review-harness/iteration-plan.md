# Iteration Plan

Review ID: CHR-20260518-0117-code-health-review-harness

## Rules

- Every item must link to one or more Finding IDs.
- Every P0/P1 item must link to one or more Verification IDs.
- Do not close an item until its verification evidence is attached or the risk is explicitly accepted.

## P0

| Iteration ID | Related Finding | Recommendation | Why Now | Expected Value | Dependencies | Verification IDs | Status |
|---|---|---|---|---|---|---|---|
| none | none | No immediate P0 action is required for the current local repository state. | The repaired worktree is usable and core validation commands pass locally. | Focus stays on higher-leverage P1/P2 hardening. | none | none | accepted-risk |

## P1

| Iteration ID | Related Finding | Recommendation | Why Now | Expected Value | Dependencies | Verification IDs | Status |
|---|---|---|---|---|---|---|---|
| ITER-20260518-001 | CHR-20260518-001 | Add scripts/test-harness-smoke.ps1 to .github/workflows/validate.yml and fail the workflow on smoke regressions. | Recent regressions were behavioral and were not caught by the previous structure-only CI gate. | Prevent merge of workflow drift and keep the installable harness trustworthy. | GitHub Actions runtime budget, Windows runner availability | VER-20260518-001 | verified-closed |
| ITER-20260518-002 | CHR-20260518-002 | Introduce a repo-configured allowlist or strict naming convention for safe PowerShell validation scripts. | Current detection is good for this repo but does not generalize cleanly. | Makes safe-check discovery reusable across PowerShell repositories without ad hoc code edits. | Policy format decision, backward compatibility for existing scripts | VER-20260518-002 | planned |
| ITER-20260518-003 | CHR-20260518-003 | Extract pure helpers and add Pester plus artifact/schema validation. | Smoke is valuable but too coarse for isolating regressions in path and ignore logic. | Faster diagnosis, safer refactors, and better confidence in artifact contracts. | Helper boundary design, PS5.1-compatible test harness | VER-20260518-003 | planned |

## P2

| Iteration ID | Related Finding | Recommendation | Why Now | Expected Value | Dependencies | Verification IDs | Status |
|---|---|---|---|---|---|---|---|
| ITER-20260518-004 | CHR-20260518-004 | Add a non-Windows pwsh CI leg or narrow the README runtime claim until validated. | The documented support matrix is broader than current automation evidence. | Improves trust in portability claims and reduces user-environment surprises. | CI matrix cost, pwsh availability on hosted runners | VER-20260518-004 | planned |

