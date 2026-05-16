# Review Dimensions

Use this matrix to avoid narrow reviews. Not every repository needs every item, but skipped dimensions must be explained.

| Dimension | What To Inspect | Strong Signals | Risk Signals | Typical Evidence |
|---|---|---|---|---|
| 1. Functional and product fit | Core workflows, business rules, edge cases, user objectives | Features align with documented workflows; clear domain rules; graceful empty/error states | Unclear requirements; partial workflows; duplicated business rules; missing boundary handling | README, specs, routes, UI flows, tests, domain models |
| 2. Architecture and modularity | Layers, dependency direction, module boundaries, abstractions, coupling | Clear ownership; stable boundaries; low accidental coupling; documented tradeoffs | God modules; circular dependencies; duplicated implementations; hidden side effects | Directory map, imports, service boundaries, ADRs, large files |
| 3. Backend and API | Routes, schemas, validation, errors, transactions, concurrency, authorization | Explicit request/response schemas; consistent errors; transaction discipline; permission checks near data access | Business logic in routes; inconsistent status codes; weak validation; missing ownership checks | API routers, schemas, CRUD/services, middleware, tests |
| 4. Frontend and interaction | Navigation, state, component split, forms, loading/error states, accessibility | Predictable flows; typed API client; reusable components; clear feedback states | State drift; duplicated API calls; missing validation; fragile route guards; inaccessible controls | Views, stores, router, API client, component hierarchy |
| 5. Data, migration, and lifecycle | Data model, constraints, migrations, indexing, soft delete, retention, backup | Clear invariants; reversible migrations; indexes for hot paths; tested lifecycle semantics | Implicit constraints only in UI; manual migrations; no backup/restore drill; stale lifecycle flags | Models, migrations, DB scripts, backup docs, lifecycle code |
| 6. Security and permissions | Authn/authz, RBAC, input validation, file upload, injection, XSS, CORS/CSP, secrets | Least privilege; server-side authorization; sanitized file handling; no secrets in repo | Client-only permission checks; path traversal; broad CORS; unsafe HTML; leaked tokens | Middleware, deps, permissions, upload routes, config, dependency audit |
| 7. Testing and quality gates | Unit, integration, E2E, smoke, regression, CI, coverage, fixtures | Tests cover critical workflows; repeatable CI; explicit regression cases | No tests for core logic; flaky E2E; manual-only validation; no CI | Test folders, scripts, CI workflow, reports, coverage config |
| 8. Performance and capacity | Hot queries, bundle size, lazy loading, caching, long tasks, resource limits | Measured bottlenecks; pagination; lazy heavy deps; bounded operations | N+1 queries; unbounded lists; giant bundles; sync blocking work; no timeouts | Query code, build output, profiling notes, API timeouts |
| 9. Operations and delivery | Config, Docker, logs, health checks, backup, deploy docs, dev/prod parity | Environment-driven config; reproducible builds; health checks; recovery procedure | Hardcoded paths; unclear deploy; missing logs; dev/prod drift; no rollback plan | Dockerfile, compose, env docs, scripts, runbooks, logs |
| 10. Supply chain and repository health | Dependency pinning, vulnerability scanning, CI permissions, branch protection, release trust | Locked deps; audit workflow; minimal CI token permissions; security policy | Unpinned actions; no dependency update path; binary blobs; no vulnerability process | lockfiles, workflows, package manifests, SECURITY, release docs |
| 11. Documentation and maintainability | README, handover, operation manual, naming, comments, complexity, onboarding | Docs match code; clear setup; small cohesive modules; useful comments | Outdated docs; obscure naming; stale comments; large duplicated logic; tribal knowledge | README, docs, comments, file sizes, onboarding scripts |
| 12. Iteration economics | Risk/value order, dependencies, reversibility, verification cost | Roadmap decomposes risk; quick wins identified; validation path clear | Big-bang rewrites; expensive changes without evidence; no rollback strategy | plans, issue backlog, architecture notes, test gaps |

## Scoring Guide

Use 0-5 scores:

- `5`: Strong evidence of mature, repeatable practice.
- `4`: Mostly healthy; minor gaps or localized debt.
- `3`: Usable but uneven; important gaps need attention.
- `2`: Significant risk; fragile or under-verified.
- `1`: Critical weakness in a core area.
- `0`: Not present or impossible to assess because essential artifacts are absent.

Confidence:

- `High`: Multiple direct evidence sources agree.
- `Medium`: Some direct evidence, but incomplete runtime/test verification.
- `Low`: Mostly structural inference or documentation-only evidence.
