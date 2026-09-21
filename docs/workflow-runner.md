# Workflow Runner

Xueguo 1.4.0 增加了一个轻量工作流编排器：`tools/xueguo.ps1`。安装到业务仓后，入口位于 `.agent-workflow/xueguo.ps1`。

## 目标

Runner 只自动执行确定性动作：创建任务、推进合法状态、运行 Spec 门禁、执行显式 Maven 验证和生成收尾报告。需求理解、业务影响判断、权限/资金/删除决策仍由 Agent 和人工负责人完成。

## 状态

```text
DRAFT -> ROUTED -> SPEC_READY -> ANALYZED -> IMPLEMENTING -> VERIFYING -> VERIFIED -> FINISHED
```

L0/L1 可以跳过完整 Feature Spec：

```text
DRAFT -> READY_TO_IMPLEMENT -> IMPLEMENTING -> VERIFYING -> VERIFIED -> FINISHED
```

异常状态为 `NEEDS_HUMAN`、`BLOCKED` 和 `NEEDS_SPEC_REVISION`。Runner 不会自动批准人工门禁，也不会把候选项目记忆升级为事实。

## 命令

在业务仓根目录执行：

```powershell
# 创建任务
powershell -ExecutionPolicy Bypass -File .agent-workflow/xueguo.ps1 `
  -Command new -TaskId 1001 -Title "修复订单查询" -ChangeLevel L1

# 风险路由和查看下一步
powershell -ExecutionPolicy Bypass -File .agent-workflow/xueguo.ps1 -Command route -TaskFile tasks/TASK-1001.yaml
powershell -ExecutionPolicy Bypass -File .agent-workflow/xueguo.ps1 -Command next -TaskFile tasks/TASK-1001.yaml

# 通过门禁后开始实现
powershell -ExecutionPolicy Bypass -File .agent-workflow/xueguo.ps1 -Command start -TaskFile tasks/TASK-1001.yaml

# 使用已有证据完成 L0/L1 验证
powershell -ExecutionPolicy Bypass -File .agent-workflow/xueguo.ps1 `
  -Command verify -TaskFile tasks/TASK-1001.yaml -Evidence status/TASK-1001-test.txt

# L2/L3 先确认 Spec 文件齐全，再运行 Feature 门禁
powershell -ExecutionPolicy Bypass -File .agent-workflow/xueguo.ps1 `
  -Command spec-ready -TaskFile tasks/TASK-2001.yaml -FeatureRoot docs/features/order-refund
powershell -ExecutionPolicy Bypass -File .agent-workflow/xueguo.ps1 `
  -Command check -TaskFile tasks/TASK-2001.yaml -FeatureRoot docs/features/order-refund -BaseRef <实现前提交号>

# 在指定业务仓执行显式 Maven 验证
powershell -ExecutionPolicy Bypass -File .agent-workflow/xueguo.ps1 `
  -Command verify -TaskFile tasks/TASK-2001.yaml `
  -RepositoryPath E:\qianjinWork\HiStore-order `
  -MavenArgs @("-pl", "order-core", "-am", "test")

# 生成收尾报告
powershell -ExecutionPolicy Bypass -File .agent-workflow/xueguo.ps1 -Command finish -TaskFile tasks/TASK-1001.yaml
```

## 门禁规则

- `start` 只接受 `READY_TO_IMPLEMENT` 或 `ANALYZED`。
- L2/L3 必须先通过 `spec-ready`，确认 `spec.md`、`tasks.md` 和 `verify.md` 存在。
- L2/L3 的 `check` 必须通过 `.cursor/skills/scripts/feature-check.ps1`。
- `verify` 必须有真实证据文件，或显式提供 `RepositoryPath` 和 `MavenArgs` 并成功执行 Maven。
- `finish` 只接受 `VERIFIED`。
- 已存在的任务文件不会被 `new` 覆盖。

## 设计边界

Runner 是一个小接口、深实现的模块。它管理任务状态和确定性门禁，但不替代 Skill 中的需求分析、代码推理和人工决策。所有命令设计为可重复执行；业务配置和项目空间仍由业务仓所有。
