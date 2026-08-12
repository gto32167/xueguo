---
name: contract-change
version: 0.1.0
description: 设计 DTO、Feign、Thrift、GW、Apifox 字段链路。用户说 contract、字段、DTO、接口变更时触发。
---

# Contract Change

## 流程

1. 读取 `impact.md` 和 `spec.md`。
2. 搜索字段、接口、DTO、Feign、Thrift 和网关响应对象。
3. 更新 `contracts.md`。
4. 更新 `field-map.md`。
5. 涉及 `HiStore-gw` 外部契约时，衔接 `gw-contract-docgen`。

## 字段链路

必须覆盖数据源、领域对象、服务响应、网关响应和 Apifox 文档。
