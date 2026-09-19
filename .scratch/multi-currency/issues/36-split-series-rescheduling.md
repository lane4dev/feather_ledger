# 36: 本次及以后改期与月末例外

Type: task
Triage: ready-for-agent

Blocked by: 35

**交付：** 系列拆分时只改变选定范围且不丢失月末账单。

**先写失败测试：** 先测试 30 日改 31 日保留 4 月手动账单及拆分边界。

**验收条件：**

- [ ] 范围之前不变。
- [ ] 不存在对应日期的手动账单保留原日期。
- [ ] 新增历史期不补造。
- [ ] 再次改期同一期同日只保留一笔。

**预计修改的生产文件：**

- `lib/features/ledger/domain/commands/update_recurring_bill_command.dart`
- `lib/features/ledger/domain/commands/project_recurring_events_command.dart`

**预计修改的测试文件：**

- `test/ui/features/ledger/recurring_bill_edit_test.dart`
- `test/unit/features/ledger/domain/services/recurring_series_test.dart`
## 共同约束

- 先在已确认的公开测试接缝编写本票首个行为的失败测试，运行并确认失败；再以最小实现通过，逐条重复，不先批量编写所有测试。接缝为账本、账户、周期及备份 service 和真实测试数据库；界面与通知行为使用 widget 测试及现有通知平台适配边界。
- 预计文件按当前代码列出；实施前核对并优先复用现有模块。需要界面文案时同步 en、zh、zh_Hans、zh_Hant 四个 ARB 并运行生成器；Drift 和 Riverpod 生成文件由生成器更新。
- 任务 28 的自动入账保护在任务 48 验收前保持，测试可通过受控测试配置验证各阶段行为；任何阶段不得删除或重置现有数据。完成时运行适用测试及静态分析。
- 完整产品规则与范围以[多币种规格](../spec.md)为准；涉及尚未验证的期次身份、资格历史及恢复算法时，先用有界原型与行为测试验证，不能把候选实现视为既定事实。
