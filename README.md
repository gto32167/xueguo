# Xueguo Agent Framework

跨项目复用的 Agent 研发协作框架。1.3 在 1.2 的项目记忆、执行路由、复盘沉淀、团队共同上下文和会话预算基础上，增加按风险分级的最小充分研发流程。

## 一句话介绍

这套框架通过需求基线、变更控制、Rules、Skills、项目记忆和验证模板，帮助 Agent 在不同账号、模型、会话和项目之间恢复工作节点，并让需求、实现、测试、复盘和发布保持可追溯。

## 1.3 范围

1.3 包含：

```text
需求发现 -> 执行路由 -> 需求基线 -> 变更控制 -> TDD/BUG 验证 -> 复盘沉淀 -> 并行协调 -> 选择性发布
```

任务按确定性、不确定性和风险路由到 SYSTEM、AI 或 HUMAN，但最终责任始终由人承担。项目记忆默认从候选态开始，经过证据或人工确认后才能晋级。

变更先按 L0-L3 分级：小范围修复使用轻量记录和最小验证，跨模块、契约、数据或高风险变化才进入完整 Spec 流程；实施中发现影响扩大时必须升级级别。

会话上下文达到 `.agent-workflow/config.yaml` 的 `context_management.rollover_threshold_tokens` 后，Agent 必须先生成结构化检查点，再由宿主创建新会话继续同一任务。默认阈值为 `260000` token；详见 `docs/context-management.md`。

## 平台目录

| 目录 | 说明 |
|---|---|
| `java-spring/` | Java 8、Spring、Maven 多模块后端规则和 Skills |
| `templates/` | 需求、任务、BUG、发布、记忆、复盘、状态和并行协调模板 |
| `projects/` | 项目级中央记忆空间说明，不放业务代码 |
| `docs/` | 框架架构、升级策略和使用说明 |
| `tools/` | 安装、升级和校验脚本 |

## 首次安装

在目标业务仓执行：

```powershell
powershell -ExecutionPolicy Bypass -File tools/install.ps1 `
  -Target E:\path\to\business-repo `
  -ProjectId example-project
```

安装只写入框架入口文件和 `.agent-workflow/config.yaml`，项目任务和配置不会被覆盖。

## 框架升级

```powershell
powershell -ExecutionPolicy Bypass -File tools/upgrade.ps1 `
  -Target E:\path\to\business-repo `
  -Check
```

确认报告后去掉 `-Check` 执行升级。升级工具只更新框架托管的 `.cursor/rules` 和 `.cursor/skills`，不会删除需求基线、任务、发布记录、项目空间或项目配置。

## 业务仓使用话术

```text
【需求发现】整理客户问题和目标，不急着写代码
【需求基线】确认当前有效版本
【BUG验证】读取 TAPD BUG 并制定验证层级 L1-L5 计划
【并行协调】登记冲突范围和发布边界
【verify】执行当前任务的最小可信验证
【learn】复盘任务并沉淀可验证记忆
```
