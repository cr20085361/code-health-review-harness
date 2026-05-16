# Iteration Plan

Review ID: CHR-20260515-1013-code-health-review-harness-self-review

## Rules

- Every item must link to one or more Finding IDs.
- Every P0/P1 item must link to one or more Verification IDs.
- Do not close an item until its verification evidence is attached or the risk is explicitly accepted.

## P0

| Iteration ID | Related Finding | Recommendation | Why Now | Expected Value | Dependencies | Verification IDs | Status |
|---|---|---|---|---|---|---|---|
| none | none | No P0 item in this review. | No critical safety, data-loss or production-risk issue was found. | Keeps iteration focused. | none | none | accepted-risk |

## P1

| Iteration ID | Related Finding | Recommendation | Why Now | Expected Value | Dependencies | Verification IDs | Status |
|---|---|---|---|---|---|---|---|
| ITER-20260515-001 | CHR-20260515-001 | Fix collect-repo-facts absolute OutputPath handling with a shared Resolve-InputPath helper and smoke coverage. | This is a confirmed script failure in a core artifact path. | Report persistence becomes reliable for both relative and absolute paths. | None. | VER-20260515-001 | verified-closed |
| ITER-20260515-002 | CHR-20260515-002 | Extend run-safe-checks to detect conservative PowerShell validation scripts or read an explicit allowlist. | Current safe-check output is empty for the harness itself. | Reviews of script/documentation projects gain meaningful default validation. | Conservative fixed allowlist selected for verify-project and test-harness-smoke. | VER-20260515-002 | verified-closed |
| ITER-20260515-003 | CHR-20260515-003 | Make install-user-skill WhatIf messaging truthful. | Dry-run trust is part of the script safety contract. | Operators can distinguish simulation from actual sync. | None. | VER-20260515-003 | verified-closed |

## P2

| Iteration ID | Related Finding | Recommendation | Why Now | Expected Value | Dependencies | Verification IDs | Status |
|---|---|---|---|---|---|---|---|
| ITER-20260515-004 | CHR-20260515-004 | Remove duplicate usage note before the H1 and keep one contextual note in the closure section. | This is visible documentation polish before GitHub extraction. | Cleaner onboarding docs. | None. | VER-20260515-004 | verified-closed |
| ITER-20260515-005 | CHR-20260515-005 | Remove empty .tmp parent after smoke cleanup or document intentional retention. | Repeated validation should leave a clean workspace. | Cleaner local maintenance behavior. | Remove empty .tmp after cleanup. | VER-20260515-005 | verified-closed |

