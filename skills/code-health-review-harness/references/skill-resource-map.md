# Skill and Standards Resource Map

This file records reusable resources for the harness.

## Installed Local Skills To Reuse Conceptually

| Resource | Use For | Notes |
|---|---|---|
| `architecture-designer-0.1.0` | Architecture, ADRs, non-functional requirements, tradeoffs | Use for architecture review framing. |
| `security-auditor-1.0.0` | OWASP, authentication, authorization, input validation, secrets, headers | Use for security dimension. |
| `test-runner-1.0.0` | Test strategy, coverage, pytest, Vitest/Jest, Playwright | Use for test and verification dimension. |
| `debug-pro-1.0.0` | Root cause analysis, reproduction, regression thinking | Use when findings require diagnosis discipline. |
| `code-1.0.4` | Planning, execution, verification workflow | Use as general engineering workflow reference. |
| `skill-vetter-1.0.0` | Vetting unknown skills before installation | Mandatory before adding external skills. |
| `find-skills` | Searching open agent skills | Use only in explicit resource expansion mode. |

## External Standards

| Standard | Review Mapping |
|---|---|
| Google Engineering Practices Code Review | Design, functionality, complexity, tests, naming, comments, style, documentation. |
| ISO/IEC 25010 | Functional suitability, performance efficiency, compatibility, interaction capability, reliability, security, maintainability, portability, flexibility, safety. |
| OWASP Top 10 | Broad web application security risk awareness. |
| OWASP ASVS | Verifiable application security controls. |
| OWASP SAMM | Secure software development lifecycle maturity. |
| OpenSSF Scorecard | Repository and supply-chain health: CI, code review, dependency update, SAST, token permissions, security policy, vulnerabilities. |
| SLSA | Build integrity, provenance, release trust, supply chain hardening. |
| Twelve-Factor App | Config, dependencies, backing services, build/release/run, processes, logs, dev/prod parity. |

## External Skill Expansion Protocol

Use only when the user explicitly asks to expand harness resources.

1. Search candidates with queries such as `code review`, `architecture review`, `security audit`, `test coverage`, `maintainability`, `dependency audit`, `performance review`.
2. Present candidates with source, purpose, and install command.
3. Vet every candidate with `skill-vetter` before installation.
4. Reject skills with unknown network calls, credential access, obfuscation, destructive commands, or broad filesystem access.
5. Ask for user confirmation before installing.
6. After installation, update this map with version, source, vetting result, and intended use.

## Current Policy

The initial harness does not depend on unvetted external skills. Public standards and installed local skills are enough for baseline review.
