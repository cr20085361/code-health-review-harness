# Module Input/Output Table

| Module | Inputs | Outputs | Called by / Consumed by | Notes |
|---|---|---|---|---|
| scripts/install-user-skill.ps1 | TargetRoot, Force | Copies the installable skill package into the user skill directory | Manual maintainer command | Distribution and local sync only; not used during review runtime. |
| scripts/verify-project.ps1 | None | Exit status plus structure validation message | CI, manual validation, run-safe-checks.ps1 | Fast structural gate for required files and SKILL frontmatter. |
| scripts/test-harness-smoke.ps1 | None | End-to-end pass/fail signal across session creation, facts, safe checks, history, and cleanup | Manual validation, run-safe-checks.ps1, future CI | Covers the highest-value workflow slice for this repository. |
| skills/code-health-review-harness/scripts/collect-repo-facts.ps1 | RepoPath, OutputPath | JSON facts document to stdout or file | SKILL fact collection, test-harness-smoke.ps1 | Read-only repository inventory with ignore filtering and optional file persistence. |
| skills/code-health-review-harness/scripts/run-safe-checks.ps1 | RepoPath, IncludeAudit, IncludeDocker | JSON result list of safe validation commands | SKILL safe-check phase, test-harness-smoke.ps1 | Runs repository-defined validation commands with bounded output capture. |
| skills/code-health-review-harness/scripts/new-review-session.ps1 | RepoPath, OutputRoot, SessionName, Force | Review session directory with metadata, report, findings, plan, matrix, log, artifacts | Review workflow bootstrap, manual session creation | Establishes stable IDs and report skeletons for follow-up AI sessions. |
| skills/code-health-review-harness/scripts/summarize-review-history.ps1 | ReportsRoot, OutputPath | Markdown summary of prior findings and verification states | Follow-up reviews, history inspection, test-harness-smoke.ps1 | Aggregates saved sessions into a status-oriented history view. |
