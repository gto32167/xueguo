# 会话上下文预算

## 配置

业务仓通过 `.agent-workflow/config.yaml` 配置会话轮转：

```yaml
context_management:
  enabled: true
  rollover_threshold_tokens: 260000
  strategy: checkpoint_then_new_session
  checkpoint_directory: status/sessions
```

- `rollover_threshold_tokens`：当前会话累计上下文达到该 token 数时触发轮转，默认 `260000`。
- `strategy`：当前只支持 `checkpoint_then_new_session`。
- `checkpoint_directory`：相对于项目空间的检查点目录。

## 执行协议

1. 每轮结束后读取宿主提供的当前上下文 token 计数。
2. 未达到阈值时继续当前会话，不生成冗余摘要。
3. 达到阈值时，先完成或终止当前工具调用，不在写文件、事务或验证命令中途切换。
4. 根据项目空间的 `status/sessions/_template.yaml` 写入 `status/sessions/<task-id>.yaml`；框架仓中的源模板为 `templates/status/session-checkpoint.yaml`。
5. 重新读取检查点，确认目标、约束、已完成事项、未完成事项、工作区状态和验证结果齐全。
6. 请求宿主创建新会话；新会话只加载固定规则、项目配置、检查点和用户最新指令，不重放完整聊天历史或完整工具输出。
7. 新会话确认接管后，将检查点状态从 `READY` 更新为 `RESUMED`。

如果宿主不暴露 token 计数或创建新会话的能力，Agent 必须明确报告限制，不得声称已经自动轮转。此时仍可生成检查点，供用户手动开启新会话后续接。

## 成本边界

轮转只有在新会话不重新携带完整历史时才会减少输入 token。源代码、Git 状态、任务文档和测试报告继续保留在各自权威位置，检查点只记录恢复任务所需的结论和引用。
