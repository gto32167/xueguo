# Xueguo 自举验证

Xueguo 使用自身的 Spec、任务、验证和复盘流程管理框架升级。每次框架版本升级至少选择一个真实升级任务完成一次闭环，记录流程摩擦和验证证据。

## 最小闭环

1. 用 `backend-feature-spec` 创建升级或规则变更的 Feature 目录。
2. 在 `spec.md` 写明六要素、`SM-xxx` 成功指标和 `AC-xxx` 验收标准。
3. 用 `feature-analyze` 检查 Spec、任务、验证和 Constitution 映射。
4. 用 `domain-feature-dev` 修改框架模板、Skill、Rule 或脚本。
5. 用 `feature-verify` 执行 `tools/validate.ps1`、安装预检、升级预检和必要的业务项目验证。
6. 将发现的流程摩擦写入 `workflow-learn` 复盘，不把未经验证的结论写成 VERIFIED 记忆。

## 关注指标

- Spec 中 AC/SM 的任务覆盖率和验证覆盖率。
- 验证失败后重新修改 Spec 的次数。
- 需求或边界问题在写码前被发现的数量。
- L0/L1 轻量任务节省的文档和上下文开销。
- 升级脚本对项目配置、任务和项目空间的保留结果。

Dogfooding 只验证框架流程和工具行为，不把示例业务规则写入通用内核。

