# Status Taxonomy

This reference defines the canonical statuses used by saved review artifacts. Keep templates, scripts and documentation aligned with this file.

## Finding Status

| Status | Meaning |
|---|---|
| `open` | Finding is valid and not yet addressed. |
| `in-progress` | Work has started, but the finding is not verified closed. |
| `blocked` | Work cannot proceed until a dependency, decision or environment issue is resolved. |
| `verified-closed` | The finding has been fixed and the linked verification evidence passed. |
| `accepted-risk` | The risk is understood and intentionally accepted. Include reason and owner in notes. |
| `superseded` | The finding was replaced by a newer finding ID. Link the replacement in notes. |

## Verification Status

| Status | Meaning |
|---|---|
| `pending` | Verification item is planned but not run. |
| `running` | Verification is in progress. |
| `passed` | Verification passed and evidence is attached or referenced. |
| `failed` | Verification ran and failed. |
| `blocked` | Verification cannot run because of missing dependency, environment or decision. |
| `accepted-risk` | Verification is intentionally waived; include risk acceptance reason. |

## Iteration Status

| Status | Meaning |
|---|---|
| `planned` | Iteration item is proposed but not started. |
| `in-progress` | Implementation has started. |
| `blocked` | Work is blocked. |
| `verified-closed` | Work is complete and linked verification passed. |
| `accepted-risk` | Work will not be done because the risk is accepted. |
| `superseded` | Item was replaced by a newer item. |

## Closure Rule

A finding should not move to `verified-closed` unless all required linked P0/P1 verification items are `passed`, or the remaining verification gap is explicitly documented as `accepted-risk`.
