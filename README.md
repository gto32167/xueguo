# Xueguo Agent Framework

跨项目复用的 Agent 研发协作框架。1.0 首先提供 Java Spring 多仓后端适配包，后续可增加其他技术栈适配包。

## 一句话介绍

这套框架通过需求基线、变更控制、Rules、Skills 和验证模板，帮助 Agent 在不同账号、模型、会话和项目之间恢复工作节点，并让需求、实现、测试和发布保持可追溯。

## 1.0 范围

1.0 包含：

```text
需求发现 -> 需求基线 -> 变更控制 -> TDD/BUG 验证 -> 并行协调 -> 选择性发布
```

## 平台目录

| 目录 | 说明 |
|---|---|
| `java-spring/` | Java 8、Spring、Maven 多模块后端规则和 Skills |
| `templates/` | 需求、任务、BUG、发布和并行协调模板 |
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
【BUG验证】读取 TAPD BUG 并制定 L1-L5 验证计划
【并行协调】登记冲突范围和发布边界
【verify】执行当前任务的最小可信验证
```
