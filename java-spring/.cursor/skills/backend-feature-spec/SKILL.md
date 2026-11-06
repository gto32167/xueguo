---
name: backend-feature-spec
version: 0.3.0
description: 为后端需求创建 docs/features/<slug> 规格工件。用户说 PRD 拆解、需求拆解、spec、propose、先写规格时触发。
---

# Backend Feature Spec

## 流程

1. 有 PRD 时先完整读取 PRD 原文，把 PRD 链接或归档路径登记为 `prd_ref`；无 PRD 时以 `discovery.md` 或需求基线为输入，`prd_ref` 写 N/A。
2. 根据用户需求生成小写短横线 `<slug>`。
3. 复制 `docs/features/_template/` 到 `docs/features/<slug>/`。
4. 更新 `proposal.md`、`spec.md`、`status.yaml`，`proposal.md` 背景写明 `prd_ref`。
5. 在 `spec.md` 中填写 Problem Statement、Success Metrics、User Stories、Acceptance Criteria、Non-Goals 和 Constraints。
6. 逐条对照 PRD 拆解：每条 PRD 条目要么映射到功能需求或验收场景，要么显式写入 Non-Goals；不允许静默丢弃或自行扩张范围。
7. 为每条成功指标使用 `SM-xxx` 编号，为每条验收标准使用唯一的 `AC-xxx` 编号，并写明验证证据。
8. 明确需求是否影响外部接口契约。
9. 按目标清晰度、路径清晰度和风险，将任务建议路由为 `SYSTEM`、`AI` 或 `HUMAN`。
10. 涉及业务语义、资金、权限、状态、删除或不可逆契约时，登记人工门禁和决策人。执行主体不替代最终人工责任人。

## Spec 迭代门禁

- Plan 发现 Spec 未声明的边界、接口、数据表、依赖或权限行为时，先回写 Spec，再重新检查 Plan。
- `tasks.md` 每项任务必须填写 `spec_refs`、`deliverable` 和 `verification`。
- `verify.md` 必须逐条回填 `AC-xxx` / `SM-xxx` 的验证结果和证据。
- `feature-analyze` 通过后才允许进入实现；实现中修改 FR、验收标准或约束时必须重新分析。
- L0/L1 轻量变更不触发本 Skill，按 `change-route` 处理。

## 交付要求

回复 feature 目录、需求范围、PRD 对照结论（已映射与进入 Non-Goals 的条目数）、待分析仓库和下一步 `【analyze】<slug>`。
