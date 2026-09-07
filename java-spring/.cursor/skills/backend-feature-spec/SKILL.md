---
name: backend-feature-spec
version: 0.2.0
description: 为后端需求创建 docs/features/<slug> 规格工件。用户说 spec、propose、先写规格时触发。
---

# Backend Feature Spec

## 流程

1. 根据用户需求生成小写短横线 `<slug>`。
2. 复制 `docs/features/_template/` 到 `docs/features/<slug>/`。
3. 更新 `proposal.md`、`spec.md`、`status.yaml`。
4. 在 `spec.md` 中填写 Problem Statement、Success Metrics、User Stories、Acceptance Criteria、Non-Goals 和 Constraints。
5. 为每条成功指标使用 `SM-xxx` 编号，为每条验收标准使用唯一的 `AC-xxx` 编号，并写明验证证据。
6. 明确需求是否影响外部接口契约。
7. 按目标清晰度、路径清晰度和风险，将任务建议路由为 `SYSTEM`、`AI` 或 `HUMAN`。
8. 涉及业务语义、资金、权限、状态、删除或不可逆契约时，登记人工门禁和决策人。执行主体不替代最终人工责任人。

## Spec 迭代门禁

- Plan 发现 Spec 未声明的边界、接口、数据表、依赖或权限行为时，先回写 Spec，再重新检查 Plan。
- `tasks.md` 每项任务必须填写 `spec_refs`、`deliverable` 和 `verification`。
- `verify.md` 必须逐条回填 `AC-xxx` / `SM-xxx` 的验证结果和证据。
- `feature-analyze` 通过后才允许进入实现；实现中修改 FR、验收标准或约束时必须重新分析。
- L0/L1 轻量变更不触发本 Skill，按 `change-route` 处理。

## 交付要求

回复 feature 目录、需求范围、待分析仓库和下一步 `【analyze】<slug>`。
