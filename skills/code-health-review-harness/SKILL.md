---
name: code-health-review-harness
description: "Use when the user asks for 代码体检, 工程检视, 全维度代码分析, 代码优缺点分析, 架构优缺点, 软件工程审计, 后续迭代建议, code health review, architecture review, engineering audit, maintainability review, security review, testing review, or repository quality assessment. Produces evidence-based scores, strengths, risks, and P0/P1/P2 roadmap recommendations."
argument-hint: "Repository or current workspace to review"
---

# Code Health Review Harness

Use this skill to run a professional, full-dimensional code health review for a software project. The goal is not to make code changes; the goal is to understand what the system does, where it is strong, where it is fragile, and what should be improved next.

## Default Behavior

- Answer in Chinese unless the user requests another language.
- Review the current workspace by default.
- Prefer evidence over opinion: cite files, modules, configs, commands, tests, docs, and observable behavior.
- Separate strengths from risks. A good report should not be only a bug list.
- Produce management summary, engineering detail, score table, and P0/P1/P2 roadmap.
- Do not modify product code, configs, database, deployment, dependencies, or generated artifacts unless the user explicitly changes the task from review to implementation.

## Required Resource Loading

Load these references as needed:

- Full dimension matrix: [review-dimensions.md](./references/review-dimensions.md)
- Evidence and severity rules: [evidence-rules.md](./references/evidence-rules.md)
- Safe command playbook: [tooling-playbook.md](./references/tooling-playbook.md)
- Report template: [report-template.md](./references/report-template.md)
- Reusable skills and standards map: [skill-resource-map.md](./references/skill-resource-map.md)

If the user asks to expand the harness with external skills, follow the extension protocol in [skill-resource-map.md](./references/skill-resource-map.md). Never install unknown skills before vetting and user confirmation.

## Workflow

1. **Preflight**
   - Identify repository roots, git status, project type, major languages, package manifests, CI files, Docker/deployment files, docs, test folders, and customization instructions.
   - Check whether the user allowed safe validation commands. If not stated, safe read-only and validation commands are allowed; destructive commands are not.

2. **Scope**
   - Summarize the system purpose, core modules, runtime shape, and business domain.
   - Identify review emphasis requested by the user. If none is provided, cover all dimensions.

3. **Fact Collection**
   - Search and read representative files before forming conclusions.
   - Prefer fast search tools and targeted reads.
   - Optionally run [collect-repo-facts.ps1](./scripts/collect-repo-facts.ps1) on Windows workspaces when script execution is appropriate.

4. **Safe Checks**
   - Use [tooling-playbook.md](./references/tooling-playbook.md) to decide which commands are safe.
   - Record command, working directory, exit code, and concise result.
   - If a command is missing, fails, or would be unsafe, skip it and document why.

5. **Multi-Dimensional Review**
   - Use [review-dimensions.md](./references/review-dimensions.md).
   - For each dimension, identify strengths, risks, missing evidence, and likely next improvements.
   - Map security findings to OWASP/ASVS concepts when relevant.
   - Map repository and supply-chain findings to OpenSSF/SLSA concepts when relevant.

6. **Scoring**
   - Score each applicable dimension from 0 to 5.
   - Include confidence: High, Medium, or Low.
   - Explain the strongest evidence and the main deduction reason.

7. **Roadmap**
   - Produce P0/P1/P2 recommendations.
   - Each item must include why now, expected value, implementation notes, dependencies, and verification method.

8. **Final Report**
   - Use [report-template.md](./references/report-template.md).
   - Keep the top summary concise, then provide enough engineering detail for action.
   - End with unverified areas and human confirmation items.

## Command Safety Contract

Allowed by default:

- Repository inspection: `git status`, `git diff --stat`, `rg --files`, file reads.
- Validation: build, test, lint, type check, audit, dependency list, Docker compose config validation.
- Local-only scripts bundled with this skill that do not modify the reviewed repository.

Forbidden by default:

- `git reset`, `git checkout --`, `git clean`, destructive delete commands.
- Production deployment, database write migrations, package upgrades, global installs.
- Automatic formatting or auto-fix across the repository.
- Reading or printing secrets, private keys, cookies, tokens, or credential stores.
- Installing external skills or tools without vetting and user confirmation.

## Output Quality Bar

Every High or Critical finding needs:

- Evidence.
- Impact.
- Recommended fix or mitigation.
- Verification method.
- Confidence level.

If evidence is weak, label the item as a hypothesis or open question.
