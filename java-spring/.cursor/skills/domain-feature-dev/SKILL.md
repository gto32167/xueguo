---
name: domain-feature-dev
version: 0.1.0
description: 按规格实现后端领域功能最小必要改动。用户说 implement、实现后端功能时触发。
---

# Domain Feature Dev

## 流程深度

读取 `change_level`。L0/L1 允许跳过完整 Spec、Impact 和契约文档，但必须遵守轻量变更记录、回归测试和最小验证要求；L2/L3 按以下完整检查执行。

## 实现前检查

1. L2/L3：`impact.md` 已说明目标仓库和模块。
2. L2/L3：`contracts.md` 已说明契约变化。
3. L2/L3：`field-map.md` 已说明字段链路。
4. L0/L1：轻量变更记录或 BUG 卡已说明范围、根因和验证方式。

## 实现原则

- 最小必要改动。
- 不把领域规则放入 `HiStore-gw`。
- 新增或修改类、字段、方法时补中文注释。
- 修改 Spring 托管类依赖时保持单一生产构造器。
- 新增字段默认补针对性测试。

## 实现后

更新 `tasks.md` 和 `verify.md`。
