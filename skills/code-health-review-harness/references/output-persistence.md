# Output Persistence

Use this reference for the default code health review flow. Unless the user explicitly asks for chat-only output, save review artifacts for later AI-driven iteration. The saved files are review artifacts, not product code changes.

## Default Report Location

When the default persistence flow is active, create or suggest this structure in the reviewed repository unless the user specifies another path:

```text
code-health-reports/
  YYYYMMDD-HHMM-repo-slug/
    metadata.json
    review-report.md
    findings.json
    iteration-plan.md
    verification-matrix.md
    command-log.md
    artifacts/
```

The session folder name should be stable and sortable:

```text
20260515-0930-shelf-product-management-system
```

## Required Artifacts

| File | Audience | Purpose |
|---|---|---|
| `metadata.json` | AI and maintainers | Review id, repository path, timestamps, model/tool notes, artifact schema version. |
| `review-report.md` | Humans | Full readable report with summary, scores, strengths, findings, roadmap, verification and open questions. |
| `findings.json` | AI and automation | Structured findings with stable IDs, severity, dimension, evidence, recommendation, status and verification links. |
| `iteration-plan.md` | Humans and AI | P0/P1/P2 roadmap with dependencies, acceptance criteria and linked verification IDs. |
| `verification-matrix.md` | Humans and AI | Quantified test and validation matrix for closing findings. |
| `command-log.md` | Humans and AI | Commands run, working directory, exit code, output summary and artifacts. |
| `artifacts/` | Humans and AI | Optional screenshots, logs, coverage reports or exported command outputs. |

## Stable IDs

Use stable IDs so later AI sessions can continue from prior feedback:

```text
CHR-YYYYMMDD-001   Finding ID
ITER-YYYYMMDD-001  Iteration item ID
VER-YYYYMMDD-001   Verification item ID
```

Rules:

- Never reuse an ID for a different issue.
- Keep an ID stable when an issue remains open across reviews.
- Mark status changes instead of deleting historical findings.
- If a finding is superseded, link to the replacement ID.

## Findings JSON Shape

Use this structure:

```json
{
  "schema_version": "1.0",
  "review_id": "CHR-20260515-0930-shelf-product-management-system",
  "repo": "shelf-product-management-system",
  "created_at": "2026-05-15T09:30:00",
  "findings": [
    {
      "id": "CHR-20260515-001",
      "severity": "High",
      "dimension": "Security and permissions",
      "title": "Server-side permission check missing for archive deletion",
      "status": "open",
      "confidence": "Medium",
      "evidence": [
        {
          "type": "file",
          "path": "backend/app/routers/files.py",
          "note": "Deletion route inspected"
        }
      ],
      "impact": "Unauthorized deletion could bypass expected lifecycle controls.",
      "recommendation": "Move permission check next to server-side delete operation and add regression tests.",
      "verification_ids": ["VER-20260515-001"],
      "owner": "unassigned",
      "notes": []
    }
  ]
}
```

Allowed statuses:

Use canonical finding statuses from [status-taxonomy.md](./status-taxonomy.md):

- `open`
- `in-progress`
- `blocked`
- `verified-closed`
- `accepted-risk`
- `superseded`

## Persistence Workflow

1. Save review artifacts by default unless the user explicitly asks for `仅聊天不落盘`, `不要保存报告`, `只在聊天里输出`, or `chat-only output`.
2. Create the session folder with [new-review-session.ps1](../scripts/new-review-session.ps1) when available.
3. Fill `review-report.md`, `findings.json`, `iteration-plan.md`, `verification-matrix.md` and `command-log.md`.
4. In the final answer, link the session folder and name the generated artifacts.
5. If the user opted out or the workspace is read-only, still produce the same complete report in chat and clearly state that no files were written.
6. For follow-up work, read the latest timestamped session folder first, especially `findings.json` and `verification-matrix.md`.

## Opt-Out Phrases

These phrases should disable file writes while keeping the full report in chat:

- `仅聊天不落盘`
- `不要保存报告`
- `只在聊天里输出`
- `chat-only output`

## Follow-Up Invocation

Recommended user phrasing:

```text
根据 code-health-reports 里最新一次会话目录中的 findings.json 和 verification-matrix.md，继续关闭 P0 项并更新验证状态。
```

If no saved artifacts exist, continue from the chat report but state that traceability is weaker.
