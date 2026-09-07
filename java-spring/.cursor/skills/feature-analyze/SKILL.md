---
name: feature-analyze
version: 0.1.0
description: 在实现前检查 Spec、Plan、Tasks、Verify 和 Constitution 的一致性，发现 Spec 漂移、越权实现和未覆盖验收标准。用户说 analyze、Spec 评审或 ready 前触发。
---

# Feature Analyze

## 适用范围

适用于 L2/L3 Feature。L0/L1 小修复走 `change-route`，不要求创建完整 Feature 工件。

## 必读工件

读取 `docs/features/<slug>/proposal.md`、`spec.md`、`design.md`、`tasks.md`、`verify.md`、`field-map.md` 和 `docs/constitution.md`。存在 `e2e.md`、`capability-map.md` 时一并读取。

## 检查矩阵

1. `spec.md` 必须包含 Problem Statement、Success Metrics、User Stories、Acceptance Criteria、Non-Goals 和 Constraints。
2. Success Metrics 使用唯一 `SM-xxx` 编号；Acceptance Criteria 使用唯一 `AC-xxx` 编号，不能重复或为空。
3. `tasks.md` 每个任务必须有 `spec_refs`、独立 `deliverable` 和 `verification`，且引用真实的 `AC-xxx` 或 `SM-xxx`。
4. `verify.md` 必须逐条覆盖 Spec 中的 `AC-xxx` / `SM-xxx`，每条都有结果和证据；未验证项必须登记风险。
5. 每条 AC 至少关联一个任务和一个验证项；没有映射时为 CRITICAL。
6. Plan/design 中新增的接口、数据表、依赖、权限、状态行为和部署步骤必须出现在 Spec 的 Constraints、Acceptance Criteria 或明确的范围内；否则为 CRITICAL。
7. 对照 `docs/constitution.md` 检查领域落点、DTO 字段链路、测试、依赖、安全、日志和 Apifox 约束；违反原则为 CRITICAL，明确 N/A 原因为 WARNING。
8. Plan 暴露 Spec 遗漏时，状态为 `NEEDS_SPEC_REVISION`，禁止进入实现；修改 Spec 后必须重新执行本 Skill。

## 输出

```markdown
## Feature Analyze: <slug>

| 检查项 | 结果 | 说明 |
|---|---|---|
| 六要素 | pass/fail | |
| AC/SM 编号 | pass/fail | |
| spec -> tasks | pass/fail | |
| tasks -> verify | pass/fail | |
| AC -> 测试/证据 | pass/fail | |
| Constitution | pass/warn/fail | |
| WHAT/HOW | pass/fail | |
| Spec 漂移风险 | pass/warn/fail | |

**CRITICAL:** 0 | **WARNING:** n
**Verdict:** PASS / FAIL / NEEDS_SPEC_REVISION
```

CRITICAL 大于 0 时禁止将 `status.yaml` 标记为 `ready`，也禁止开始实现。

## 自动检查

在业务仓执行：

```powershell
powershell -ExecutionPolicy Bypass -File .cursor/skills/scripts/feature-check.ps1 -FeatureRoot docs/features/<slug> -BaseRef <实现前基线提交>
```

未提供 `-BaseRef` 时，脚本只检查文档映射和必填结构；提供基线提交后，还会检查 Java、POM、SQL 和应用配置发生变化时是否同步更新对应 Feature Spec。脚本不替代代码 Review、测试或人工决策。
