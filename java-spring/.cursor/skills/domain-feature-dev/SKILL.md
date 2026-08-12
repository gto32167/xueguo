---
name: domain-feature-dev
version: 0.1.0
description: 按规格实现后端领域功能最小必要改动。用户说 implement、实现后端功能时触发。
---

# Domain Feature Dev

## 实现前检查

1. `impact.md` 已说明目标仓库和模块。
2. `contracts.md` 已说明契约变化。
3. `field-map.md` 已说明字段链路。

## 实现原则

- 最小必要改动。
- 不把领域规则放入 `HiStore-gw`。
- 新增或修改类、字段、方法时补中文注释。
- 修改 Spring 托管类依赖时保持单一生产构造器。
- 新增字段默认补针对性测试。

## 实现后

更新 `tasks.md` 和 `verify.md`。
