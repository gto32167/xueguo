---
name: backend-feature-spec
version: 0.1.0
description: 为后端需求创建 docs/features/<slug> 规格工件。用户说 spec、propose、先写规格时触发。
---

# Backend Feature Spec

## 流程

1. 根据用户需求生成小写短横线 `<slug>`。
2. 复制 `docs/features/_template/` 到 `docs/features/<slug>/`。
3. 更新 `proposal.md`、`spec.md`、`status.yaml`。
4. 明确需求是否影响外部接口契约。

## 交付要求

回复 feature 目录、需求范围、待分析仓库和下一步 `【analyze】<slug>`。
