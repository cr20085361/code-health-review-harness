# Verification Matrix

Review ID: CHR-20260515-1013-code-health-review-harness-self-review

| Verification ID | Related Finding | Priority | Test Type | Target Area | Command/Method | Pass Criteria | Baseline | Target | Evidence Artifact | Owner | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|
| VER-20260515-001 | CHR-20260515-001 | P1 | PowerShell integration | collect-repo-facts OutputPath | Run collect-repo-facts with an absolute OutputPath under artifacts. | Exit code 0; output file exists; JSON parses with repoPath and fileCount. | Absolute OutputPath failed with NotSupportedException. | Relative and absolute OutputPath both pass. | artifacts/repo-facts-absolute-path-test.json | AI session | passed |
| VER-20260515-002 | CHR-20260515-002 | P1 | Smoke / quality gate | run-safe-checks PowerShell project discovery | Run run-safe-checks against the harness repo. | JSON results includes verify-project and test-harness-smoke with status passed. | Results array was empty. | At least two project-defined safe checks are discovered and pass. | artifacts/safe-checks.json | AI session | passed |
| VER-20260515-003 | CHR-20260515-003 | P1 | CLI behavior | install-user-skill WhatIf | Run .\\scripts\\install-user-skill.ps1 -Force -WhatIf. | Output does not include Installed skill to; target contents are unchanged; dry-run message is explicit. | WhatIf output included Installed skill to. | Dry run and real install messages are distinct. | artifacts/install-whatif.log | AI session | passed |
| VER-20260515-004 | CHR-20260515-004 | P2 | Documentation consistency | docs/usage.md | Check heading and duplicate note count. | First line is # Usage; code-health-reports notice appears once in the closure section. | Notice appeared at line 1 and line 93. | One contextual notice only. | docs/usage.md | AI session | passed |
| VER-20260515-005 | CHR-20260515-005 | P2 | Smoke cleanup | scripts/test-harness-smoke.ps1 | Run smoke test, then inspect .tmp. | Smoke passes; .tmp is absent or documented/intentional; no child residue remains. | Smoke pass left empty .tmp parent. | Cleanup behavior is explicit and deterministic. | command-log.md | AI session | passed |

Allowed Status: pending, running, passed, failed, blocked, accepted-risk. See references/status-taxonomy.md.

