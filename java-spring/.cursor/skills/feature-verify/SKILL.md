---
name: feature-verify
version: 0.2.0
description: 按变更级别执行后端最小充分验收；L2/L3 补充字段链路、编译、测试和文档检查。用户说 verify、验收、编译测试时触发。
---

# Feature Verify

## 先选验证深度

1. 读取任务或 BUG 卡的 `change_level`。
2. L0 只执行能证明局部修改正确的最小检查，并记录结果。
3. L1 执行复现对应的回归测试和受影响模块编译或测试。
4. L2/L3 执行下列完整验证清单，并按需求补充契约、环境和发布验证。

## 完整路径必做

1. 对照 `field-map.md` 核对字段链路。
2. 检查 Apifox 文档是否同步或说明无需同步原因。
3. 查找适用的项目验证配方；若为 `CANDIDATE`，先核对其适用范围和证据。
4. 进入具体子仓执行 Maven 编译或测试。
5. 搜索乱码、替代符和连续问号。
6. 记录本次验证是否形成新的验证配方候选，但不得因一次通过自动标记为 `VERIFIED`。
7. 逐条回填 `spec.md` 中的 `AC-xxx` / `SM-xxx`，每条记录验证结果、证据和未验证风险。
8. 对照 `docs/constitution.md` 检查领域落点、契约、字段链路、测试、依赖、安全和日志约束。

## 验证命令选择

- 单模块编译：`mvn -pl <module-name> -am -DskipTests compile`
- 单模块测试：`mvn -pl <module-name> -am test`
- 仓级编译：`mvn -DskipTests compile`

## 交付要求

更新 `verify.md`，说明已验证仓库、模块、命令、结果和未验证风险。
