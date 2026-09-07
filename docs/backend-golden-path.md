# 后端契约字段变更黄金路径

## 适用场景

适用于新增或修改后端接口返回字段、请求字段、共享 DTO 字段、网关聚合字段和 Apifox 文档的任务。

## 标准流程

```text
bootstrap -> spec -> analyze -> contract -> implement -> verify -> finish
```

该路径适用于 L2/L3 契约变更。L0/L1 局部修复使用 `docs/change-risk-routing.md` 的轻量路径；一旦发现共享字段、消费者或接口影响，立即升级到本路径。

## 必查链路

| 层级 | 检查内容 |
|---|---|
| 数据源 | Mapper、DO、外部服务返回、领域对象 |
| 领域服务 | Service、BO、转换器、默认空对象 |
| 契约层 | Request、Response、DTO、Feign、Thrift、Enum |
| 网关层 | 聚合对象、字段复制、fallback、权限和登录态 |
| 文档层 | Apifox OpenAPI、mock 示例、required、example、枚举说明 |

## 验收口径

验证层级 L1 必做：字段链路检查、受影响模块编译、针对性测试或测试风险说明。

L2 按环境执行：curl 或接口工具验证测试环境 JSON 结构。

L3 按需求执行：前端、网关、领域服务和外部依赖联合验证。
