# 后端验收分层

| 层级 | 名称 | 内容 | 是否必做 |
|---|---|---|---|
| L1 | 静态与编译门禁 | 字段链路、文档、模块编译、单测 | 必做 |
| L2 | 接口探针 | 测试环境 curl 或接口调用验证 JSON 结构 | 按环境执行 |
| L3 | 跨仓联调 | 前端、网关、领域服务、外部依赖共同验证 | 按需求执行 |

## Maven 验证原则

必须进入具体子仓执行 Maven。工作区根目录不是 Maven 父工程。

常用命令：

```bash
mvn -pl <module-name> -am -DskipTests compile
mvn -pl <module-name> -am test
mvn -DskipTests compile
```

交付说明必须写明已验证仓库、已验证模块、未执行验证项和原因。
