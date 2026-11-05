# 版本与升级策略

## 版本号

框架使用语义化版本：

- `MAJOR`：目录结构、状态模型或升级方式不兼容。
- `MINOR`：向后兼容地增加规则、模板或工具能力。
- `PATCH`：修正文档、校验或脚本缺陷。

项目安装状态保存在业务仓的 `.agent-workflow/config.yaml`：

```yaml
framework:
  name: xueguo
  version: 1.5.0
project:
  id: example-project
  name: 示例项目
workspace:
  path: ../xueguo-projects
  memory_mode: central
context_management:
  enabled: true
  rollover_threshold_tokens: 260000
  strategy: checkpoint_then_new_session
  checkpoint_directory: status/sessions
```

`rollover_threshold_tokens` 使用十进制 token 数。项目可以覆盖默认值；升级工具只提示旧项目缺失该配置，不自动改写项目拥有的 `config.yaml`。

## 文件所有权

| 文件区域 | 所有者 | 升级行为 |
|---|---|---|
| `.cursor/rules/` | 框架 | 可以覆盖同名框架文件 |
| `.cursor/skills/` | 框架 | 可以覆盖同名框架文件 |
| `.agent-workflow/xueguo.ps1` | 框架 | 可以更新工作流编排器 |
| `.agent-workflow/config.yaml` | 项目 | 永不覆盖，冲突时提示 |
| `docs/features/` | 项目 | 永不删除或覆盖进行中任务 |
| 项目空间 `projects/<id>/` | 项目 | 升级工具不触碰 |

## 升级原则

1. 升级前先执行 `upgrade.ps1 -Check`。
2. 检查输出必须列出新增、更新、冲突和保留文件。
3. 默认只同步框架拥有的文件。
4. 项目配置、项目规则和进行中的任务不自动覆盖。
5. 发现同名文件被项目修改时，生成 `.upgrade-report.md`，由人处理。
6. 升级后重新执行框架校验和项目接入校验。

## 回退

升级只允许在业务仓 Git 分支上执行。工具不执行 reset、force push 或自动提交。回退使用业务仓自身的 Git 历史恢复框架文件；任务数据和项目配置不由工具删除。
