# 接口探针

## 定位

BUG 修复阶段不能只做静态源码和日志分析。拿到测试环境 token 后，必须用真实接口复现 BUG、核对字段、验证修复，把"代码看起来没问题"升级为"接口真实返回可证明"。前端代码在手时尤其重要：前端消费的必填字段在接口返回 `null` 或缺失，是纯源码分析最容易漏掉的根因。

```text
静态定位假设 -> 构造最小探针 -> 真实响应比对 -> 根因确认 -> 修复 -> 重放探针回归
```

静态分析负责提出假设，接口探针负责证实或推翻假设。两者结论冲突时，以接口真实返回为准。

## 前置条件

1. 环境租约状态为 `AVAILABLE`，需要 VPN 的环境先确认人工已连接。
2. 确认 token 获取途径，三选一：
   - 登录接口换取：使用测试账号调用登录接口，token 只保留在会话内存。
   - 项目空间凭据引用：凭据文件由项目维护，框架和项目空间索引只记录文件路径引用，不记录凭据内容。
   - 会话内提供：由人临时提供，用完即弃。
3. 探针目标必须是测试环境；禁止把探针指向生产环境。

## Token 与凭据规则

- token 只在会话内存和探针脚本进程内流转，不写入任务卡、BUG 卡、证据文件、项目记忆、文档和聊天总结。
- 探针定义文件不保存真实 token、密码、完整连接串；认证头由脚本在执行时注入。
- 证据文件输出前必须脱敏：token、Cookie、Authorization 头替换为 `***`。
- 探针执行完，token 即视为过期材料，不在会话之间复用。

## 安全边界

- 只读接口（GET、查询类）优先；修复验证也优先用查询接口确认数据表现。
- 非只读探针（写入、删除、状态流转、资金操作）必须先设 `human_gate.required: true`，由人批准后才能执行。
- 探针请求要可重放、可停止：记录完整请求定义，避免一次性手工拼参数。
- 同一接口反复探针时注意限流和测试环境共享性，不做压力测试。

## 探针执行

使用 `bug-probe` Skill 和 `api-probe.ps1` 脚本执行确定性请求：

```powershell
powershell -ExecutionPolicy Bypass -File .cursor\skills\scripts\api-probe.ps1 `
  -ProbeFile bugs\TAPD-1001-probe.json `
  -BaseUrl https://test.example.com `
  -TokenEnvName XUEGUO_API_TOKEN `
  -OutFile status\TAPD-1001-probe-before.md
```

- token 通过环境变量或凭据文件传入，不出现在命令行参数。
- 脚本输出状态码、耗时、脱敏响应摘要和必填字段检查表，verdict 为 `API_PROBE_PASS`、`API_PROBE_FAIL` 或 `API_PROBE_ERROR`。
- `required_fields` 支持点路径和数组下标，例如 `data.orderNo`、`data.items[0].skuName`。

## 前端字段比对

仓库中存在前端代码时，修复前必须完成一次字段比对：

1. 从前端代码提取 BUG 相关页面消费的必填字段清单。
2. 用接口探针获取真实响应，逐字段比对：字段是否存在、是否为 `null`、类型和枚举值是否符合前端预期。
3. 把 `null` 或缺失字段记入 BUG 卡的 `api_probe.required_field_checks`，作为根因证据或排除证据。

## 证据与标记

- 修复前的探针响应是复现证据，标记 `API_REPRODUCED`；修复后重放同一探针的响应是回归证据，标记 `API_VERIFIED`。
- 探针证据回填 BUG 卡 `api_probe` 段，并作为 `verify` 命令的 Evidence 文件。
- 证据标记体系在 `MOCK_VERIFIED`、`CONTRACT_VERIFIED`、`SANDBOX_VERIFIED`、`RELEASE_VERIFIED` 基础上增加 `API_REPRODUCED` 和 `API_VERIFIED`，不能互相冒充。
- 拿不到 token 或环境不可用时，退回静态分析路线，并在 `unverified_risks` 写明"未做接口验证"及原因；不允许把静态推断写成接口结论。
