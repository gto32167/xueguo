---
name: feature-verify
version: 0.1.0
description: 执行后端 L1 验收：字段链路、编译、测试和文档检查。用户说 verify、验收、编译测试时触发。
---

# Feature Verify

## L1 必做

1. 对照 `field-map.md` 核对字段链路。
2. 检查 Apifox 文档是否同步或说明无需同步原因。
3. 进入具体子仓执行 Maven 编译或测试。
4. 搜索乱码、替代符和连续问号。

## 验证命令选择

- 单模块编译：`mvn -pl <module-name> -am -DskipTests compile`
- 单模块测试：`mvn -pl <module-name> -am test`
- 仓级编译：`mvn -DskipTests compile`

## 交付要求

更新 `verify.md`，说明已验证仓库、模块、命令、结果和未验证风险。
