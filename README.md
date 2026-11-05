# Xueguo Agent Framework

Xueguo 是一套面向 Java 8、Spring 和 Maven 多模块项目的 Agent 研发协作框架，也是 Rules、Skills、研发模板和工作流工具的权威源。

它通过需求基线、变更控制、风险分级、项目记忆和验证门禁，让 Agent 在不同账号、模型、会话和项目之间恢复工作节点，并让需求、实现、测试、复盘和发布保持可追溯。

框架仓只维护跨项目复用的能力，不承载业务代码、客户凭据或某一个项目的业务规则。

## 当前版本

| 平台 | `kernelVersion` | `bundleVersion` | 发布日期 | 变更明细 |
|---|---:|---:|---|---|
| Java Spring | **1.5.0** | **1.5.0** | 2026-10-16 | [CHANGELOG.md](CHANGELOG.md) |

1.5 在 1.4 的任务状态机和工作流编排器基础上，把 BUG 修复从"静态分析"升级为"接口探针优先"：

- BUG 修复阶段拿到测试环境 token 后，先用真实接口复现 BUG、核对前端必填字段，修复后重放同一探针回归；源码推断与接口返回冲突时以接口为准。
- 探针 token 只在会话内存和脚本环境变量中流转，证据自动脱敏；只读探针优先，非只读探针必须通过人工门禁。

完整研发流程保持不变：

```text
需求发现 -> 执行路由 -> 需求基线 -> 变更控制 -> 状态机门禁
        -> TDD/BUG 验证 -> 复盘沉淀 -> 并行协调 -> 选择性发布
```

- 任务按确定性、不确定性和风险路由到 SYSTEM、AI 或 HUMAN，最终责任始终由人承担。
- 变更按 L0-L3 分级，小范围修复采用轻量记录和最小验证，跨模块、契约、数据或高风险变化进入完整 Spec 流程。
- L2/L3 功能通过 `AC-xxx` 验收标准和 `SM-xxx` 成功指标连接 Spec、任务、验证和测试。
- 项目记忆从候选态开始，经过代码、测试或人工确认后才能晋级为已验证知识。
- 会话上下文达到配置阈值后先生成结构化检查点，再由宿主创建新会话继续任务；默认阈值为 `260000` token。

## 文档

| 文档 | 说明 |
|---|---|
| [框架架构](docs/framework-architecture.md) | 分层、核心能力、权威边界和非目标 |
| [后端黄金路径](docs/backend-golden-path.md) | Java Spring 契约字段变更的标准研发路径 |
| [风险分级](docs/change-risk-routing.md) | L0-L3 变更级别与最小充分流程 |
| [需求与变更](docs/requirements-and-changes.md) | 需求发现、基线和变更控制 |
| [BUG 验证](docs/bug-verification.md) | BUG 复现、验证分层和证据要求 |
| [接口探针](docs/api-probe.md) | BUG 修复的接口复现、token 管理和探针证据 |
| [工作流编排器](docs/workflow-runner.md) | 任务创建、状态推进、门禁、验证和收尾命令 |
| [并行开发与发布](docs/parallel-development-and-release.md) | 冲突登记、任务隔离和选择性发布 |
| [会话上下文](docs/context-management.md) | Token 预算、检查点和会话轮转 |
| [版本与升级](docs/versioning-and-upgrades.md) | 语义化版本、文件所有权、升级与回退策略 |
| [自举验证](docs/dogfooding.md) | 使用 Xueguo 验证和演进 Xueguo |
| [平台文档索引](java-spring/docs/README.md) | Constitution、Feature Spec 和测试文档入口 |

## 目录

```text
xueguo/
├── java-spring/          # Java Spring 平台包：Rules、Skills、SDD 与测试规范
│   ├── .cursor/
│   │   ├── rules/
│   │   └── skills/
│   └── docs/
├── templates/            # 需求、变更、任务、BUG、发布、记忆和状态模板
├── projects/             # 中央项目空间说明，不存放业务代码
├── docs/                 # 架构、流程、升级和使用文档
├── tools/                # 安装、升级、编排和框架校验脚本
├── AGENTS.md             # 本仓库的 Agent 协作规则
├── CHANGELOG.md          # 版本变更记录
└── VERSION               # 当前框架版本
```

## 安装到业务项目

### 1. 获取框架仓库

```powershell
git clone https://github.com/gto32167/xueguo.git
Set-Location .\xueguo
```

### 2. 预览安装位置

```powershell
powershell -ExecutionPolicy Bypass -File tools\install.ps1 `
  -Target E:\path\to\business-repo `
  -ProjectId example-project `
  -WhatIf
```

### 3. 执行安装

```powershell
powershell -ExecutionPolicy Bypass -File tools\install.ps1 `
  -Target E:\path\to\business-repo `
  -ProjectId example-project
```

默认在目标业务仓的同级目录创建 `xueguo-projects/<project-id>/`。如需指定中央项目空间，可增加：

```powershell
-ProjectSpace E:\path\to\xueguo-projects
```

安装完成后，业务仓会获得：

| 位置 | 内容 | 所有权 |
|---|---|---|
| `.cursor/rules/` | Java Spring 通用规则 | 框架维护 |
| `.cursor/skills/` | 需求、分析、开发、验证与复盘 Skills | 框架维护 |
| `.agent-workflow/xueguo.ps1` | 工作流编排器 | 框架维护 |
| `.agent-workflow/config.yaml` | 项目标识、项目空间和上下文预算 | 业务项目维护 |
| `xueguo-projects/<project-id>/` | 需求、任务、发布、记忆和状态索引 | 业务项目维护 |

安装工具不会覆盖已存在的 `.agent-workflow/config.yaml`，也不会把业务规则写入框架内核。

## 框架升级

先更新本地框架仓，再在框架仓根目录预检业务项目：

```powershell
git pull

powershell -ExecutionPolicy Bypass -File tools\upgrade.ps1 `
  -Target E:\path\to\business-repo `
  -Check
```

确认新增和更新列表后，去掉 `-Check` 执行升级：

```powershell
powershell -ExecutionPolicy Bypass -File tools\upgrade.ps1 `
  -Target E:\path\to\business-repo
```

升级只同步框架维护的 `.cursor/rules/`、`.cursor/skills/` 和 `.agent-workflow/xueguo.ps1`。项目配置、需求基线、任务、发布记录、项目空间和环境凭据不会被删除或覆盖。

## 业务项目

业务代码始终保存在各自的 Git 仓库中。Xueguo 只向业务仓安装协作入口，并通过中央项目空间保存跨会话的轻量索引：

```text
Xueguo 框架仓
  -> 业务仓 .cursor/ + .agent-workflow/
  -> 中央项目空间 xueguo-projects/<project-id>/
  -> 业务仓源码、测试与项目配置
```

中央项目空间保存当前需求基线、变更单、任务状态、关键决策、验证证据索引、发布清单和经过筛选的项目记忆；不保存聊天全文、完整构建日志、临时文件、凭据或业务代码副本。

## 在业务仓中使用

安装后可在业务仓根目录通过编排器创建任务并推进状态：

```powershell
powershell -ExecutionPolicy Bypass -File .agent-workflow\xueguo.ps1 `
  -Command new -TaskId 1001 -Title "修复订单查询" -ChangeLevel L1

powershell -ExecutionPolicy Bypass -File .agent-workflow\xueguo.ps1 `
  -Command next -TaskFile tasks\TASK-1001.yaml
```

Agent 也可以使用以下入口话术：

```text
【需求发现】整理客户问题和目标，不急着写代码
【需求基线】确认当前有效版本
【BUG验证】读取 BUG，token 可用时先用接口探针复现，再制定验证层级 L1-L5 计划
【并行协调】登记冲突范围和发布边界
【verify】执行当前任务的最小可信验证
【learn】复盘任务并沉淀可验证记忆
```

完整命令和门禁规则见 [Workflow Runner](docs/workflow-runner.md)。

## 开发与校验

修改框架后，在仓库根目录执行：

```powershell
powershell -ExecutionPolicy Bypass -File tools\validate.ps1
```

验证通过后应输出：

```text
PASS: Xueguo Framework 1.5.0
```
