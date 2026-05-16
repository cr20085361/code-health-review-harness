# Verification Matrix

Every iteration recommendation should be tied to quantified verification. This prevents roadmap items from becoming vague advice.

## Required Columns

| Column | Meaning |
|---|---|
| Verification ID | Stable ID, for example `VER-20260515-001`. |
| Related Finding | One or more `CHR-*` finding IDs. |
| Priority | P0, P1 or P2. |
| Test Type | Unit, integration/API, E2E, RBAC, migration/rollback, security, performance, build/deploy, documentation consistency. |
| Target Area | Module, route, page, workflow, data model or deployment path. |
| Command/Method | Exact command or repeatable manual procedure. |
| Pass Criteria | Quantified pass/fail criteria. |
| Baseline | Current measured or observed state. |
| Target | Desired state after iteration. |
| Evidence Artifact | Expected file, log, screenshot, report or command output. |
| Owner | Person/team/AI session responsible. |
| Status | Canonical verification status from [status-taxonomy.md](./status-taxonomy.md): pending, running, passed, failed, blocked or accepted-risk. |

## Template

```markdown
| Verification ID | Related Finding | Priority | Test Type | Target Area | Command/Method | Pass Criteria | Baseline | Target | Evidence Artifact | Owner | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|
| VER-YYYYMMDD-001 | CHR-YYYYMMDD-001 | P0 | Integration/API |  |  |  |  |  |  | unassigned | pending |
```

## Verification Strength

| Priority | Minimum Verification Strength |
|---|---|
| P0 | Automated test or explicit repeatable manual script with pass/fail evidence. |
| P1 | Automated regression, integration check, build check or deterministic smoke test. |
| P2 | Documentation check, sampled manual verification or lightweight automated check, with saved evidence. |

## Test Type Guidance

### Unit

- Use for pure business rules, parsing, validation, calculations and state transitions.
- Pass criteria examples: named tests pass; boundary cases covered; branch coverage target reached.

### Integration/API

- Use for backend routes, database behavior, service boundaries and schema contracts.
- Pass criteria examples: status codes and response schemas match; transaction rollback verified; unauthorized cases return 401/403.

### E2E / Critical Path

- Use for user workflows that cross UI, API and persistence.
- Pass criteria examples: create/edit/delete flow passes in Chromium; screenshot or trace saved; no uncaught console errors.

### RBAC / Permission

- Use for role gates, ownership checks, approval flows and lifecycle actions.
- Pass criteria examples: each role matrix case passes; client-side and server-side permission behavior match.

### Migration / Rollback

- Use for schema changes, data cleanup and lifecycle transitions.
- Pass criteria examples: migration is idempotent; backup restore tested; rollback or forward-fix plan documented.

### Security

- Use for injection, path traversal, unsafe upload, XSS, CORS/CSP, dependency vulnerabilities and secret exposure.
- Pass criteria examples: malicious inputs rejected; audit has no high vulnerabilities or accepted-risk notes; no secrets detected in repo.

### Performance / Capacity

- Use for hot queries, bundle size, long-running endpoints and heavy UI flows.
- Pass criteria examples: p95 latency target met; bundle chunk limit met; query count bounded; memory usage within target.

### Build / Deploy

- Use for production build, type check, Docker config and deployment smoke.
- Pass criteria examples: command exit code 0; health check passes; build artifact generated; no new known warnings.

### Documentation Consistency

- Use for README, handover, operation manual, API docs and runbooks.
- Pass criteria examples: changed workflows documented; manual route exists; screenshots or steps match current UI.

## Examples

| Verification ID | Related Finding | Priority | Test Type | Target Area | Command/Method | Pass Criteria | Baseline | Target | Evidence Artifact | Owner | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|
| VER-20260515-001 | CHR-20260515-001 | P0 | RBAC | Archive deletion permission | `python -m pytest backend/tests/test_archive_permissions.py` | Super admin allowed; normal users rejected with 403; archived lifecycle unchanged | No dedicated regression test | All role cases pass | `artifacts/pytest-archive-permissions.log` | unassigned | pending |
| VER-20260515-002 | CHR-20260515-002 | P1 | E2E | Product archive upload | `npx playwright test archive-upload.spec.ts` | Upload, preview, delete, recycle-bin flow pass in Chromium | Manual smoke only | Automated critical path test passes | `artifacts/playwright-archive-upload/` | unassigned | pending |
| VER-20260515-003 | CHR-20260515-003 | P1 | Build / Deploy | Frontend production build | `npm run build` | Exit code 0; no new chunk or compatibility warnings beyond accepted baseline | Build result unknown | Build passes and warnings documented | `artifacts/frontend-build.log` | unassigned | pending |
