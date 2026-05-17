# 更新日志

本文档记录 `code-health-review-harness` 的版本变化。

## 0.1.1 - 2026-05-18

### 修复

- 修复 `test-harness-smoke.ps1` 与 `SKILL.md`、`docs/usage.md` 之间的文案漂移，恢复端到端 smoke 通过。
- 修复 `collect-repo-facts.ps1` 的绝对路径输出与 Git 警告处理，使仓库事实采集在当前工作流中稳定可用。
- 为 `run-safe-checks.ps1` 增加 PowerShell 项目的验证脚本发现能力，并加入 smoke 递归保护。

### 变更

- 将 `test-harness-smoke.ps1` 纳入 GitHub Actions `validate.yml`，形成结构校验 + 行为校验的最小门禁。
- 同步 `README.md`、最新评审工件与模块输入/输出表，使当前实现、文档和评审结论保持一致。
- 新增当前仓库的自评归档会话 `code-health-reports/20260518-0117-code-health-review-harness/`，作为本次功能快照附件。

## 0.1.0 - 2026-05-15

### 新增

- 初始全局代码体检 harness 工程。
- 新增 `code-health-review-harness` skill 包。
- 新增全维度检视矩阵、报告模板、证据规则、安全命令策略和资源映射。
- 新增仓库事实采集脚本与安全验证脚本。
- 新增 GitHub 维护文档、issue 模板、PR 模板和 CI 验证 workflow。
