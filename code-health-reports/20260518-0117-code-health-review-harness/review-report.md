# Code Health Review Report

Review ID: CHR-20260518-0117-code-health-review-harness
Repository: code-health-review-harness
Created: 2026-05-18T01:17:49

## 总评结论

- Health: 良好
- One-line conclusion: 当前工作树已经恢复端到端 smoke、PowerShell safe-check 覆盖，并把 smoke 纳入 CI 门禁；剩余差距主要在更细粒度的自动化验证和跨平台覆盖。
- Biggest strength: 双层 skill 架构、稳定 ID 和报告落盘协议清晰，且 verify + smoke 已形成最小可用的 CI 门禁。
- Biggest risk: 仍缺少 Pester 与 schema 级测试，路径/忽略/工件结构回归主要依赖端到端 smoke 才能暴露。
- Top 3 next actions: 把 PowerShell safe-check 发现从仓库特例提升为显式策略；为路径/忽略/工件 schema 增加 Pester 与结构化校验；增加非 Windows 的 pwsh 验证腿。

## 评分表

| 维度 | 分数 0-5 | 置信度 | 主要证据 | 扣分原因 |
|---|---:|---|---|---|
| Functional and product fit | 4.4 | High | README.md, skills/code-health-review-harness/SKILL.md, smoke/safe-check 本地通过 | 主流程清晰，当前缺口主要在自动化深度而非目标定义。 |
| Architecture and modularity | 4.2 | High | docs/architecture.md, skills/, artifacts/module-io-table.md | 双层结构和 progressive loading 明确；脚本发现逻辑仍有仓库特定分支。 |
| Backend and API | N/A | High | 仓库事实与源码结构显示无后端/API 代码 | 该项目是 skill + PowerShell helper，不适用。 |
| Frontend and interaction | N/A | High | 仓库事实与源码结构显示无前端源码 | 该项目无 UI。 |
| Data, migration and lifecycle | 4.0 | Medium | references/output-persistence.md, new-review-session.ps1, findings/verification artifacts | 工件生命周期清晰；schema 约束尚未自动化验证。 |
| Security and permissions | 4.2 | Medium | SKILL.md command safety contract, tooling-playbook.md, SECURITY.md | 默认边界稳健；safe-check 策略仍未配置化。 |
| Testing and quality gates | 3.8 | High | scripts/test-harness-smoke.ps1 通过, run-safe-checks.ps1 返回 2 个 passed 结果, validate.yml 已运行 verify+smoke | verify 与 smoke 已进入 CI；主要剩余短板是缺少 Pester 和更细粒度的契约验证。 |
| Performance and capacity | 4.3 | Medium | 小型 PowerShell/Markdown 仓库、忽略规则、outputTail 截断 | 当前规模无明显热点；运行器超时/更细资源上限仍待演进。 |
| Operations and delivery | 3.9 | High | install-user-skill.ps1, verify-project.ps1, smoke, 会话落盘工件 | 安装/验证/报告闭环齐全；发布与持续验证仍偏轻量。 |
| Supply chain and repository health | 3.8 | Medium | SECURITY.md, .github/workflows/validate.yml, 低依赖面 | 依赖面小，但分支保护、发布信任和更细 CI 权限控制未验证。 |
| Documentation and maintainability | 4.3 | High | README.md, docs/*.md, references/*, module-io-table artifact | 文档覆盖广且与当前实现更一致；样例工件仍需按版本刷新以防老化。 |
| Iteration economics | 4.5 | High | roadmap.md, iteration-plan.md, verification-matrix.md, status-taxonomy.md | 稳定 ID 和验证矩阵降低续跑成本；下一步主要是把策略配置化。 |

## 关键优点

- 双层结构清楚：仓库根目录负责维护资产，skills/code-health-review-harness/ 保持为可安装 skill 包，符合 docs/architecture.md 的设计目标。
- 评审协议成熟：维度矩阵、证据规则、状态分类、输出模板和持久化协议已经形成闭环，而不是一次性聊天 prompt。
- 当前核心链路可执行：本轮本地运行 scripts/test-harness-smoke.ps1 已通过，直接运行 run-safe-checks.ps1 也成功发现并执行了 powershell:verify-project 与 powershell:test-harness-smoke。
- CI 最小门禁已形成：.github/workflows/validate.yml 现在会在每个 push/PR 上同时运行 verify-project 与 test-harness-smoke。
- 脚本职责边界清楚：本轮额外生成了 [artifacts/module-io-table.md](artifacts/module-io-table.md)，把每个核心脚本的输入、输出和调用关系单独沉淀为 artifact。

## 主要问题与风险

### CHR-20260518-001 - CI 行为级门禁已在本轮补齐

- Severity: Medium
- Status: verified-closed
- Evidence: .github/workflows/validate.yml 现在同时运行 .\scripts\verify-project.ps1 与 .\scripts\test-harness-smoke.ps1；本地等价验证两条命令均通过。
- Impact: 修复前，结构完整但行为已回归的变更可能在 push/PR 阶段漏过；修复后，结构与主流程都会进入门禁。
- Recommendation: 保持 smoke 快速且确定性强，使它能持续作为 CI 门禁；如需扩展，再单独追加 safe-check 结果断言。
- Verification: VER-20260518-001.
- Confidence: High.

### CHR-20260518-002 - PowerShell safe-check 发现仍是仓库特例逻辑

- Severity: Medium
- Evidence: skills/code-health-review-harness/scripts/run-safe-checks.ps1 当前显式发现 scripts/verify-project.ps1 与 scripts/test-harness-smoke.ps1，而非从仓库策略文件或统一约定中读取。
- Impact: harness 对当前仓库已足够，但推广到其他 PowerShell 仓库时，仍可能低估可运行的安全验证入口。
- Recommendation: 增加 `.code-health-review.json` allowlist 或更严格的命名/目录策略，把“可运行哪些 PowerShell 验证脚本”显式化。
- Verification: VER-20260518-002.
- Confidence: High.

### CHR-20260518-003 - 辅助逻辑缺少细粒度回归测试与 schema 校验

- Severity: Medium
- Evidence: 当前主要依赖 scripts/test-harness-smoke.ps1 做端到端回归；仓库中尚无 Pester 套件，README/roadmap 也把 Pester 和 schema 校验列为后续工作。
- Impact: 路径解析、忽略规则、状态工件结构等回归只能在较晚的 smoke 阶段发现，定位成本高于单元测试。
- Recommendation: 抽离纯函数到 lib 层，并为 Resolve-InputPath、Test-IgnoredPath、safe-check discovery、findings schema 增加 Pester/结构化验证。
- Verification: VER-20260518-003.
- Confidence: High.

### CHR-20260518-004 - 跨平台支持声明宽于自动化验证覆盖

- Severity: Low
- Evidence: README.md 声明支持 Windows PowerShell 5.1/7 及 macOS/Linux 的 pwsh，但 CI 当前只有 windows-latest。
- Impact: 非 Windows 上的 shell 细节或路径差异，可能在用户环境中才首次暴露。
- Recommendation: 至少增加一个 pwsh 的非 Windows CI 验证腿，或者在文档中把非 Windows 支持降为“有限验证”。
- Verification: VER-20260518-004.
- Confidence: Medium.

## P0/P1/P2 Roadmap

当前评审没有必须立即阻断使用的 P0 项；P1/P2 见 iteration-plan.md。

## 已运行验证

| Command | Working Directory | Exit Code | Result |
|---|---|---:|---|
| .\scripts\verify-project.ps1 | repo root | 0 | 结构校验通过；当前 CI workflow 已调用该脚本。 |
| .\scripts\test-harness-smoke.ps1 | repo root | 0 | 端到端 smoke 通过，覆盖会话创建、facts、safe-check、history 和清理链路。 |
| .\skills\code-health-review-harness\scripts\run-safe-checks.ps1 -RepoPath . | repo root | 0 | 返回 2 个结果，powershell:verify-project 与 powershell:test-harness-smoke 均为 passed。 |
| .\skills\code-health-review-harness\scripts\collect-repo-facts.ps1 -RepoPath . | repo root | 0 | 返回 repoPath、fileCount=45、1 个 workflow、无 manifest/tests，符合仓库当前形态。 |

## 未验证项

- 未在 GitHub 托管环境中验证分支保护、release/tag 策略、Dependabot 或 Actions token 权限。
- 未在 macOS/Linux 的 pwsh 环境执行同一套 smoke/safe-check。
- 尚未观察到本次 validate.yml 变更在 GitHub 托管 runner 上的实际 run summary；当前关闭结论基于 workflow 文件与本地等价命令验证。
- 未对全局 skill 安装目录做本轮写入验证，本轮评审聚焦于仓库内工作流与脚本行为。

## 需要人工确认

- PowerShell safe-check 的长期策略应采用显式 allowlist 配置，还是保守的命名约定。
- README 中的跨平台支持声明，是要继续保持为产品承诺，还是调整为“实验性支持直到 CI 覆盖完成”。


