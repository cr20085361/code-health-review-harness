# Command Log

Review ID: CHR-20260515-1013-code-health-review-harness-self-review

| Command | Working Directory | Exit Code | Result | Evidence Artifact |
|---|---|---:|---|---|
| `new-review-session.ps1 -RepoPath .\\code-health-review-harness -OutputRoot code-health-reports -SessionName 20260515-1013-code-health-review-harness-self-review -Force` | workspace root | 0 | Created review session and templates. | this folder |
| `collect-repo-facts.ps1 -RepoPath .\\code-health-review-harness -OutputPath ...\\artifacts\\repo-facts.json` | workspace root | 0 | Collected 30 source files, 1 workflow, 9 docs, no manifests/tests. | artifacts/repo-facts.json |
| `run-safe-checks.ps1 -RepoPath .\\code-health-review-harness` | workspace root | 0 | Returned valid JSON but `results` was empty. | artifacts/safe-checks.json |
| `.\\code-health-review-harness\\scripts\\verify-project.ps1` | workspace root | 0 | Project verification passed. | terminal output |
| `.\\code-health-review-harness\\scripts\\test-harness-smoke.ps1` | workspace root | 0 | Smoke test passed; created and removed child temp dirs. | terminal output |
| `.\\code-health-review-harness\\scripts\\install-user-skill.ps1 -Force -WhatIf` | workspace root | 0 | WhatIf simulated backup/remove/install but also printed `Installed skill to`, which is misleading. | terminal output |
| `git status --short -- code-health-review-harness; git diff --stat -- code-health-review-harness` | workspace root | 0 | Parent repo sees the subproject as untracked; no diff stat because it is not yet tracked. | terminal output |
| `rg -n ... code-health-review-harness` | workspace root | 1 | `rg` is not installed in the active terminal; VS Code grep/file search and PowerShell were used instead. | terminal output |
| `collect-repo-facts.ps1 -RepoPath .\\code-health-review-harness -OutputPath <absolute artifact path>` | workspace root | 1 | Reproduced NotSupportedException at collect-repo-facts.ps1 line 172. | terminal output |
| `summarize-review-history.ps1 -ReportsRoot <absolute reports root> -OutputPath <absolute artifact path>` | workspace root | 0 | Absolute ReportsRoot and OutputPath worked. | artifacts/history-absolute-path-test.md |
| `get_errors code-health-review-harness` | VS Code | 0 | No editor diagnostics found. | tool output |
| `Test-Path .\\code-health-review-harness\\.tmp` | workspace root | 0 | Returned True after smoke; directory was empty. | terminal output |
| `apply_patch` | workspace | 0 | Implemented all five findings: path resolution, PowerShell safe-check discovery, WhatIf messaging, usage cleanup, and .tmp cleanup. | source files |
| `.\\code-health-review-harness\\scripts\\verify-project.ps1` | workspace root | 0 | Project verification passed after fixes. | terminal output |
| `.\\code-health-review-harness\\scripts\\test-harness-smoke.ps1` | workspace root | 0 | Enhanced smoke test passed, including absolute OutputPath and PowerShell safe-check discovery. | terminal output |
| `collect-repo-facts.ps1 -OutputPath <absolute artifact path>` | workspace root | 0 | Absolute OutputPath wrote JSON and parsed with repoPath/fileCount. | artifacts/repo-facts-absolute-path-test.json |
| `run-safe-checks.ps1 -RepoPath .\\code-health-review-harness` | workspace root | 0 | Reported powershell:verify-project and powershell:test-harness-smoke as passed. | artifacts/safe-checks.json |
| `.\\code-health-review-harness\\scripts\\install-user-skill.ps1 -Force -WhatIf` | workspace root | 0 | Output no longer includes Installed skill to and contains a dry-run completion message. | artifacts/install-whatif.log |
| `docs/usage.md heading and notice count check` | workspace root | 0 | First line is # Usage; notice appears once. | terminal output |
| `Test-Path .\\code-health-review-harness\\.tmp` | workspace root | 0 | Returned False after enhanced smoke cleanup. | terminal output |
| `summarize-review-history.ps1 -ReportsRoot .\\code-health-review-harness\\code-health-reports` | workspace root | 0 | History summary now reports 5 verified-closed findings and 5 passed verification rows. | artifacts/history-summary.md |
| `.\\code-health-review-harness\\scripts\\install-user-skill.ps1 -Force -NoBackup` | workspace root | 0 | Updated installable skill package was synced to the user-level global skills directory. | `%USERPROFILE%\\.agents\\skills\\code-health-review-harness` |
| `read_file global skill scripts` | global skills directory | 0 | Confirmed installed collect-repo-facts and run-safe-checks contain the new path resolver and PowerShell safe-check discovery. | tool output |

