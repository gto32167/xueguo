# Java Spring 后端 Skills 索引

## 黄金路径

```text
【bootstrap】->【spec】->【analyze】->【contract】->【implement】->【verify】->【finish】
```

该路径用于 L2/L3 变更。L0/L1 先使用 `change-route` 选择轻量记录和最小验证，发现影响扩大后再升级到完整路径。

## 路由表

| 用户意图 | Skill |
|---|---|
| bootstrap、扫描项目约定 | `project-bootstrap` |
| 分级、小 BUG、轻量流程 | `change-route` |
| spec、先写规格、propose | `backend-feature-spec` |
| analyze、Spec 一致性、ready 前检查 | `feature-analyze` |
| analyze、影响分析、落仓分析 | `impact-analyze` |
| contract、字段、DTO、接口变更 | `contract-change` |
| implement、实现后端功能 | `domain-feature-dev` |
| Apifox、网关文档、mock 示例 | `gw-contract-docgen` |
| verify、验收、编译测试 | `feature-verify` |
| finish、交付、收尾 | `feature-finish` |

## 质量红线

- 未分析仓库和模块落点，不进入实现。
- L2/L3 未通过 `feature-analyze`，不将 Feature 标记为 ready 或进入实现。
- 未核对字段链路，不声明字段透传完成。
- 涉及 `HiStore-gw` 外部契约变化，未同步 Apifox 或未说明原因，不交付。
- 未进入具体子仓执行 Maven，不声明编译通过。
