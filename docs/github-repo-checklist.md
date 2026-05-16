# GitHub Repository Checklist

建仓前建议检查：

- [ ] 仓库名使用 `code-health-review-harness`。
- [ ] README 能说明项目用途、安装方式和触发语。
- [ ] `skills/code-health-review-harness/SKILL.md` 可被复制到用户全局 skills。
- [ ] 已运行 `.\scripts\verify-project.ps1`。
- [ ] 已决定并添加正式 LICENSE。
- [ ] 已设置默认分支保护策略。
- [ ] 已启用 GitHub Actions。
- [ ] 已启用 Dependabot 或其他依赖更新工具。
- [ ] 已检查仓库中没有 token、私钥、客户数据或本地路径敏感信息。
- [ ] 已在首个 release note 中写明安全边界。

建议仓库描述：

```text
Evidence-based code health review harness for full-dimensional software engineering audits.
```

建议 topics：

```text
code-review, software-architecture, engineering-audit, security-review, quality-assurance, ai-agent-skill
```
