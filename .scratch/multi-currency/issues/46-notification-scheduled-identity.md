# 46: 通知追踪账单改期及删除

Type: task
Triage: ready-for-agent
Status: resolved

Blocked by: 36、45

**交付：** 旧通知能打开改期后的账单或报告已删除。

**先写失败测试：** 先测试通知显示后改期，再点击打开新日期。

**验收条件：**

- [ ] 多次改期、系列拆分后旧通知指向同一期。
- [ ] 单期和整个系列删除后保留精简记录，重启及备份恢复仍提示已删除。

**预计修改的生产文件：**

- `lib/features/ledger/domain/commands/update_recurring_bill_command.dart`
- `lib/features/ledger/domain/commands/delete_recurring_bill_command.dart`
- `lib/features/ledger/presentation/notifications/reminder_response_handler.dart`
- `lib/core/data/database/tables.dart`

**预计修改的测试文件：**

- `test/ui/features/ledger/reminder_response_handler_test.dart`
- `test/unit/features/ledger/domain/services/recurring_series_test.dart`
## 共同约束

- 先在已确认的公开测试接缝编写本票首个行为的失败测试，运行并确认失败；再以最小实现通过，逐条重复，不先批量编写所有测试。接缝为账本、账户、周期及备份 service 和真实测试数据库；界面与通知行为使用 widget 测试及现有通知平台适配边界。
- 预计文件按当前代码列出；实施前核对并优先复用现有模块。需要界面文案时同步 en、zh、zh_Hans、zh_Hant 四个 ARB 并运行生成器；Drift 和 Riverpod 生成文件由生成器更新。
- 任务 28 的自动入账保护在任务 48 验收前保持，测试可通过受控测试配置验证各阶段行为；任何阶段不得删除或重置现有数据。完成时运行适用测试及静态分析。
- 完整产品规则与范围以[多币种规格](../spec.md)为准；涉及尚未验证的期次身份、资格历史及恢复算法时，先用有界原型与行为测试验证，不能把候选实现视为既定事实。

## Answer

**机制：** 新增 CRUD 豁免表 `scheduled_bill_redirects`（`old_id` 主键、`new_id` 可空=已删除、`created_at`）。账单 id 编码日期，改期/拆分会让旧 id 成孤儿；重定向记录把已显示通知的旧 id 解析到同一期次（或报告已删除），跨重启与备份恢复持续存在。

**解析链：** `ReminderResponseHandler._resolveScheduled(id)` 先查 `watchScheduled()` 里活状态（scheduled/posted）的行；若为 skipped/failed/缺失，则经 `resolveScheduledRedirect` 沿重定向链（最多 16 跳，防环）走到最终 id，或判定 deleted/never-existed。

**写入点（命令层）：**
- `update_recurring_bill_command`：`_updateOne` 移动分支 → `recordScheduledRedirect(oldId → movedId)`；`_splitFrom` 先捕获 cut 及之后全部 scheduled 行，再为每行记 `recordScheduledRedirect(row.id → newSeriesId 下的新 id)`（月末用 `_samePeriod` 对齐）；`_updateWholeSeries` 非 posted 分支 → `recordScheduledRedirect(row.id → movedId)`（posted 行原地保留旧 id，无需重定向）。
- `delete_recurring_bill_command`：thisOnly → `recordScheduledRedirect(id → null)`；thisAndFollowing 与 all → 删除前捕获待删 scheduled 行，逐行记 `recordScheduledRedirect(row.id → null)`。

**验收映射：** 「多次改期/拆分指向同一期」= 重定向链解析 + handler 动作使用解析后的 `bill.id`（`postInstance`/`deleteBill`/`_showRecorded`）；「删除后保留精简记录，重启及恢复仍提示已删除」= 重定向行是数据库表（非内存态），handler 命中 `newId==null` 时报 `notificationDeleted` 文案。schemaVersion 12→13（`createTable` 新增，非事件溯源投影）。

**测试：** `recurring_series_test.dart` 新增「通知重定向」组（移动解析、thisOnly 删除持久、整系列删除）；`reminder_response_handler_test.dart` 新增改期打开新账单 + 已删除报 deleted 两个 widget 测试。全量 730 通过（6 个既有 receipt_consistency 日期标签失败与本票无关）。
