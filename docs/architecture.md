# Architecture

## 设计目标

`code-health-review-harness` 采用“仓库工程 + 可安装 skill 包”的双层结构：

- 仓库根目录用于 GitHub 长期维护、文档、脚本、模板和版本管理。
- `skills/code-health-review-harness/` 是可复制到全局 skills 的干净 skill 包。

这样既能满足长期维护，又不会让全局 skill 本体加载过多 GitHub 管理文档。

## 运行模型

```text
User request
  -> SKILL.md trigger
  -> Preflight and scope
  -> Repository fact collection
  -> Optional safe checks
  -> Dimension-by-dimension review
  -> Evidence-based scoring
  -> Roadmap and final report
```

## Progressive Loading

`SKILL.md` 只保存必要流程和导航，详细内容按需读取：

- `references/review-dimensions.md`：检查维度。
- `references/evidence-rules.md`：证据、严重级别、置信度。
- `references/tooling-playbook.md`：命令白名单和技术栈命令。
- `references/report-template.md`：报告格式。
- `references/skill-resource-map.md`：外部标准和可复用 skills。

## 脚本边界

脚本只做事实采集和验证命令编排，不做代码修改：

- `collect-repo-facts.ps1`：读取仓库结构、manifest、CI、部署和测试入口。
- `run-safe-checks.ps1`：按白名单运行 build/test/lint/audit 命令。

任何可能修改项目状态的命令都不得默认执行。
