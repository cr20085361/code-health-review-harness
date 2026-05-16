# Evidence Rules

## Evidence Hierarchy

Prefer stronger evidence first:

1. Runtime or test result.
2. Source code path and symbol-level observation.
3. Configuration or manifest.
4. Repository history or CI evidence.
5. Documentation.
6. Inference from absence or naming.

Absence can be evidence, but only when the search scope is stated. Example: "No CI workflow was found under `.github/workflows/`" is acceptable. "There is no CI" is too broad unless other CI locations were checked.

## Finding Structure

Every material finding should include:

- `Severity`: Critical, High, Medium, Low, or Info.
- `Evidence`: File, config, command output, or searched location.
- `Impact`: What can break, slow down, leak, confuse, or block iteration.
- `Recommendation`: Concrete next step.
- `Verification`: How to confirm the fix.
- `Confidence`: High, Medium, or Low.

## Severity Rules

`Critical`:

- Realistic data loss, remote code execution, privilege bypass, secret exposure, production outage risk, or irrecoverable deployment risk.

`High`:

- Likely security vulnerability, core workflow breakage, missing server-side authorization, no backup for valuable data, serious test blind spot in high-risk logic.

`Medium`:

- Maintainability debt, performance risk, incomplete validation, brittle coupling, unclear deployment path, missing non-critical tests.

`Low`:

- Local cleanup, naming, small documentation drift, low-impact consistency issue.

`Info`:

- Useful observation, strength, tradeoff, or future opportunity.

## Anti-Patterns

Avoid these report patterns:

- Generic advice without repository evidence.
- Treating missing tests as automatically Critical.
- Penalizing intentional simple architecture just because it is not fashionable.
- Recommending large rewrites without a staged migration path.
- Mixing implementation work into a review unless explicitly requested.

## Strengths Need Evidence Too

When listing strengths, point to why they are strengths:

- Existing docs that match code.
- Clear separation of concerns.
- Tests around risky behavior.
- Good deployment or recovery scripts.
- Strong permission checks near server-side data access.
