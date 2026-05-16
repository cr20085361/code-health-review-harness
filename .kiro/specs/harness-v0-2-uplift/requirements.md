# Requirements Document

## Introduction

本规格描述 `code-health-review-harness` 从 0.1.0 升级到 0.2.0 所需的迭代和修复需求。该 harness 是一个基于 PowerShell 与 Markdown 的可重用 agent skill，运行基于证据的全维度工程评审，并将结果以稳定 ID（CHR-/ITER-/VER-）落入 `code-health-reports/<session>/`。本次迭代以前一轮自检会话（位于 `code-health-reports/20260515-1013-code-health-review-harness-self-review/`）的关闭项为背景，引入：自评审污染防御、LICENSE 落地、纯函数抽取与 Pester 单测、多语言只读校验扩展、安全命令超时与按仓库白名单、历史会话对比、可选 JSON Schema 校验、报告轮转、提示注入声明、跨平台与维度校准等改进。所有变更必须在保持 `findings.json` schema_version `1.0` 兼容、保持安全命令边界、保持 smoke 用例通过的前提下完成。

## Glossary

- **Harness**: 本仓库 `code-health-review-harness` 工程整体，包括 `skills/code-health-review-harness/` 包与根级 `scripts/`、`docs/`。
- **Repo_Facts_Collector**: 脚本 `skills/code-health-review-harness/scripts/collect-repo-facts.ps1`。
- **Safe_Check_Runner**: 脚本 `skills/code-health-review-harness/scripts/run-safe-checks.ps1`。
- **History_Comparator**: 新脚本 `skills/code-health-review-harness/scripts/compare-review-sessions.ps1`。
- **History_Summarizer**: 脚本 `skills/code-health-review-harness/scripts/summarize-review-history.ps1`。
- **Session_Creator**: 脚本 `skills/code-health-review-harness/scripts/new-review-session.ps1`。
- **Verify_Project**: 脚本 `scripts/verify-project.ps1`。
- **Smoke_Test**: 脚本 `scripts/test-harness-smoke.ps1`。
- **Installer**: 脚本 `scripts/install-user-skill.ps1`。
- **Skill_Manifest**: 文件 `skills/code-health-review-harness/SKILL.md`。
- **Tooling_Playbook**: 文件 `skills/code-health-review-harness/references/tooling-playbook.md`。
- **Review_Dimensions**: 文件 `skills/code-health-review-harness/references/review-dimensions.md`。
- **Output_Persistence**: 文件 `skills/code-health-review-harness/references/output-persistence.md`。
- **Pester_Suite**: 仓库 `tests/` 目录下的 Pester 5 测试集合。
- **Lib_Module**: 目录 `skills/code-health-review-harness/scripts/lib/` 下的纯函数模块（`*.ps1`），通过 dot-source 加载。
- **CI_Workflow**: 文件 `.github/workflows/validate.yml`。
- **PR_Template**: 文件 `.github/PULL_REQUEST_TEMPLATE.md`。
- **Report_Root**: 评审会话的根目录，默认 `code-health-reports/`，可通过参数覆盖。
- **Review_Session**: `Report_Root` 下的单次评审目录，命名为 `YYYYMMDD-HHMM-<slug>` 或显式 `SessionName`。
- **Findings_File**: `Review_Session` 中的 `findings.json`，遵循 `schema_version` `1.0`。
- **Stable_ID**: 形如 `CHR-`、`ITER-`、`VER-` 前缀加 `YYYYMMDD` 日期再加零填充至少 2 位的序号（例如 `CHR-20260515-001`）的跨会话稳定标识。
- **Ignore_Set**: `Repo_Facts_Collector` 与 `Safe_Check_Runner` 共享的、不应被纳入扫描的相对路径前缀集合；匹配语义为大小写不敏感的子串匹配，匹配前需将相对路径中的 `/` 规范化为 `\` 并在首尾各补一个 `\`。
- **Repo_Allowlist_File**: 受评仓库根目录下的可选文件 `.code-health-review.json`。
- **Allowed_Verb_Set**: `Tooling_Playbook` 中明确列为允许的命令动词集合（如 `build`、`test`、`lint`、`check`、`verify`、`config`、`status`、`diff`、`audit --json`、`list`）。
- **Forbidden_Verb_Set**: `Tooling_Playbook` 中明确列为禁止的动词集合（如 `run`、`up`、`deploy`、`publish`、`install -U`、`update`、`reset`、`clean`、`rm -rf`、`del /s`、`audit fix`、`docker compose up`）。
- **Schema_Version**: `Findings_File` 顶层 `schema_version` 字段，本次迭代保持 `"1.0"`。
- **Smoke_Budget**: smoke 测试整体运行时间预算，目标小于 60 秒。
- **Self_Review_Session**: 历史会话 `code-health-reports/20260515-1013-code-health-review-harness-self-review/`，CHR-20260515-001..005 已闭环，作为背景而非本轮新发现。

## Open Decisions (do not block requirements)

以下是需要决策但不阻塞需求成形的开放问题；在设计阶段需要给出明确选择并回填到对应需求中：

1. **LICENSE 选择**：MIT 或 Apache-2.0。需求 2 默认占位为 `<CHOSEN_LICENSE>`，决策落地后替换。
2. **Repo_Allowlist_File 位置**：仓库根 `.code-health-review.json` 或 `.kiro/.code-health-review.json`。需求 5 暂以仓库根为推荐位置。
3. **多语言 safe-checks 默认开关**：需求 4 当前以「检测到清单文件即默认运行」为基线（默认开启），保留在设计阶段把它改为 `-IncludeLanguageStacks` 显式开关的选项。

## Background (closed prior findings, do not re-open)

CHR-20260515-001 至 CHR-20260515-005 已在 `Self_Review_Session` 中验证关闭：绝对路径修复、PowerShell 校验脚本发现、`-WhatIf` 提示真实化、`docs/usage.md` 重复说明清理、smoke 用例 `.tmp` 残留清理。本规格不重新打开这些条目。

## Requirements

### Requirement 1: Repo-fact 自评审污染防御

**User Story:** As a harness 维护者, I want `Repo_Facts_Collector`、`Safe_Check_Runner` 与 `Smoke_Test` 默认忽略 `code-health-reports/` 及任何用户指定的报告根, so that 自评审产生的报告产物不会反过来污染下一次评审输入并破坏证据链。

#### Acceptance Criteria

1. THE Harness SHALL 在 `skills/code-health-review-harness/scripts/lib/ignore-set.ps1` 维护 `Ignore_Set` 的单一定义来源，并由 `Repo_Facts_Collector` 与 `Safe_Check_Runner` 通过 dot-source 共同引用。
2. THE `Ignore_Set` SHALL 至少包含 `\.git\`、`\node_modules\`、`\.venv\`、`\venv\`、`\dist\`、`\build\`、`\coverage\`、`\htmlcov\`、`\.pytest_cache\`、`\.tmp\`、`\tmp\` 与 `\code-health-reports\`，总条目数不超过 64；匹配语义为大小写不敏感子串匹配，应用对象为「将相对路径中的 `/` 规范化为 `\` 并在首尾各补一个 `\`」之后的字符串。
3. WHEN `Repo_Facts_Collector` 收集仓库事实, THE `Repo_Facts_Collector` SHALL 对 `manifests`、`workflows`、`docs`、`tests`、`extensionSummary`、`packageScripts` 全部六个数组按需求 1 第 2 项规则统一排除；任一数组均 SHALL NOT 包含以 `code-health-reports\` 开头的条目。
4. WHEN `Safe_Check_Runner` 扫描 `package.json` 或测试入口, THE `Safe_Check_Runner` SHALL 按需求 1 第 2 项规则排除路径，且 `results[].workingDirectory` 中均不出现位于 `code-health-reports\` 子树下的目录。
5. WHERE 用户通过参数 `-ReportRoot <path>` 声明非默认报告根, THE `Repo_Facts_Collector` 与 THE `Safe_Check_Runner` SHALL 把该路径规范化为相对仓库根的前缀，并按需求 1 第 2 项规则加入运行时忽略集合。
6. IF `-ReportRoot <path>` 指向仓库根之外或路径不存在, THEN THE 接收脚本 SHALL 以退出码 1 终止，将一条以 `ERROR: ` 前缀的诊断信息写入标准错误输出（包含原始 `-ReportRoot` 值与失败原因），且不在受评仓库内产出任何报告或事实文件。
7. WHEN `Smoke_Test` 运行, THE `Smoke_Test` SHALL 先在 `code-health-reports/smoke-ignore-test/` 下放置至少一个伪造的 `package.json`，运行 `Repo_Facts_Collector` 与 `Safe_Check_Runner`，断言两者输出中均无以 `code-health-reports\` 开头的条目；无论断言通过或失败，`Smoke_Test` SHALL 在退出前清理 `code-health-reports/smoke-ignore-test/` 目录。
8. IF `Smoke_Test` 在第 7 项任一断言上失败, THEN THE `Smoke_Test` SHALL 以退出码 1 终止，并把失败的字段名与首个违例条目以 `ERROR: ` 前缀写入标准错误输出。
9. IF 第 7 项的伪造目录或文件创建步骤本身因权限或磁盘错误失败, THEN THE `Smoke_Test` SHALL 跳过第 7 项的断言并以零退出码继续执行后续步骤，同时把跳过原因以 `WARN: ` 前缀写入标准输出。

### Requirement 2: LICENSE 落地与一致传播

**User Story:** As an 开源消费者, I want 仓库提供明确且一致的开源许可证, so that 我可以在合规前提下复用、分发和修改本 harness。

#### Acceptance Criteria

1. THE Harness SHALL 在仓库根目录提供 `LICENSE` 文件；文件首行（去除前后空白后）SHALL 等于所选许可证标准头之一（区分大小写）：`MIT License` 或 `Apache License`；版权年份 SHALL 为不小于 `2026` 且不大于运行 `Verify_Project` 当年的整数；版权人占位字面量为 `<COPYRIGHT_HOLDER>`，在发布决策前保持不变。
2. THE `Verify_Project` SHALL 把 `LICENSE` 加入其 `RequiredFiles` 列表，并在执行结构检查时验证仓库根 `LICENSE` 文件存在。
3. IF `LICENSE` 文件在仓库根缺失, THEN THE `Verify_Project` SHALL 以非零退出码终止，错误信息中至少包含字符串 `LICENSE`，且不修改任何仓库内文件。
4. THE `README.md` 「维护状态」一节 SHALL 至少包含一行同时满足两项条件的纯文本：(a) 包含所选许可证完整名称（如 `MIT License`），(b) 包含指向 `LICENSE` 文件的相对链接（`LICENSE` 或 `./LICENSE`）；该节 SHALL NOT 再保留字符串「尚未选择」。
5. THE `SECURITY.md`、`CONTRIBUTING.md` 与 `PR_Template` SHALL 各自至少一次以区分大小写的方式包含所选许可证完整名称（如 `MIT License`）。
6. WHEN `Smoke_Test` 运行, THE `Smoke_Test` SHALL 依次断言：(a) 仓库根存在 `LICENSE` 文件；(b) `README.md` 不再包含字符串「尚未选择」；(c) `SECURITY.md`、`CONTRIBUTING.md`、`PR_Template` 三个文件均出现所选许可证完整名称；任一断言失败时 `Smoke_Test` SHALL 以非零退出码终止，错误输出中标识出失败的断言编号或文件名。
7. THE `CHANGELOG.md` SHALL 在 `0.2.0` 段落以条目形式记录许可证落地事项，条目中同时包含：(a) 所选许可证完整名称；(b) 形如 `YYYY-MM-DD` 的 ISO 8601 决策日期。

### Requirement 3: 纯函数抽取与 Pester 单元测试

**User Story:** As a harness 维护者, I want 把 `Get-RelativePath`、`Test-IgnoredPath`、`ConvertTo-Slug`、`Read-VerificationRows`、`Get-PackageManager`、`Get-RunArguments` 等纯函数抽取到独立 `Lib_Module` 并配套 Pester 5 测试, so that 我可以以单元粒度验证脚本内部行为，避免回归只能依赖 smoke 测试。

#### Acceptance Criteria

1. THE Harness SHALL 在 `skills/code-health-review-harness/scripts/lib/` 下提供恰好以下 6 个文件，每个文件 SHALL 仅 dot-source 导出一个同名函数：`Get-RelativePath.ps1`、`Test-IgnoredPath.ps1`、`ConvertTo-Slug.ps1`、`Read-VerificationRows.ps1`、`Get-PackageManager.ps1`、`Get-RunArguments.ps1`。
2. THE `Repo_Facts_Collector`、`Safe_Check_Runner`、`Session_Creator`、`History_Summarizer` SHALL 通过 `. (Join-Path $PSScriptRoot 'lib/<FunctionName>.ps1')` 形式 dot-source 引用 `Lib_Module` 中的对应函数；这四个脚本顶层（不含 `lib/` 子目录）中关于这 6 个函数名的 `function` 定义数量 SHALL 等于 0。
3. THE Pester_Suite SHALL 位于仓库根 `tests/` 目录下，使用 Pester 5 的 `Describe`/`It` 结构；每个被抽取函数 SHALL 至少对应一个 `*.Tests.ps1` 文件，且每个函数 SHALL 至少包含 1 个 happy-path `It` 与 1 个 edge-case `It`；edge-case `It` SHALL 至少覆盖以下集合中一项：空字符串入参、绝对路径入参、Windows `\` 与 POSIX `/` 分隔符混用入参、缺失 `scripts` 字段的 `package.json`、不存在文件入参。
4. THE `CI_Workflow` SHALL 在 `windows-latest` runner 上的同一个 job 中新增一个步骤，命令至少包含 `Invoke-Pester` 与 `-CI` 参数，且执行顺序在 `Verify_Project` 之后；该步骤 SHALL NOT 使用 `continue-on-error: true` 或 `2>$null` 等抑制错误的修饰。
5. IF `Invoke-Pester -CI` 返回非零退出码, THEN THE `CI_Workflow` 步骤 SHALL 失败，进而导致整个 workflow 失败。
6. WHEN `Smoke_Test` 在抽取后的版本上运行, THE `Smoke_Test` SHALL 保持抽取前的所有断言全部通过，且 SHALL NOT 引入对 `tests/` 目录或 `Invoke-Pester` 的运行期依赖。
7. THE `Verify_Project` SHALL 把 `tests/` 目录与 `skills/code-health-review-harness/scripts/lib/` 加入结构检查范围；当且仅当 (a) `tests/` 至少包含一个 `*.Tests.ps1` 文件、(b) `lib/` 至少包含 6 个 `*.ps1` 文件、(c) 第 1 项列出的 6 个文件名均存在于 `lib/` 时，结构检查视为通过。
8. IF (a)、(b)、(c) 中任一条件不满足, THEN THE `Verify_Project` SHALL 以非零退出码终止，错误信息中标识首个不满足的条件。
9. WHERE 运行环境为 PowerShell 5.1 且 Pester 5 不可用, THE `CI_Workflow` SHALL 在 Pester 步骤之前显式执行 `Install-Module Pester -Scope CurrentUser -Force -SkipPublisherCheck -MinimumVersion 5.0.0`。
10. IF `Install-Module` 步骤返回非零退出码, THEN THE `CI_Workflow` 步骤 SHALL 失败，且 SHALL NOT 使用 `continue-on-error: true` 或 `2>$null` 抑制该失败。

### Requirement 4: 多语言只读校验扩展

**User Story:** As a 评审使用者, I want `Safe_Check_Runner` 在 Go、Rust、.NET、Java 项目中也能产出有意义的只读校验结果, so that 评审 PowerShell/Node/Python 之外的项目时不再得到空 `results` 数组。

#### Acceptance Criteria

1. THE `Safe_Check_Runner` SHALL 在受评仓库根开始递归扫描清单文件，最大递归深度为 5 层，且按需求 1 第 2 项的 `Ignore_Set` 规则排除目录；每条新增多语言命令默认开启（无需额外开关），单条命令的超时上限为 600 秒。
2. WHEN `Safe_Check_Runner` 检测到 `go.mod`, THE `Safe_Check_Runner` SHALL 在该 `go.mod` 所在目录依次独立运行 `go build ./...` 与 `go test ./...`，并以 `label` 前缀 `go:` 区分；两条命令的执行结果 SHALL 各自独立记录在 `results` 中。
3. WHEN `Safe_Check_Runner` 检测到 `Cargo.toml`, THE `Safe_Check_Runner` SHALL 在该目录依次独立运行 `cargo check` 与 `cargo test --no-run`，`label` 前缀为 `rust:`。
4. WHEN `Safe_Check_Runner` 检测到 `*.csproj` 或 `*.sln`, THE `Safe_Check_Runner` SHALL 在该目录运行 `dotnet build`，`label` 前缀为 `dotnet:`。
5. WHEN `Safe_Check_Runner` 检测到 `pom.xml`, THE `Safe_Check_Runner` SHALL 运行 `mvn -B -DskipTests verify`，`label` 前缀为 `maven:`。
6. WHEN `Safe_Check_Runner` 检测到 `build.gradle` 或 `build.gradle.kts` 而未检测到 `pom.xml`, THE `Safe_Check_Runner` SHALL 运行 `gradle check`，`label` 前缀为 `gradle:`。
7. IF 第 2 至第 6 项中任一外部工具（`go`、`cargo`、`dotnet`、`mvn`、`gradle`）在 `PATH` 中不存在, THEN THE `Safe_Check_Runner` SHALL 跳过该命令，并在 `results` 中以 `status` 等于 `"skipped"`、`outputTail` 包含字符串 `Command not found:` 的形式记录。
8. THE `Safe_Check_Runner` SHALL 永远不调用 `Forbidden_Verb_Set` 中的任何动词；具体而言，所有新增多语言命令的命令行 SHALL NOT 包含子串 `run `、`up`、`deploy`、`publish`、`install -U`、`update`、`audit fix`。
9. THE `Tooling_Playbook` SHALL 新增「Multi-language safe checks」小节，明文列出第 2 至第 6 项中的命令、检测条件与跳过条件。
10. WHEN `Smoke_Test` 运行时所有 `go`、`cargo`、`dotnet`、`mvn`、`gradle` 工具均不在 `PATH` 中, THE `Smoke_Test` SHALL 以零退出码通过，且 SHALL NOT 要求多语言命令实际成功执行。
11. WHERE `go`、`cargo`、`dotnet`、`mvn`、`gradle` 中任一工具在 `PATH` 中可用, THE `Smoke_Test` SHALL 要求 `Safe_Check_Runner` 对应命令的 `status` 等于 `"passed"` 或 `"skipped"` 之一；IF 该 `status` 等于 `"failed"` 或 `"error"`, THEN THE `Smoke_Test` SHALL 以非零退出码终止。

### Requirement 5: 安全命令超时与按仓库白名单

**User Story:** As a 评审运行者, I want `Safe_Check_Runner` 对所有外部命令施加可配置的超时，并支持受评仓库通过 `Repo_Allowlist_File` 声明额外的安全校验命令, so that 长时间挂起的命令不会拖垮评审流程，且仓库可以贡献自定义只读校验而不破坏安全契约。

#### Acceptance Criteria

1. THE `Safe_Check_Runner` 顶层参数 SHALL 接受 `-TimeoutSeconds <int>`，作用域为本次运行的所有命令，整数取值范围 1–86400，默认值 300；IF 传入值不在该范围内, THEN THE `Safe_Check_Runner` SHALL 以非零退出码立即终止并在错误信息中标识无效值与允许范围。
2. THE `Invoke-SafeCommand` 函数 SHALL 接受 `-TimeoutSeconds` 参数，整数取值范围与第 1 项一致；调用方未显式传入时使用顶层参数值。
3. WHEN 单个命令的运行时长达到 `TimeoutSeconds` 上限, THE `Invoke-SafeCommand` SHALL 在 5 秒内终止该子进程及其子进程树，并把该结果记录为 `status` 等于 `"timeout"`、`exitCode` 为 `null`、`outputTail` 至少包含字符串 `timed out after`。
4. THE `Safe_Check_Runner` SHALL 在被评仓库根目录读取可选文件 `.code-health-review.json`；当该文件存在且为合法 JSON 时，将其顶层数组字段 `additionalSafeChecks`（最多前 50 个元素）中每一项作为一次额外命令调度。
5. THE `Repo_Allowlist_File` 中每个 `additionalSafeChecks` 条目 SHALL 包含字段 `label`（字符串，长度 1–80）、`command`（字符串，长度 1–200）、`arguments`（字符串数组，元素数 0–32，单个元素长度 0–200）、`workingDirectory`（相对仓库根的字符串，长度 0–260）。
6. IF `additionalSafeChecks` 数组元素数超过 50, THEN THE `Safe_Check_Runner` SHALL 仅处理前 50 个元素，并在 `results` 中追加单条 `status` 等于 `"skipped"`、`label` 等于 `"repo-allowlist:overflow"`、`outputTail` 包含字符串 `exceeds 50` 的记录。
7. IF 一个 `additionalSafeChecks` 条目缺失字段、字段类型不符或字段长度/元素数超出第 5 项约束, THEN THE `Safe_Check_Runner` SHALL 拒绝该条目，并在 `results` 中以 `status` 等于 `"rejected"`、`outputTail` 包含字符串 `invalid entry` 的形式记录该条目。
8. WHEN 一个 `additionalSafeChecks` 条目的 `command` 或 `arguments` 中任一字符串包含 `Forbidden_Verb_Set` 中的子串, THE `Safe_Check_Runner` SHALL 在分配子进程或施加超时之前先做该拒绝检查，拒绝执行该条目，并以 `status` 等于 `"rejected"`、`outputTail` 包含字符串 `forbidden verb` 的形式记录。
9. IF 第 8 项的拒绝检查本身因正则故障或异常无法得出确定结果, THEN THE `Safe_Check_Runner` SHALL 默认拒绝该条目（fail-safe），同样以 `status` 等于 `"rejected"` 记录。
10. IF 一个 `additionalSafeChecks` 条目的 `workingDirectory` 经规范化后包含 `..`、为绝对路径或解析后逃逸出仓库根, THEN THE `Safe_Check_Runner` SHALL 在分配子进程之前拒绝该条目，并以 `status` 等于 `"rejected"`、`outputTail` 包含字符串 `path escape` 的形式记录。
11. IF `.code-health-review.json` 存在但不是合法 JSON, THEN THE `Safe_Check_Runner` SHALL 不抛出未捕获异常，且在结果集中追加单条 `status` 等于 `"failed"`、`label` 等于 `"repo-allowlist:parse"` 的记录，并继续运行内置探测。
12. THE `Tooling_Playbook` SHALL 新增「Per-repo allowlist」小节，明文列出 `Repo_Allowlist_File` 的字段、约束与 `Forbidden_Verb_Set` 拒绝规则。
13. WHEN `Smoke_Test` 运行, THE `Smoke_Test` SHALL 至少包含两条覆盖：其一构造一个含合法条目的 `.code-health-review.json` 并断言其结果出现在 `results` 中；其二构造一个含禁止动词的条目并断言对应记录的 `status` 等于 `"rejected"`。

### Requirement 6: 历史会话对比工具

**User Story:** As a 评审使用者, I want 一个脚本对比两个 `Review_Session` 的差异, so that 我可以快速看到维度评分变化、新开/关闭/回归/未关闭的发现，以验证迭代是否真正收敛。

#### Acceptance Criteria

1. THE Harness SHALL 在 `skills/code-health-review-harness/scripts/compare-review-sessions.ps1` 提供新脚本 `History_Comparator`。
2. THE `History_Comparator` SHALL 接受参数 `-From <sessionPath>`、`-To <sessionPath>` 与可选 `-OutputPath <path>`；WHERE `-OutputPath` 被指定, THE `History_Comparator` SHALL 仅把 Markdown 报告写入该文件（不再同时写到标准输出）；WHERE `-OutputPath` 未被指定, THE `History_Comparator` SHALL 把 Markdown 报告写入标准输出。
3. WHEN `-OutputPath` 被指定且其父目录不存在, THEN THE `History_Comparator` SHALL 以退出码 2 失败，错误信息包含父目录路径；WHEN `-OutputPath` 被指定且父目录存在, THE `History_Comparator` SHALL 以 UTF-8 无 BOM 编码覆盖写入目标文件，文件以单个换行符结尾。
4. THE `History_Comparator` 输出的 Markdown 报告 SHALL 按以下精确顺序包含五个二级标题：`## Score Deltas`、`## Newly Opened Findings`、`## Closed Findings`、`## Regressed Findings`、`## Unchanged Open Findings`；任何小节为空时，正文 SHALL 写明 `(none)`。
5. THE `History_Comparator` SHALL 把发现按其稳定 ID 在 `From`、`To` 中的状态进行如下互斥分类，集合 Active = {`open`, `in-progress`, `blocked`}，集合 Resolved = {`verified-closed`, `accepted-risk`, `superseded`}：
   - `Newly Opened Findings`: 在 `From` 中不存在，或在 `From` 中属 Resolved 集合但不属 `verified-closed`，且在 `To` 中属 Active 集合。
   - `Closed Findings`: 在 `From` 中属 Active 集合，且在 `To` 中属 Resolved 集合。
   - `Regressed Findings`: 在 `From` 中等于 `verified-closed`，且在 `To` 中属 Active 集合。
   - `Unchanged Open Findings`: 在 `From` 与 `To` 中均属 Active 集合。
6. THE `History_Comparator` 的 `Score Deltas` 小节 SHALL 解析 `From/review-report.md` 与 `To/review-report.md` 的 Score Table，对每个出现于任一报告的维度生成一行 `dimension | from | to | delta`，按维度名升序排列；缺失值以 `n/a` 表示，delta 在双方有数值时按 `to - from` 计算并保留 2 位小数（带正负号），任一侧为 `n/a` 时 delta 也为 `n/a`。
7. IF `From/review-report.md` 或 `To/review-report.md` 缺失或不含可解析的 Score Table, THEN THE `History_Comparator` SHALL 在 `Score Deltas` 小节内写入一行 `WARN: ` 前缀的说明，且不影响其他四个小节的产出与最终退出码。
8. IF `-From` 或 `-To` 指定的目录不存在或缺少 `findings.json`, THEN THE `History_Comparator` SHALL 以退出码 2 失败，错误信息包含具体路径与缺失文件名。
9. IF 任一 `findings.json` 解析失败, THEN THE `History_Comparator` SHALL 不抛出未捕获异常；脚本以退出码 3 退出，并将解析错误以 `### Parse Errors` 子节追加到输出报告末尾，五个二级标题仍 SHALL 全部出现。
10. THE `History_Comparator` 在每个发现小节中 SHALL 以 Markdown 列表项形式按稳定 ID 升序列出每条发现，每项格式为 `- <stable-id>: <title>`；当 `title` 缺失时使用 `(no title)`。
11. WHEN `Smoke_Test` 运行, THE `Smoke_Test` SHALL 在 `.tmp` 下临时构造两个最小 `Review_Session`（其中第二个含一个 `verified-closed` 的发现），运行 `History_Comparator`，断言输出 Markdown 按精确顺序包含五个二级标题，且 `Closed Findings` 小节至少含一项符合第 10 项格式的稳定 ID；运行结束后 SHALL 清理 `.tmp` 下临时构造的会话目录。

### Requirement 7: Findings JSON Schema 校验

**User Story:** As a harness 维护者, I want 一个 JSON Schema 描述 `findings.json` 的契约，并在 `Verify_Project` 中对仓库内的 `findings.json` 做轻量校验, so that schema 演进时回归可被自动捕获，且不破坏现有的 `schema_version` `1.0` 兼容。

#### Acceptance Criteria

1. THE Harness SHALL 在 `skills/code-health-review-harness/references/findings.schema.json` 提供 JSON Schema（draft 2020-12 或 draft-07，二者择一）；schema 中 SHALL 描述 `Findings_File` 顶层 required 字段 `schema_version`（string）、`review_id`（string）、`repo`（string）、`created_at`（string）、`findings`（array，允许空数组），以及每个 finding 的 required 字段 `id`（string）、`severity`（enum）、`dimension`（string）、`title`（string）、`status`（enum）；其余 finding 字段 `confidence`、`evidence`、`impact`、`recommendation`、`verification_ids`、`owner`、`notes` SHALL 为 optional。
2. THE Schema SHALL 把 `status` 限定为 `[open, in-progress, blocked, verified-closed, accepted-risk, superseded]`、`severity` 限定为 `[Critical, High, Medium, Low, Info]`，并把 `schema_version` 固定为字符串 `"1.0"`。
3. WHEN `Verify_Project` 在 PowerShell 7+ 上运行, THE `Verify_Project` SHALL 对仓库内每个 `code-health-reports/**/findings.json` 调用 `Test-Json -SchemaFile`；JSON 解析失败或 schema 违例任一发生时 `Verify_Project` SHALL 以非零退出码失败，并把违例文件路径与失败原因以 `ERROR: ` 前缀写入标准错误输出；允许校验全部通过时附带以 `WARN: ` 前缀写入标准输出的非阻塞告警。
4. WHERE 运行环境为 PowerShell 5.1, THE `Verify_Project` SHALL 跳过 schema 校验、以零退出码继续，并向标准输出写入恰好一行以 `WARN: ` 开头的告警，告警内容同时包含字符串 `Test-Json` 与 `PowerShell 7`。
5. THE `Verify_Project` SHALL 始终对 `Self_Review_Session/findings.json` 校验通过；该文件失败时脚本立即以非零退出码失败；其他 `findings.json` 失败时即使自评审文件通过，`Verify_Project` 仍 SHALL 以非零退出码失败。
6. THE `Findings_File` 的字段集合或类型 SHALL NOT 在本次迭代中发生破坏性变更；破坏性变更被定义为：移除任一 required 字段、变更已有字段类型、或收窄已有 enum 取值集合。新增字段 SHALL 为 optional，`schema_version` SHALL 保持 `"1.0"`。

### Requirement 8: 报告会话轮转

**User Story:** As a 长期使用者, I want `Session_Creator` 支持只保留最近 N 个会话、把更早的会话归档而非删除, so that `code-health-reports/` 不会无限增长，同时保留全部历史证据可追溯。

#### Acceptance Criteria

1. THE `Session_Creator` SHALL 接受可选参数 `-RetainLast <N>`，`N` 为整数取值范围 1–10000；不传该参数时，行为保持与 0.1.0 完全一致。
2. IF `-RetainLast` 传入非整数、零、负数或超过 10000, THEN THE `Session_Creator` SHALL 以非零退出码立即终止，错误信息包含字符串 `invalid -RetainLast` 与原始输入值，且不修改任何会话目录。
3. WHEN `-RetainLast <N>` 被传入且有效, THE `Session_Creator` SHALL 枚举 `<ReportsRoot>` 下所有非 `_archive` 顶层目录，按目录名降序字典排序，保留前 `N` 个为活动会话，其余 SHALL 整目录复制到 `<ReportsRoot>/_archive/<sessionName>/`。
4. WHERE `<ReportsRoot>` 下现有非 `_archive` 会话总数小于或等于 `N`, THE `Session_Creator` SHALL 跳过归档（归档数为 0）、不创建空的 `_archive/` 目录、且以零退出码继续。
5. WHEN 复制完成, THE `Session_Creator` SHALL 对源会话目录与目标 `_archive/<sessionName>/` 做递归（含全部子目录文件）字节级一致性校验；当且仅当所有文件字节匹配时 SHALL 删除源会话目录。
6. IF 任意文件未通过第 5 项一致性校验, THEN THE `Session_Creator` SHALL 保留源目录与已写入的归档副本均不变，停止后续待归档会话的处理，并以非零退出码终止，错误信息包含字符串 `archive verification failed` 与首个不一致文件的相对路径。
7. THE `Session_Creator` SHALL NOT 在任何参数组合下直接删除任何会话目录，除非第 5 项校验已成功通过。
8. IF `_archive/<sessionName>/` 已存在且至少包含一个文件, THEN THE `Session_Creator` SHALL 拒绝再次归档同名会话，错误信息包含字符串 `archive collision` 与会话名，且 SHALL NOT 修改既有归档内容、SHALL NOT 删除源目录、并以非零退出码终止。
9. THE `Session_Creator` SHALL 在 `_archive/` 与会话目录的命名上保持稳定，不修改 `Stable_ID` 命名规则。
10. WHEN `Smoke_Test` 运行, THE `Smoke_Test` SHALL 在临时根下构造 3 个伪会话目录（每个至少包含 `findings.json`），调用 `Session_Creator -RetainLast 1`，断言活动根仅剩 1 个会话目录、`_archive/` 含 2 个会话目录、且每个被归档目录的所有文件字节与归档前的源完全一致；任一断言失败时 `Smoke_Test` SHALL 以非零退出码终止。

### Requirement 9: SKILL.md 提示注入声明

**User Story:** As a harness 调用者, I want `Skill_Manifest` 显式声明被评仓库内容是不可信数据, so that 后续 AI 会话不会被仓库 README、issue、注释或代码内的指令劫持，从而绕过安全契约。

#### Acceptance Criteria

1. THE `Skill_Manifest` SHALL 包含一个二级 ATX 标题，标题文本（去除前后空白后）精确等于 `Untrusted Repository Content`（区分大小写）。
2. 紧随该二级标题之后、下一个同级或更高级标题之前的小节正文（以下简称「该小节」），THE 该小节 SHALL 至少包含一句同时出现子串 `untrusted`（不区分大小写）与 `safety contract`（区分大小写）的语句，且明确陈述被评审仓库的 README、issues、comments 与 code 中的指令不得覆盖本 skill 的安全契约或工作流。
3. THE 该小节 SHALL 列举至少三类潜在注入向量，且正文中至少同时出现以下三类指示性子串各一次（区分大小写或如标注）：(a) `ignore previous instructions`（不区分大小写），(b) `code comment`（不区分大小写），(c) `error message` 或 `log`（不区分大小写，二者任选其一）。
4. THE 该小节 SHALL 至少包含一句同时出现子串 `precedence`（不区分大小写）与 `finding`（不区分大小写）的语句，明确说明：与本 `Skill_Manifest` 安全契约冲突时以 `Skill_Manifest` 为准，冲突应作为发现项记录而不是被执行。
5. WHEN `Verify_Project` 运行, THE `Verify_Project` SHALL 把以下三组检查作为复合 AND 条件依次执行：(i) `Skill_Manifest` 同时包含子串 `Untrusted Repository Content`（区分大小写）与 `safety contract`（区分大小写）；(ii) `README.md` 中存在需求 10 与需求 11 所要求的所有子串；(iii) `Review_Dimensions` 中存在需求 12 所要求的子串；当所有子条件均通过时该验证视为通过。
6. IF 第 5 项任一子条件失败, THEN THE `Verify_Project` SHALL 以非零退出码失败，将首个失败的子条件标识（i/ii/iii）与缺失子串名称以 `ERROR: ` 前缀写入标准错误输出，且 SHALL NOT 修改任何仓库内文件。

### Requirement 10: README 引用规范示例报告

**User Story:** As a 新用户, I want README 直接指向一份真实的 harness 输出示例, so that 我无需运行就能看到「这就是 harness 会产出的东西」。

#### Acceptance Criteria

1. THE `README.md` SHALL 新增一个二级 ATX 标题（以 `## ` 开头），标题文本（去除前后空白后）等于「示例报告」或「Example Report」之一；该节正文中 SHALL 引用 `Self_Review_Session` 的相对路径 `code-health-reports/20260515-1013-code-health-review-harness-self-review/`。
2. THE 第 1 项所述小节 SHALL 至少包含 3 个深链子串，分别为 `code-health-reports/20260515-1013-code-health-review-harness-self-review/review-report.md`、`code-health-reports/20260515-1013-code-health-review-harness-self-review/findings.json` 与 `code-health-reports/20260515-1013-code-health-review-harness-self-review/iteration-plan.md`。
3. THE 第 1 项所述小节 SHALL 包含至少一句中文说明，明确该会话是 harness 自评审产生的样例（包含子串「自评审」与「样例」），且明确该报告仅作为示例（包含子串「示例」）、其中所列发现已闭环、不应被视为当前仓库的开放问题（包含子串「已闭环」或「verified-closed`）。
4. WHEN `Verify_Project` 运行, THE `Verify_Project` SHALL 按列出顺序检查 `README.md` 是否包含第 2 项所列的全部 3 个深链子串。
5. IF 第 2 项所列任一深链子串缺失, THEN THE `Verify_Project` SHALL 立即以非零退出码失败，错误信息明确指出首个缺失的子串名称。

### Requirement 11: 跨平台运行说明

**User Story:** As a macOS/Linux 用户, I want README 明确声明运行时支持矩阵, so that 我能预知本 harness 在我的环境上的可用性边界。

#### Acceptance Criteria

1. THE `README.md` SHALL 新增或更新一个二级 ATX 标题（以 `## ` 开头），标题文本（去除前后空白后）至少包含子串「Known runtime」或「运行时支持」之一。
2. 紧随第 1 项标题之后、下一个同级或更高级标题之前的小节正文（以下简称「该节」），THE 该节 SHALL 同时包含子串 `PowerShell 5.1` 与 `PowerShell 7`，并陈述 Windows + PowerShell 5.1 与 Windows + PowerShell 7 受支持。
3. THE 该节 SHALL 同时包含子串 `macOS`（区分大小写）、`Linux`（区分大小写）、`PowerShell 7`，并陈述 macOS 与 Linux 仅在 PowerShell 7 下受支持，且当前以 Windows + PowerShell 7 为参考实现。
4. THE 该节 SHALL 同时包含子串 `Bash` 与 `0.2`，并陈述 Bash 镜像（Bash 端口）不在 0.2 范围内。
5. WHEN `Verify_Project` 运行, THE `Verify_Project` SHALL 按以下顺序在 `README.md` 中检查子串是否存在：先 `PowerShell 7`，再 `PowerShell 5.1`。
6. IF 第 5 项任一子串缺失, THEN THE `Verify_Project` SHALL 以非零退出码（例如 1）立即终止，错误信息明确指出首个缺失的子串名称。
7. IF `README.md` 缺失子串 `Bash`（即第 4 项 Bash 范围声明缺失）, THEN THE `Verify_Project` SHALL 在标准输出写入一行以 `WARN: ` 前缀的告警，但 SHALL NOT 因此返回非零退出码。

### Requirement 12: 维度评分校准说明

**User Story:** As a 评审执行者, I want `Review_Dimensions` 给出每个维度上 4 分与 3 分典型证据的描述, so that 不同评审者对同一维度的打分一致性提升。

#### Acceptance Criteria

1. THE `Review_Dimensions` SHALL 新增至少一个 Markdown 标题（`##` 或 `###` 级），其文本（去除前后空白后）精确等于 `Score Calibration`（区分大小写）；不允许使用别名或译名（如 `Scoring Examples`、`Calibration Notes`、`评分校准`）替代。
2. 紧随第 1 项标题之后、下一个同级或更高级标题之前的小节内容，THE 校准小节 SHALL 为以下 12 个维度均提供校准说明：Functional and product fit、Architecture and modularity、Backend and API、Frontend and interaction、Data, migration and lifecycle、Security and permissions、Testing and quality gates、Performance and capacity、Operations and delivery、Supply chain and repository health、Documentation and maintainability、Iteration economics；允许两种合法布局：(a) 在该小节中以子标题或显式短语涵盖所有 12 个维度名；(b) 每个维度各自带有标题精确等于 `Score Calibration` 的子节。
3. THE 校准小节 SHALL 至少包含 2 个分别针对「4 分」与「3 分」的「典型证据条目」；典型证据条目被定义为：以 Markdown 列表项（`-` 或 `*` 起始）开头、随后第一个非空白字符为阿拉伯数字 `4` 或 `3`、紧随其后的字符为 `分`、`：` 或 `:` 之一。
4. THE 校准小节 SHALL 不引入新的评分档位（仍仅使用整数 0–5）。
5. WHEN `Verify_Project` 运行, THE `Verify_Project` SHALL 依次断言：(a) `Review_Dimensions` 包含子串 `Score Calibration`；(b) 至少存在 2 个起始为 `4 分`、`4：` 或 `4:` 的列表项；(c) 至少存在 2 个起始为 `3 分`、`3：` 或 `3:` 的列表项。
6. IF 第 5 项任一断言失败, THEN THE `Verify_Project` SHALL 以非零退出码终止，将失败的断言代号（a/b/c）与缺失内容描述以 `ERROR: ` 前缀写入标准错误输出。
7. THE `Review_Dimensions` 中既有的 `## Scoring Guide` 标题文本与其下的 0–5 分档定义 SHALL 保持不变；本次迭代 SHALL NOT 引入小数档位（如 3.5）或字母档位（如 A/B/C）。

### Requirement 13: 向后兼容、安全契约与确定性约束

**User Story:** As a 维护者, I want 本次迭代的所有变更不破坏既有报告会话、不放宽安全边界、不引入不确定输出, so that 升级到 0.2.0 是低风险且可重复的。

#### Acceptance Criteria

1. THE Harness SHALL 保持 `Findings_File` 顶层 `schema_version` 等于 `"1.0"` 不变；任何字段变化必须为新增可选字段。
2. WHEN `History_Summarizer` 与 `History_Comparator` 在 0.2.0 版本上读取 `Self_Review_Session/findings.json`, THE 两个脚本 SHALL 不抛出未捕获异常并以零退出码完成解析，且其输出对原有字段（`schema_version`、`review_id`、`repo`、`created_at`、`findings[*].id`、`findings[*].severity`、`findings[*].dimension`、`findings[*].title`、`findings[*].status`）的内容 SHALL 与 0.1.0 解析结果在结构等价层面保持一致（key 集合相同、对应值字符串相等）。
3. THE Harness SHALL 保持 `Stable_ID` 命名规则不变：合法 ID 形如 `<PREFIX>-<YYYYMMDD>-<NNN+>`，其中 `<PREFIX>` 取自集合 `{CHR, ITER, VER}`，`<YYYYMMDD>` 为 8 位十进制日期，`<NNN+>` 为零填充至少 2 位的非负整数（例如 `CHR-20260515-001`）。
4. THE Harness SHALL NOT 在 `Allowed_Verb_Set` 之外引入任何默认执行的命令；本次迭代中**新增**的命令路径 SHALL 同时满足 (a) 落在 `Allowed_Verb_Set` 内，与 (b) 已显式列入 `Tooling_Playbook` 的允许清单。
5. WHERE 一条命令在 0.1.0 已经存在于 `Allowed_Verb_Set` 与现有调度逻辑中, THE Harness SHALL 允许该命令继续执行而无需为本次迭代再追加 playbook 条目。
6. THE Harness SHALL 不放宽 `Skill_Manifest` 的 Command Safety Contract；新增 `Repo_Allowlist_File` 仅允许通过显式 `Forbidden_Verb_Set` 拒绝机制收紧默认行为，SHALL NOT 在 `Forbidden_Verb_Set`、`Allowed_Verb_Set` 与 `Tooling_Playbook` 三者之外引入任何新的允许集合。
7. WHEN 同一仓库快照在不同时间被 `Repo_Facts_Collector` 或 `History_Summarizer` 两次扫描, THE 两个脚本的两次输出（剔除时间戳字段集合 `{collectedAt, ranAt, Generated}` 中的字段后）SHALL 字节相同。
8. IF `Smoke_Test` 检测到第 7 项的字节比对不一致, THEN THE `Smoke_Test` SHALL 以非零退出码终止，把首个差异路径以 `ERROR: ` 前缀写入标准错误输出，且 SHALL NOT 删除两次扫描产生的输出文件。
9. THE 任一新增脚本接受外部输入字符串（如命令、参数、路径）时 SHALL 仅以 PowerShell 参数数组（如 `& $cmd @args` 或 `Start-Process -ArgumentList`）形式传入子进程，SHALL NOT 使用字符串拼接到单一命令行的形式。
10. THE 任一新增脚本 SHALL NOT 包含 `Invoke-Expression`、`iex`（作为别名调用）、`& [scriptblock]::Create(...)` 或 `cmd /c` 拼接字符串等动态求值模式；`Verify_Project` SHALL 以静态字符串扫描方式对 `Lib_Module` 与本次迭代新增脚本执行该检查，发现匹配时以非零退出码终止，错误信息包含命中文件与命中行号。
11. IF 引入任何新的外部依赖（例如新的 PowerShell 模块或 npm/Cargo/Maven 包）作为默认执行路径, THEN 引入前 SHALL 在 `Skill_Resource_Map` 中追加一条 vetting 记录，并在引入提交对应的 review session 中记录用户确认；本次迭代默认不引入新外部依赖。
12. IF 第 11 项任一前置证据缺失（vetting 记录或用户确认），THEN 相关脚本 SHALL 在运行时拒绝以默认路径调用该外部依赖，并将拒绝事件以 `status` 等于 `"rejected"` 的形式记录到对应结果集合（如 `Safe_Check_Runner` 的 `results`）。

### Requirement 14: 性能与编码非功能约束

**User Story:** As a CI 维护者, I want 升级后 smoke 测试仍在合理时间预算内完成、所有生成的文本文件保持 UTF-8 无 BOM, so that 验证流程不会成为瓶颈，且产出的 Markdown 与 JSON 在跨平台工具链下都可被正确读取。

#### Acceptance Criteria

1. WHEN `Smoke_Test` 在干净 checkout（即新克隆或执行 `git clean -fdx` 之后的工作区）上从头运行，并依次调用 `Verify_Project`、`Repo_Facts_Collector`、`Safe_Check_Runner`、`Session_Creator`、`History_Summarizer`、`History_Comparator`，THE `Smoke_Test` SHALL 在主进程启动到主进程退出之间不超过 60 秒（`Smoke_Budget`）完成；本预算仅在「干净 checkout」前提下生效，对增量本地重复运行不强制 60 秒上限。
2. IF `Smoke_Test` 在干净 checkout 上的实际耗时超过 60 秒（`Smoke_Budget`）, THEN THE `Smoke_Test` SHALL 以非零退出码终止，并在标准输出中打印实际耗时（以秒为单位，精度至少到 0.1 秒）。
3. WHEN 任一 harness 脚本（`Repo_Facts_Collector`、`Safe_Check_Runner`、`Session_Creator`、`History_Summarizer`、`History_Comparator`、`Verify_Project`、`Smoke_Test`、`Installer`、`Lib_Module/*.ps1`、`Pester_Suite/*.Tests.ps1`）写入扩展名为 `.md`、`.json`、`.txt`、`.ps1`、`.psm1`、`.psd1`、`.yml`、`.yaml` 之一的文本文件, THE 脚本 SHALL 以 UTF-8 编码写入字节序列，且写入文件的前三个字节不得为 `EF BB BF`（即不带 BOM）。
4. THE `Pester_Suite` SHALL 至少包含一条用例，断言以下两类文件的前三个字节均不等于 `EF BB BF`：(a) 至少一份 harness 脚本文件（至少覆盖 `Smoke_Test` 与 `History_Comparator` 对应的 `.ps1` 文件各一份），以及 (b) 至少一份由 `History_Comparator` 生成的 Markdown 输出文件。
5. WHEN `History_Comparator` 在任意两个会话之间运行，且每个会话各包含不超过 50 个发现, THE `History_Comparator` SHALL 在主进程启动到主进程退出之间 5 秒内完成；超过 5 秒本身不导致非零退出码。
6. WHEN `History_Comparator` 完成运行（无论会话发现数量是否超过 50）, THE `History_Comparator` SHALL 在标准输出中打印本次运行的实际耗时（以秒为单位，精度至少到 0.1 秒）以及两个会话各自的发现数量。
7. WHEN `CI_Workflow` 完成端到端 `validate` job, THE `CI_Workflow` SHALL 在 job 摘要中输出从 job 开始到完成的总耗时（以秒为单位）。
8. IF `validate` job 的总耗时超过 5 分钟（300 秒）, THEN THE `CI_Workflow` SHALL 在 job 摘要中以可被 PR 评审看到的方式标记此次运行为性能回归。
