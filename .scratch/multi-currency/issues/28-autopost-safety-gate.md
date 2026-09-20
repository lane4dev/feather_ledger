# 28: 安全关闭旧自动入账入口

Type: task
Triage: ready-for-agent
Status: resolved

Blocked by: 无

**交付：** 在新资格与恢复屏障完成之前防止中间版本误自动记账。

**先写失败测试：** 先测试账户恢复与通知响应不能绕过安全门自动入账。

**验收条件：**

- [ ] 启动、账户恢复、通知响应不绕过统一安全门。
- [ ] 默认禁用自动记账。
- [ ] 手动记入不受阻。

**预计修改的生产文件：**

- `lib/main.dart`
- `lib/features/settings/domain/services/account_service.dart`
- `lib/features/ledger/presentation/notifications/reminder_response_handler.dart`
- `lib/features/ledger/domain/services/recurring_service.dart`

**预计修改的测试文件：**

- `test/unit/features/settings/domain/services/account_lifecycle_test.dart`
- `test/ui/features/ledger/reminder_response_handler_test.dart`
- `test/unit/features/ledger/domain/services/recurring_series_test.dart`
## 共同约束

- 先在已确认的公开测试接缝编写本票首个行为的失败测试，运行并确认失败；再以最小实现通过，逐条重复，不先批量编写所有测试。接缝为账本、账户、周期及备份 service 和真实测试数据库；界面与通知行为使用 widget 测试及现有通知平台适配边界。
- 预计文件按当前代码列出；实施前核对并优先复用现有模块。需要界面文案时同步 en、zh、zh_Hans、zh_Hant 四个 ARB 并运行生成器；Drift 和 Riverpod 生成文件由生成器更新。
- 任务 28 的自动入账保护在任务 48 验收前保持，测试可通过受控测试配置验证各阶段行为；任何阶段不得删除或重置现有数据。完成时运行适用测试及静态分析。
- 完整产品规则与范围以[多币种规格](../spec.md)为准；涉及尚未验证的期次身份、资格历史及恢复算法时，先用有界原型与行为测试验证，不能把候选实现视为既定事实。

## Answer

统一安全门落在 RecurringService.catchUpAutoPosted：新增 autoPostEnabled 门（默认 false），门关闭时启动、账户恢复、通知响应三条自动入账入口全部静默跳过；手动记入（postInstance）不查询该门。测试经 LedgerServiceHarness(autoPostEnabled: true) 受控开启门验证记入路径。见 recurring_service.dart、account_service.dart（restore 经门）、reminder_response_handler.dart（deferred 经门）。
