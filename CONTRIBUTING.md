# Contributing

感谢维护 `code-health-review-harness`。这个项目的目标是让工程代码体检稳定、可重复、可证据化，而不是追求一次性的大而全结论。

## 贡献原则

- 保持 skill 主入口简洁，把详细规则放在 `references/`。
- 新增检视维度时，必须说明触发条件、证据类型、常见风险和建议形态。
- 新增脚本时，默认只读或验证性质；任何可能修改用户仓库的行为必须默认关闭。
- 不自动安装外部 skill。候选 skill 必须先经过安全审查，再由用户确认。
- 报告模板必须保留“未验证项”和“需要人工确认项”，不要把未知写成确定结论。

## 本地验证

```powershell
.\scripts\verify-project.ps1
```

如需安装到用户全局 skills：

```powershell
.\scripts\install-user-skill.ps1 -Force
```

## Pull Request 要求

- 说明变更动机和影响范围。
- 若修改 `SKILL.md`，说明是否影响触发语或权限边界。
- 若修改脚本，说明命令副作用和安全边界。
- 若修改报告模板，给出一段预期输出示例或结构说明。
