# Report Template

Use this structure for the final report. Keep headings in Chinese by default.

## 总评结论

- 健康度：`优秀 / 良好 / 可用但有风险 / 高风险 / 无法判断`
- 一句话结论：
- 最大优势：
- 最大风险：
- 最优先的三件事：

## 评分表

| 维度 | 分数 0-5 | 置信度 | 主要证据 | 扣分原因 |
|---|---:|---|---|---|
| 功能与产品适配 |  |  |  |  |
| 架构与模块化 |  |  |  |  |
| 后端/API |  |  |  |  |
| 前端/交互 |  |  |  |  |
| 数据与迁移 |  |  |  |  |
| 安全与权限 |  |  |  |  |
| 测试与质量门禁 |  |  |  |  |
| 性能与容量 |  |  |  |  |
| 运维与交付 |  |  |  |  |
| 供应链与仓库健康 |  |  |  |  |
| 文档与可维护性 |  |  |  |  |
| 迭代经济性 |  |  |  |  |

## 关键优点

List strengths with evidence and why they matter.

## 主要问题与风险

Order by severity.

For each finding:

```text
Severity:
Evidence:
Impact:
Recommendation:
Verification:
Confidence:
```

## 后续迭代建议

### P0

Must address soon because it protects data, security, production reliability, or core workflows.

### P1

High value improvements that reduce debt, improve verification, or unblock feature delivery.

### P2

Nice-to-have, polish, documentation, optimization, or future maturity work.

## 已运行验证

| Command | Working Directory | Exit Code | Result |
|---|---|---:|---|

## 未验证项

List anything skipped because of missing dependencies, environment constraints, unsafe side effects, or time.

## 需要人工确认

List product decisions, risk acceptance, production assumptions, secret/config ownership, and organization policies that cannot be inferred from code.
