---
name: impact-analyze
version: 0.1.0
description: 分析后端需求影响仓库、模块、接口和消费者。用户说 analyze、影响分析、落仓分析时触发。
---

# Impact Analyze

## 优先读取

1. `docs/analysis/*.md`
2. 当前业务仓 `AGENTS.md`
3. `docs/features/<slug>/proposal.md`
4. 代码中的 Controller、Feign、Thrift、Service、Mapper

## 输出

更新 `impact.md`，至少说明：

- 需求落在哪个仓和模块。
- 入口接口在哪里。
- DTO、枚举、Mapper、Service 调用链。
- 其他仓消费者是否受影响。
- 是否已有相似实现可复用。

## 门禁

影响分析未完成时，不进入实现。
