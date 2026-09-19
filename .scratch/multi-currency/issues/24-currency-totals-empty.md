# 24: 日月合计及空状态按币种

Type: task
Triage: ready-for-agent

Blocked by: 23

**交付：** 账本合计、余额及空状态不混币。

**先写失败测试：** 先测试同日 CNY/USD 互不混加和有余额空状态。

**验收条件：**

- [ ] 日小计、月收支及余额先限定币种。
- [ ] 有账户无交易显示余额及零收支。
- [ ] 无账户显示零及创建引导。

**预计修改的生产文件：**

- `lib/features/ledger/domain/queries/watch_monthly_snapshot_query.dart`
- `lib/features/ledger/presentation/models/ledger_day_group.dart`
- `lib/features/ledger/presentation/widgets/ledger_empty.dart`
- `lib/shared/presentation/models/monthly_summary_ui_model.dart`

**预计修改的测试文件：**

- `test/unit/features/ledger/presentation/ledger_day_group_test.dart`
- `test/unit/features/ledger/domain/services/monthly_snapshot_test.dart`
- `test/ui/features/ledger/ledger_timeline_test.dart`
## 共同约束

- 先在已确认的公开测试接缝编写本票首个行为的失败测试，运行并确认失败；再以最小实现通过，逐条重复，不先批量编写所有测试。接缝为账本、账户、周期及备份 service 和真实测试数据库；界面与通知行为使用 widget 测试及现有通知平台适配边界。
- 预计文件按当前代码列出；实施前核对并优先复用现有模块。需要界面文案时同步 en、zh、zh_Hans、zh_Hant 四个 ARB 并运行生成器；Drift 和 Riverpod 生成文件由生成器更新。
- 任务 28 的自动入账保护在任务 48 验收前保持，测试可通过受控测试配置验证各阶段行为；任何阶段不得删除或重置现有数据。完成时运行适用测试及静态分析。
- 完整产品规则与范围以[多币种规格](../spec.md)为准；涉及尚未验证的期次身份、资格历史及恢复算法时，先用有界原型与行为测试验证，不能把候选实现视为既定事实。
