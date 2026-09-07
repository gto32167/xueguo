# 需求与变更控制

## 推荐生命周期

```text
discovery -> decision -> baseline -> tasks -> implementation -> verification -> release
```

需求合理性评审默认执行，但属于决策参考，不强制否决甲方需求。评审结果可以是 `ACCEPT`、`SPLIT`、`MANDATED`、`ACCEPTED_WITH_RISK`、`HOLD` 或 `REJECTED_BY_OWNER`。

## 变更风险分级

先判断变更级别，再选择流程深度：

- `L0`：局部文案、日志、样式或机械修复，使用轻量变更记录和最小检查。
- `L1`：单模块内部 BUG，补充复现、根因、回归测试和受影响模块验证。
- `L2`：跨模块行为、接口、数据、消费者或新依赖变化，使用增量 Spec、Impact、Plan 和 Verify。
- `L3`：资金、权限边界、状态含义、数据删除/迁移、对外契约删除或其他不可逆变化，使用完整 Spec、Change Request 和人工决策。

L0/L1 不要求创建没有实际信息的完整规格工件，但必须记录责任人、范围、验证命令和未验证风险。实施中发现影响扩大时，立即升级级别并补齐产出。详细路由见 `docs/change-risk-routing.md`。

## 外部依赖

协议未知但业务结果明确时，可以先实现内部 Port、Fake Adapter 和自动化测试。业务语义、资金规则、数据删除语义未知时，只能拆分或等待决策，不能用临时假设代替真实规则。

## 需求基线

批准后的基线不可静默覆盖。方向性变化必须创建变更单，并生成新版本：

```text
requirements/REQ-001/
├─ CURRENT.yaml
├─ baselines/v1/spec.md
├─ baselines/v2/spec.md
└─ changes/CR-001.md
```

L2/L3 任务必须绑定 `requirement_version`。任务版本与 `CURRENT.yaml` 不一致时，任务进入 `NEEDS_REVIEW`，禁止 Agent 继续写代码。L0/L1 可以使用轻量变更记录或 BUG 卡，并将 `requirement_version` 标记为 `N/A`。

## 不可逆变更

涉及数据删除、状态含义、资金、权限范围、对外契约删除或历史数据重新解释时，变更单必须写明备份、迁移、兼容窗口、补偿方案和人工批准。
