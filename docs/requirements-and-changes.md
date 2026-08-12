# 需求与变更控制

## 推荐生命周期

```text
discovery -> decision -> baseline -> tasks -> implementation -> verification -> release
```

需求合理性评审默认执行，但属于决策参考，不强制否决甲方需求。评审结果可以是 `ACCEPT`、`SPLIT`、`MANDATED`、`ACCEPTED_WITH_RISK`、`HOLD` 或 `REJECTED_BY_OWNER`。

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

任务必须绑定 `requirement_version`。任务版本与 `CURRENT.yaml` 不一致时，任务进入 `NEEDS_REVIEW`，禁止 Agent 继续写代码。

## 不可逆变更

涉及数据删除、状态含义、资金、权限范围、对外契约删除或历史数据重新解释时，变更单必须写明备份、迁移、兼容窗口、补偿方案和人工批准。
