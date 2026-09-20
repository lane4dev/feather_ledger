# 33: 逾期账单按月增量补齐

Type: task
Triage: ready-for-agent
Status: resolved

Blocked by: 31、32

**交付：** 长期未启动的账单可逐月找回。

**先写失败测试：** 先测试每日系列停用超过 12 期后所有月份可找到。

**验收条件：**

- [ ] 超过 12 期可有界分页并接续。
- [ ] 原月份显示，月份选择器标记未物化待处理期。
- [ ] 失败及手动项不阻断后续。
- [ ] 手动记入沿用排定日期。

**预计修改的生产文件：**

- `lib/features/ledger/domain/commands/project_recurring_events_command.dart`
- `lib/features/ledger/domain/queries/watch_scheduled_transactions_query.dart`
- `lib/shared/presentation/widgets/feather_month_picker.dart`

**预计修改的测试文件：**

- `test/unit/features/ledger/domain/services/recurring_materialization_test.dart`
- `test/ui/features/ledger/pending_bill_test.dart`
## 共同约束

- 先在已确认的公开测试接缝编写本票首个行为的失败测试，运行并确认失败；再以最小实现通过，逐条重复，不先批量编写所有测试。接缝为账本、账户、周期及备份 service 和真实测试数据库；界面与通知行为使用 widget 测试及现有通知平台适配边界。
- 预计文件按当前代码列出；实施前核对并优先复用现有模块。需要界面文案时同步 en、zh、zh_Hans、zh_Hant 四个 ARB 并运行生成器；Drift 和 Riverpod 生成文件由生成器更新。
- 任务 28 的自动入账保护在任务 48 验收前保持，测试可通过受控测试配置验证各阶段行为；任何阶段不得删除或重置现有数据。完成时运行适用测试及静态分析。
- 完整产品规则与范围以[多币种规格](../spec.md)为准；涉及尚未验证的期次身份、资格历史及恢复算法时，先用有界原型与行为测试验证，不能把候选实现视为既定事实。

## Answer

**有界逾期物化（materialization core）**

`ProjectRecurringEventsCommand` 对永续系列先走新增的 `_fillOverdue`：用 `rule.getInstances(start: startUtc, before: nowUtc)` 把启动截点前所有缺失的期次全部物化（不受 12 条滚动窗口上限约束），再照旧以 `after: nowUtc` 填 3–12 条未来窗口。这样每天 40 天前开启的每日系列会得到全部 ~40 条逾期期次，而不是停在最早的 12 条。原来的 `_fill` 里那个 `existing.values.where(scheduled).length >= maxKeep` 全局上限被删除——它现在会把逾期行计入，反而挡住未来窗口。

有限系列（有 endDate / countLimit）本来就全量物化，不受影响。

**月份选择器标记**

`FeatherMonthPicker` 新增 `markedMonths: Set<DateTime>`（`show` 透传），`_MonthTile` 在标记月渲染一个 5×5 圆形小点。数据来自 `pendingBillMonthsProvider`（`ledger_view_model.dart`）：按当前币种过滤 `watchScheduledTransactions`，把每个 `scheduled` 实例的 `DateTime(year, month)` 汇成集合；`ledger_screen._onMonthTap` 读取它传入选择器，`build` 里 `ref.watch` 保持流存活。

**验收覆盖**

- 「超过 12 期可分页并接续」：`recurring_materialization_test.dart` 新增『a dormant daily series materializes every overdue bill, not twelve』（断言 `overdue.length > 12` 且逐日连续）。
- 「原月份显示 + 选择器标记」：`feather_month_picker_test.dart`（标记月出点、无标记不出点）+ `ledger_pending_months_test.dart`（两个月都进集合）。
- 「失败及手动项不阻断后续 / 手动沿用排定日期」：既有测试已覆盖（`_fillOverdue` 只插 `status == null` 的 id，`postInstance` 用排定 `date`）。

**静态分析**：`flutter analyze` 170 项 info，全部为仓库既有的 `deprecated_member_use`（`package:flutter/material.dart` → `package:material_ui`），无 error/warning。
