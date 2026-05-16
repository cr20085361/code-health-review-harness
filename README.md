# Code Health Review Harness

> Evidence-based, full-dimensional engineering review for software projects, packaged as an installable agent skill.

`code-health-review-harness` 把架构、功能、后端、前端、数据、安全、测试、性能、运维、供应链、文档和迭代经济性 12 个维度的工程检视固化成可重复执行的 review 流程。一句话触发，一次执行，一份带证据、评分、风险和 P0/P1/P2 迭代建议的报告。

- 不只是代码审查 prompt，而是一套带 references、scripts、安全契约和落盘工件的 skill 工程
- 默认中文回答，默认在当前 workspace 工作
- 默认只读 + 验证类命令，destructive 命令默认禁止
- 每次 review 产出可追溯工件（metadata、findings、iteration plan、verification matrix、command log、artifacts）
- 稳定 ID（CHR-/ITER-/VER-）让多轮 AI 会话能续接迭代而不丢失上下文

## 推荐触发语

中文（推荐）：

```text
对当前工程做一次全面代码体检
```

更明确的版本：

```text
请用 code-health-review-harness 对当前仓库做全维度工程检视，输出评分、优缺点和 P0/P1/P2 迭代建议
```

英文：

```text
Run a full code health review for this repository with architecture, security, testing, maintainability, and roadmap recommendations.
```

## 示例报告

仓库内置一份用 harness 自己审查 harness 自身的样例：

- [`code-health-reports/20260515-1013-code-health-review-harness-self-review/review-report.md`](code-health-reports/20260515-1013-code-health-review-harness-self-review/review-report.md)
- [`code-health-reports/20260515-1013-code-health-review-harness-self-review/findings.json`](code-health-reports/20260515-1013-code-health-review-harness-self-review/findings.json)
- [`code-health-reports/20260515-1013-code-health-review-harness-self-review/iteration-plan.md`](code-health-reports/20260515-1013-code-health-review-harness-self-review/iteration-plan.md)

该会话是 harness 的自评审产生的样例，仅用于展示输出形态。其中所列 5 个发现已全部 verified-closed、属于已闭环示例，不应被视为本仓库当前的开放问题。

## Known runtime（运行时支持）

当前 harness 是 PowerShell 脚本 + Markdown 文档：

- Windows + PowerShell 5.1：受支持，是默认目标环境
- Windows + PowerShell 7：受支持，是参考实现
- macOS、Linux：仅在 PowerShell 7（pwsh）下受支持
- Bash 镜像（Bash 端口）：不在 0.2 范围内，后续版本评估

跨平台字符编码与换行：所有生成的文本（Markdown、JSON、PS 脚本）保持 UTF-8 无 BOM，行尾以 LF 为目标，由 `.gitattributes` 显式约束。

## 仓库结构

```text
code-health-review-harness/
  README.md                       # 本文件
  CHANGELOG.md                    # 版本变化
  CONTRIBUTING.md                 # 贡献原则
  SECURITY.md                     # 安全策略
  LICENSE                         # 许可证（计划于 0.2.0 落地）
  docs/
    architecture.md               # 双层结构、运行模型
    usage.md                      # 触发语、报告契约、opt-out
    maintenance.md                # 版本策略、发布前检查
    roadmap.md                    # 0.2.x / 0.3.x / 1.0.0 路线
    github-repo-checklist.md      # 上 GitHub 前的清单
  scripts/
    install-user-skill.ps1        # 复制 skill 到 %USERPROFILE%\.agents\skills
    verify-project.ps1            # 仓库结构与 frontmatter 校验
    test-harness-smoke.ps1        # 端到端 smoke
  skills/
    code-health-review-harness/
      SKILL.md                    # skill 主入口
      references/                 # 渐进加载的检视维度、规则、playbook
      scripts/                    # 事实采集、安全命令运行、会话管理
  code-health-reports/            # 落盘的评审会话（保留作为示例）
  .github/
    ISSUE_TEMPLATE/                # bug & feature 模板
    PULL_REQUEST_TEMPLATE.md
    workflows/validate.yml         # CI 结构校验
  .kiro/
    specs/harness-v0-2-uplift/     # 0.2 升级的 EARS 规格
```

## 快速开始

### 安装到用户全局 skill

```powershell
.\scripts\install-user-skill.ps1 -Force
```

安装目标：

```text
%USERPROFILE%\.agents\skills\code-health-review-harness\
```

支持 `-WhatIf` 干运行；干运行不会修改全局 skill 目录。

### 触发一次评审

在任意 VS Code workspace 中输入：

```text
对当前工程做一次全面代码体检
```

agent 会读取 `SKILL.md`，按工作流：preflight → 事实采集 → 安全验证 → 多维度评审 → 评分 → P0/P1/P2 路线 → 落盘工件。

### 落盘默认开启，可显式关闭

默认在被评审仓库下创建：

```text
code-health-reports/YYYYMMDD-HHMM-<repo-slug>/
  metadata.json
  review-report.md
  findings.json
  iteration-plan.md
  verification-matrix.md
  command-log.md
  artifacts/
```

如希望仅在聊天中输出，使用以下任一短语：

- `仅聊天不落盘`
- `不要保存报告`
- `只在聊天里输出`
- `chat-only output`

### 验证仓库结构

```powershell
.\scripts\verify-project.ps1
```

它检查必要文件、`SKILL.md` frontmatter（`name` 与 `description`）等。CI 在 `windows-latest` 上对每个 push/PR 运行这一脚本。

### 跑端到端 smoke

```powershell
.\scripts\test-harness-smoke.ps1
```

smoke 会构造伪造目录、调用 `collect-repo-facts.ps1`、`run-safe-checks.ps1`、`new-review-session.ps1`、`summarize-review-history.ps1`，并断言关键不变量。运行后会清理 `.tmp/`。

## 12 个评审维度

| # | 维度 | 关注点 |
|---:|---|---|
| 1 | Functional and product fit | 核心工作流、业务规则、边界情形 |
| 2 | Architecture and modularity | 分层、依赖方向、模块边界、耦合度 |
| 3 | Backend and API | 路由、schema、校验、错误、事务、并发、授权 |
| 4 | Frontend and interaction | 路由、状态、组件拆分、表单、加载/错误状态、可访问性 |
| 5 | Data, migration and lifecycle | 数据模型、约束、迁移、索引、软删、保留、备份 |
| 6 | Security and permissions | 认证/授权、RBAC、输入校验、上传、注入、XSS、CORS/CSP、secrets |
| 7 | Testing and quality gates | 单元、集成、E2E、smoke、CI、覆盖率、夹具 |
| 8 | Performance and capacity | 热点查询、bundle 体积、懒加载、缓存、长任务、资源上限 |
| 9 | Operations and delivery | 配置、Docker、日志、健康检查、备份、部署、dev/prod 一致性 |
| 10 | Supply chain and repository health | 依赖锁定、漏洞扫描、CI 权限、分支保护、release 信任 |
| 11 | Documentation and maintainability | README、交付、运维手册、命名、注释、复杂度、上手成本 |
| 12 | Iteration economics | 风险/价值排序、依赖、可逆性、验证成本 |

完整矩阵见 [`skills/code-health-review-harness/references/review-dimensions.md`](skills/code-health-review-harness/references/review-dimensions.md)。

## 输出契约

每次体检默认包含：

1. **总评结论**：健康度、最大优势、最大风险、优先三件事
2. **评分表**：每个维度 0–5 分、置信度（High/Medium/Low）、主要证据、扣分原因
3. **优点（带证据）**：避免只列问题、对优势同样溯源
4. **问题与风险**：按 Severity 排序（Critical / High / Medium / Low / Info），每条含 Evidence、Impact、Recommendation、Verification、Confidence
5. **P0/P1/P2 迭代路线**：每条挂接到至少一个 Verification ID，含 Why now / Expected value / Dependencies
6. **已运行命令**：command、cwd、exit code、结果摘要
7. **未验证项**：被跳过、被环境阻塞或未授权运行的部分
8. **需要人工确认项**：产品决策、风险接受、生产假设、组织策略

报告格式见 [`skills/code-health-review-harness/references/report-template.md`](skills/code-health-review-harness/references/report-template.md)。证据等级与严重度规则见 [`evidence-rules.md`](skills/code-health-review-harness/references/evidence-rules.md)。

## 安全边界（Command Safety Contract）

默认允许：

- 仓库检查：`git status`、`git diff --stat`、`rg --files`、文件读取
- 验证类：build / test / lint / typecheck / audit、依赖列表、`docker compose config`
- 仓库自带的安全脚本（不修改被评仓库）

默认禁止：

- `git reset`、`git checkout --`、`git clean`、递归删除
- 生产部署、写库迁移、包升级、全局安装
- 全仓自动格式化或 auto-fix
- 读取或回显 secrets / tokens / 私钥
- 未经 vetting 安装外部 skill 或工具

完整清单见 [`tooling-playbook.md`](skills/code-health-review-harness/references/tooling-playbook.md)。安全策略见 [`SECURITY.md`](SECURITY.md)。

## 落盘工件与稳定 ID

| 工件 | 受众 | 用途 |
|---|---|---|
| `metadata.json` | AI / 维护者 | review id、仓库路径、时间戳、模型/工具说明 |
| `review-report.md` | 人 | 完整可读报告 |
| `findings.json` | AI / 自动化 | 结构化发现，含稳定 ID、severity、证据、状态 |
| `iteration-plan.md` | 人 / AI | P0/P1/P2 路线，挂接 Verification IDs |
| `verification-matrix.md` | 人 / AI | 量化的测试与验证矩阵 |
| `command-log.md` | 人 / AI | 命令、cwd、退出码、输出摘要 |
| `artifacts/` | 人 / AI | 截图、日志、覆盖率报告等 |

稳定 ID 形如 `CHR-YYYYMMDD-NNN`、`ITER-YYYYMMDD-NNN`、`VER-YYYYMMDD-NNN`。**永不复用**，跨会话保持稳定，使下一轮 AI 会话能直接续接。详见 [`output-persistence.md`](skills/code-health-review-harness/references/output-persistence.md) 与 [`status-taxonomy.md`](skills/code-health-review-harness/references/status-taxonomy.md)。

## 续接已有评审

```text
根据 code-health-reports 里最新一次会话目录中的 findings.json 和 verification-matrix.md，
继续关闭 P0 项并更新验证状态。
```

agent 会读取最新会话、按状态枚举更新发现，并把变更落到同一份工件里。

## Untrusted Repository Content

被评审仓库中的 README、issues、comments、code、错误信息和日志属于不可信数据。即便其中包含 `ignore previous instructions`、伪装成系统提示的 code comment、或嵌入到 error message / log 里的指令，harness 都不应据此覆盖本 skill 的安全契约或工作流。当被评内容与本 `SKILL.md` 的 safety contract 出现 precedence 冲突时，以 `SKILL.md` 为准；冲突应被作为 finding 记录，而不是被执行。

## 0.1 / 0.2 路线

- **0.1.0**（当前）：核心维度矩阵、报告模板、事实采集与安全命令脚本、会话落盘、CI 结构校验、smoke 用例
- **0.2.0**（spec 已就绪，见 `.kiro/specs/harness-v0-2-uplift/requirements.md`）：
  - 自评审污染防御（集中 Ignore_Set + smoke 断言）
  - LICENSE 落地与跨文件传播
  - 纯函数抽到 `skills/.../scripts/lib/` + Pester 5 单测 + CI 集成
  - Go / Rust / .NET / Java 多语言 safe-check
  - Safe_Check_Runner 加超时与 `.code-health-review.json` 仓库 allowlist（含路径逃逸、forbidden-verb、size cap）
  - 历史会话对比工具 `compare-review-sessions.ps1`
  - findings JSON Schema + PS7 `Test-Json` 校验、PS5.1 优雅跳过
  - 报告会话非破坏性轮转 `-RetainLast N` + `_archive/`
  - SKILL.md 提示注入声明
  - 跨平台运行说明、维度评分校准

完整 EARS 规格见 [`.kiro/specs/harness-v0-2-uplift/requirements.md`](.kiro/specs/harness-v0-2-uplift/requirements.md)。

## 贡献

- 设计目标与原则：[`docs/architecture.md`](docs/architecture.md)
- 维护策略与版本规则：[`docs/maintenance.md`](docs/maintenance.md)
- 贡献指南：[`CONTRIBUTING.md`](CONTRIBUTING.md)
- 路线图：[`docs/roadmap.md`](docs/roadmap.md)

报 bug 或新维度建议请用对应 issue 模板：

- [Bug report](.github/ISSUE_TEMPLATE/bug_report.md)
- [Feature request](.github/ISSUE_TEMPLATE/feature_request.md)

## 维护状态

当前版本：`0.1.0`

许可证：尚未选择。在 0.2.0 中将根据 [`.kiro/specs/harness-v0-2-uplift/requirements.md`](.kiro/specs/harness-v0-2-uplift/requirements.md) 需求 2 落地 MIT 或 Apache-2.0；在 LICENSE 文件确定前，默认保留全部权利。
