---
name: bug-probe
version: 0.1.0
description: BUG 修复阶段用真实接口复现和验证：拿 token 打接口、比对前端必填字段、修复后重放回归。用户说 BUG 修复、复现、接口验证、字段返回 null 时触发。
---

# Bug Probe

BUG 修复不能只靠静态源码和日志分析。token 可用时，先打真实接口复现，再定位，修复后重放同一探针回归。规则冲突时以接口真实返回为准。

## 执行步骤

1. 读取 BUG 卡和环境租约，确认测试环境可用、VPN 已连接（如需），并确认 token 获取途径：登录接口换取、项目空间凭据文件引用或会话内提供。
2. 从 BUG 描述、前端代码和日志构造最小探针请求，写成探针定义文件（JSON），不要手工拼一次性参数。
3. 执行探针脚本获取修复前的真实响应：

```powershell
$env:XUEGUO_API_TOKEN = "<会话内获取，不写入任何文件>"
powershell -ExecutionPolicy Bypass -File .cursor\skills\scripts\api-probe.ps1 `
  -ProbeFile <探针文件> -BaseUrl <测试环境地址> `
  -OutFile <证据目录>\<BUG标识>-probe-before.md
```

4. 把真实响应与期望比对：状态码、业务码、关键字段。有前端代码时，提取该页面消费的必填字段清单，逐字段检查是否存在、是否 `null`、类型和枚举是否符合预期；`null` 或缺失字段直接记入 BUG 卡 `api_probe.required_field_checks` 作为根因证据。
5. 用探针结论收敛根因，再做源码修复；源码推断与接口返回冲突时，以接口返回为准重新定位。
6. 修复后重放同一探针文件，输出 `-probe-after.md` 证据，对比前后响应确认修复生效。
7. 回填 BUG 卡 `api_probe` 段：`reproduced: API_REPRODUCED`、`verified_after_fix: API_VERIFIED`，探针证据文件作为 `verify` 的 Evidence。

## 安全边界

- 只读探针优先；写入、删除、状态流转、资金类请求必须先设 `human_gate.required: true` 并获得人工批准。
- 探针只打测试环境，禁止指向生产。
- token 只在会话内存和脚本环境变量中流转；证据输出前脚本会脱敏，但仍不得把 token、密码、完整连接串写入探针文件、BUG 卡、证据、记忆或总结。
- 探针失败或不可执行（无 token、环境不可用、无权限）时，退回静态分析路线，并在 `unverified_risks` 写明"未做接口验证"及原因，不允许把静态推断写成接口结论。

## 证据要求

- 修复前与修复后的探针证据文件各一份，包含请求摘要、状态码、耗时、脱敏响应和必填字段检查表。
- 字段比对表：前端期望字段、接口实际值、结论。
- 沉淀项目记忆时，把可复用的探针请求和字段检查写成验证配方候选，不写入真实凭据。
