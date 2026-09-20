# 32: 创建及编辑时自动资格

Type: task
Triage: ready-for-agent
Status: resolved

Blocked by: 31

**交付：** 已到期账单修改后不被误自动入账。

**先写失败测试：** 先测试到期后修改金额与无变化保存分别产生手动和原资格。

**验收条件：**

- [x] 创建已到期或改期到过去转手动。
- [x] 到期前修改金额或描述保持原资格。
- [x] 到期后实际改账务字段转手动，无变更不误转。
- [x] 检测到不可靠回拨转手动。

**预计修改的生产文件：**

- `lib/features/ledger/domain/commands/create_recurring_series_command.dart`
- `lib/features/ledger/domain/commands/update_recurring_bill_command.dart`
- `lib/features/ledger/domain/services/recurring_service.dart`

**预计修改的测试文件：**

- `test/unit/features/ledger/domain/services/recurring_series_test.dart`
- `test/ui/features/ledger/recurring_bill_edit_test.dart`
## Answer

`recurring_series_test.dart` 新增 6 条测试（创建已到期、到期前修改、到期后修改、无变化保存、改期到过去、回拨），全部通过；`recurring_series_test.dart` 共 47 条通过。

**验收条件逐条：**

- 创建已到期或改期到过去转手动：`createSeries` 物化后调用 `markSeriesIneligibleBefore(id, DateTime.now())`，把系列内所有 `date <= now` 且仍 `autoPostEligible` 的待入账行批量置为手动；`updateBill` 改期到过去时新行以 `autoPostEligible: false` 写入（`shouldLatch` 由 `movedToPast` 触发）。
- 到期前修改金额或描述保持原资格：`shouldLatch = actuallyChanged && (wasDue || movedToPast || rollback)`，未到期（`wasDue` 为假）且非回拨时不置手动。
- 到期后实际改账务字段转手动，无变更不误转：`actuallyChanged` 比较金额、日期、账户、分类、描述五字段，全同则 `shouldLatch` 为假。
- 检测到不可靠回拨转手动：`UpdateRecurringBillCommand` 注入 `PreferencesRepository`，读 `getLastSeenWallClock()`；若本次 `now` 早于上次记录，视为回拨并置手动；每次决策后写 `setLastSeenWallClock(now)`。

`recurring_bill_edit_test.dart` 为视图模型 widget 测试（fake service），未改动。

- 先在已确认的公开测试接缝编写本票首个行为的失败测试，运行并确认失败；再以最小实现通过，逐条重复，不先批量编写所有测试。接缝为账本、账户、周期及备份 service 和真实测试数据库；界面与通知行为使用 widget 测试及现有通知平台适配边界。
- 预计文件按当前代码列出；实施前核对并优先复用现有模块。需要界面文案时同步 en、zh、zh_Hans、zh_Hant 四个 ARB 并运行生成器；Drift 和 Riverpod 生成文件由生成器更新。
- 任务 28 的自动入账保护在任务 48 验收前保持，测试可通过受控测试配置验证各阶段行为；任何阶段不得删除或重置现有数据。完成时运行适用测试及静态分析。
- 完整产品规则与范围以[多币种规格](../spec.md)为准；涉及尚未验证的期次身份、资格历史及恢复算法时，先用有界原型与行为测试验证，不能把候选实现视为既定事实。
