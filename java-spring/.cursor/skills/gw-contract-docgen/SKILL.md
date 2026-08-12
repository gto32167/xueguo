---
name: gw-contract-docgen
version: 0.1.0
description: 同步 HiStore-gw Apifox OpenAPI 和 mock 示例。用户说 Apifox、网关文档、mock 示例时触发。
---

# GW Contract Docgen

## 流程

1. 确认本次变化是否影响 `HiStore-gw` 外部接口契约。
2. 更新 `HiStore-gw/docs/apifox/*.zh.openapi.json`。
3. 更新 `HiStore-gw/docs/apifox/*.mock-examples.json`。
4. 为子级字段补中文解释。
5. 为关键字段补 example。
6. 为稳定字段补 required。
7. 为状态或类型字段补枚举说明。

## 不更新文档的情况

如果不影响外部接口契约，交付说明必须写明原因。
