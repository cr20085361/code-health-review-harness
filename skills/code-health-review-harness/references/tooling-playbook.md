# Tooling Playbook

This playbook guides safe validation. Prefer repository-defined scripts over inventing commands.

## Default Allowed Commands

Repository inspection:

```powershell
git status --short
git diff --stat
rg --files
```

JavaScript / TypeScript:

```powershell
npm run build
npm test
npm run lint
npm run typecheck
npm audit --json
```

Python:

```powershell
python -m pytest
pytest
pip list --outdated
```

Docker:

```powershell
docker compose config
docker-compose config
```

Use only commands that exist in the project or system. If a command is missing, record it as skipped.

## Commands Requiring Explicit User Confirmation

- Package installation or upgrade.
- Database migrations that write data.
- Long-running E2E suites that launch browsers or services.
- Container builds that consume significant disk or network.
- Any command that writes outside normal build/test caches.

## Forbidden By Default

```text
git reset
git checkout --
git clean
Remove-Item -Recurse -Force on repository content
rm -rf
del /s
npm audit fix
npm update
pip install -U
docker compose up against production services
deploy scripts
cloud publish commands
```

## Command Result Reporting

Record:

- Command.
- Working directory.
- Exit code.
- Runtime.
- Important output summary.
- Whether the command may have produced build/test artifacts.

## Safe Script Usage

Bundled scripts:

- [collect-repo-facts.ps1](../scripts/collect-repo-facts.ps1): read-only facts.
- [run-safe-checks.ps1](../scripts/run-safe-checks.ps1): safe validation command runner.

These scripts are helpers, not mandatory. If direct tool use is clearer, use direct tool calls and still follow the same safety rules.
