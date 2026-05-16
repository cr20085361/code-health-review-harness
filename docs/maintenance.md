# Maintenance Guide

## 版本策略

建议采用语义化版本：

- `0.x`：harness 仍在快速迭代。
- `1.0.0`：触发语、报告结构和安全边界稳定。
- patch：修复脚本、错别字、文档小问题。
- minor：新增维度、模板或可选脚本。
- major：改变默认流程、权限边界或报告契约。

## 发布前检查

```powershell
.\scripts\verify-project.ps1
```

检查点：

- skill 文件夹名与 `SKILL.md` 的 `name` 一致。
- 必要 references 和 scripts 存在。
- GitHub 模板存在。
- README、CHANGELOG、SECURITY、CONTRIBUTING 存在。

## 扩展规则

新增标准或 skill 资源时：

1. 先写入 `references/skill-resource-map.md`。
2. 说明适用维度、触发场景和风险。
3. 如果涉及外部 skill，必须先经过 vetting。
4. 不把长篇标准全文复制进 SKILL.md。

## 兼容性

脚本应优先兼容 Windows PowerShell 5.1，因为该 harness 的首要使用环境是 Windows + VS Code。

命令写法避免依赖 Bash 特性；PowerShell 中不要使用 `&&`。
