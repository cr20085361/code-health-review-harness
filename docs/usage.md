# Usage

## 安装到用户全局 skill

在项目根目录执行：

```powershell
.\scripts\install-user-skill.ps1 -Force
```

安装目标：

```text
%USERPROFILE%\.agents\skills\code-health-review-harness\
```

## 触发语

推荐使用中文触发：

```text
对当前工程做一次全面代码体检
```

也可以使用更明确的触发：

```text
请用 code-health-review-harness 对当前仓库做全维度工程检视，输出评分、优缺点和 P0/P1/P2 迭代建议
```

英文触发：

```text
Run a full code health review for this repository with architecture, security, testing, maintainability, and roadmap recommendations.
```

## Short trigger prompts

也支持更短的中文触发语，例如：

```text
代码体检一下这个仓库
帮我看下这个工程健康度
帮我看看这个仓库有没有明显问题
给这个项目做个体检
检查一下这个仓库的工程健康度
```

## 推荐输入

如果你希望报告更聚焦，可以补充：

- 当前系统类型：Web app、桌面 app、CLI、库、服务端 API。
- 重点关注：安全、性能、测试、架构、交付、前端体验。
- 允许命令：是否允许 build/test/lint/audit。
- 报告粒度：摘要版、工程详版、评分表、迭代路线。

## 输出约定

报告默认包含：

- 总评结论。
- 评分表。
- 关键优点。
- 问题与风险。
- 后续迭代路线。
- 已运行命令与结果。
- 未验证项和人工确认项。

如果你只希望在聊天中查看结果而不落盘，可在请求中加入 `chat-only output`、`仅聊天不落盘`、`不要保存报告` 或 `只在聊天里输出`。

## 资源刷新模式

当你希望扩展外部 skill 资源时，使用：

```text
给代码体检 harness 扩展 skill 资源，先搜索候选并做 vetting，不要直接安装
```

任何候选外部 skill 都必须先经过安全审查，并由用户确认后才能安装。
