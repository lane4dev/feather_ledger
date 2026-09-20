# 45: 按币种协调提醒和通知操作

Type: task
Triage: ready-for-agent
Status: resolved

Blocked by: 23、31、33

**交付：** 非当前币种暂停未来提醒，旧通知仍可操作。

**先写失败测试：** 先测试 CNY 当前设置下通过 USD 通知记入且设置不变。

**验收条件：**

- [ ] 取消旧币种未触发提醒而保留已显示通知，切回不补发。
- [ ] 从旧通知可按原币种编辑或手动记入且设置不变。
- [ ] 入账后取消未触发提醒。

**预计修改的生产文件：**

- `lib/features/ledger/data/notifications/recurring_reminders.dart`
- `lib/features/ledger/presentation/notifications/reminder_response_handler.dart`
- `lib/features/ledger/presentation/screens/recurring_bill_form_screen.dart`

**预计修改的测试文件：**

- `test/unit/features/ledger/data/notifications/recurring_reminders_test.dart`
- `test/ui/features/ledger/reminder_response_handler_test.dart`
## 共同约束

- 先在已确认的公开测试接缝编写本票首个行为的失败测试，运行并确认失败；再以最小实现通过，逐条重复，不先批量编写所有测试。接缝为账本、账户、周期及备份 service 和真实测试数据库；界面与通知行为使用 widget 测试及现有通知平台适配边界。
- 预计文件按当前代码列出；实施前核对并优先复用现有模块。需要界面文案时同步 en、zh、zh_Hans、zh_Hant 四个 ARB 并运行生成器；Drift 和 Riverpod 生成文件由生成器更新。
- 任务 28 的自动入账保护在任务 48 验收前保持，测试可通过受控测试配置验证各阶段行为；任何阶段不得删除或重置现有数据。完成时运行适用测试及静态分析。
- 完整产品规则与范围以[多币种规格](../spec.md)为准；涉及尚未验证的期次身份、资格历史及恢复算法时，先用有界原型与行为测试验证，不能把候选实现视为既定事实。

## Answer

实现（spec 006 US45）：

- `upcomingReminders` 新增 `currencyCode` 参数——只在当前币种的账单上安排提醒；其他币种账单的提醒被取消（不安排），切回后才重新出现，不补发错过的提醒。
- `RecurringReminders` 注入 `String? Function() currencyCode` 解析器（测试直接构造时默认全币种）；`recheck()` 重新读取 `watchScheduled().first` 并跑 `_reconcile`。`recurringRemindersProvider` 用 `ref.listen(currencyControllerProvider, ...)` 在切换币种时触发 `recheck()`——用 `listen` 而非 `watch`，避免 provider 重建丢失进行中的响应队列。
- 从旧通知记入/跳过本就经 `postInstance`/`deleteBill`，二者无币种守卫且处理函数从不读 `currencyControllerProvider`，故以原币种记入且不改变设置（widget 测试钉住 `setCalls` 为空）；记入成功后账单状态翻转触发 `watchScheduled()` 流 → `_reconcile` 取消其未触发提醒。

测试：`recurring_reminders_test.dart` 3 条（含「仅当前币种安排提醒」）；`reminder_response_handler_test.dart` 8 条（含「旧币种通知记入不改设置」）。全部通过；`flutter analyze` 0 error/warning。
