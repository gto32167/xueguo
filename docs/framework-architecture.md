# Xueguo Agent Framework 1.3 架构

## 定位

Xueguo 是跨项目复用的 Agent 研发协作框架。框架仓只维护通用规则、模板、工具和版本说明；业务项目的任务记忆、需求基线、发布记录和环境状态由项目空间单独维护。

## 分层

```text
通用内核
  -> 平台适配包（java-spring）
  -> 项目配置（业务仓 .agent-workflow/config.yaml）
  -> 项目空间（本仓 projects/<project-id>/）
  -> 业务代码仓
```

## 核心能力

| 能力 | 作用 | 1.3 形态 |
|---|---|---|
| 需求发现 | 识别问题、价值、替代方案和风险 | Markdown 模板 |
| 需求基线 | 保留有效版本，避免静默覆盖 | `CURRENT.yaml` + baselines |
| 变更控制 | 记录不可逆或方向性变化 | Change Request 模板 |
| 不确定性管理 | 区分协议未知和业务语义未知 | 依赖成熟度与风险字段 |
| TDD | 先写可观察行为测试 | Java Spring 规则 |
| BUG 验证 | 分层验证和证据回填 | 验证计划模板 |
| 图谱协作 | 加速调用链和影响分析 | codebase-memory-mcp 集成 |
| 并行开发 | 任务隔离、冲突登记和选择性发布 | 协调模板 |
| 框架升级 | 保留项目配置和任务数据 | `upgrade.ps1` |
| 执行路由 | 按确定性、不确定性和风险分配 SYSTEM/AI/HUMAN | 任务与需求字段 |
| 项目记忆 | 从真实任务沉淀候选知识和验证配方 | 项目空间 `memory/` |
| 复盘自演进 | 识别重复推理并推动工具化 | `workflow-learn` Skill |
| 团队上下文 | 汇总任务、风险、待决策和冻结发布 | 项目空间 `status/` |
| 会话预算 | 达到 token 阈值后以结构化检查点轮转会话 | 项目配置 + `status/sessions/` |
| 变更风险路由 | 按风险选择 L0-L3 最小充分流程，避免小修复流程官僚化 | `change-risk-routing.md` + `change-route` Skill |
| Spec 锚定 | 以 AC/SM 编号连接 Spec、任务、验证和测试，检查 Constitution 与 Spec 漂移 | `feature-analyze` + `feature-check.ps1` |

## 权威边界

- TAPD：外部需求、BUG 和业务讨论来源。
- Xueguo 项目空间：当前有效基线、任务、决策、验证和发布证据。
- 业务 Git 仓：Java 源码、测试代码和项目专属配置。
- codebase-memory-mcp：代码结构和调用关系索引，不承担业务决策记忆。

## 1.3 非目标

- 不自动修改业务代码。
- 不自动合并分支或自动发布。
- 不要求 Docker 或专用测试环境。
- 不保存完整聊天记录、完整日志和敏感凭据。
- 不将某一个项目的业务规则写死到通用内核。
- 不绕过宿主直接创建会话；框架负责检测约定和交接状态，创建新会话由宿主能力完成。
