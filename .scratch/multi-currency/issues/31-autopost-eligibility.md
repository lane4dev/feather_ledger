# 31: 关闭开关与币种暂停的手动资格

Type: task
Triage: ready-for-agent
Status: resolved

Blocked by: 23、29、30

**交付：** 关闭或切走币种时的逾期账单永久手动。

**先写失败测试：** 先测试开关开启与到期同毫秒和切回后不自动补记。

**验收条件：**

- [x] 关闭/离开时已到期及关闭/暂停期间到期的期次永久手动，切回或开启后不补记。
- [x] 同毫秒视为已到期。
- [x] 资格跨重启保留。

**预计修改的生产文件：**

- `lib/core/data/database/tables.dart`
- `lib/features/ledger/domain/services/recurring_service.dart`
- `lib/features/ledger/data/repositories/recurring_repository.dart`
- `lib/core/presentation/providers/currency_provider.dart`

**预计修改的测试文件：**

- `test/unit/features/ledger/domain/services/recurring_series_test.dart`
- `test/unit/core/presentation/currency_controller_test.dart`

## Answer

资格判定在 `RecurringService.catchUpAutoPosted` 内完成：对每笔到期且 `scheduled` 的实例，其 `mode` 对应开关必须开启，且 `date > enabledSince[mode]` 且 `date > currencyActiveSince[currency]`（严格大于，因此同毫秒=手动）且实例列 `autoPostEligible` 仍为真，才自动入账；否则调用 `WatchScheduledTransactionsQuery.markAutoPostIneligible` 把该实例永久锁为手动（仍按待入账渲染），并跳过。

实现点：
- `scheduled_transactions_view.auto_post_eligible` 新列（schemaVersion 9→10），默认 true 回填旧行，作为按实例的手动门闩，跨重启保留。
- `PreferencesRepository` 新增本地专用（不随备份）边界时间：`get/setAutoPostEnabledSince(mode)`（开关从关到开时锚定 now）与 `get/setCurrencyActiveSince(code)`（首次使用与每次 `setCurrency` 锚定 now）。
- `RecurringService` 注入 `PreferencesRepository?`（null = 全部开关关闭）；自动入账开关用 `mode` 而非旧 `autoPost` 列判定。
- `currency_provider` 在首用与切换币种时写入 `currencyActiveSince`。

测试：`recurring_series_test.dart` 新增三条（到期前开关关→永久手动且开启不补记；同毫秒=手动；币种尚未成为当前币种→手动），并把既有补记用例改为注入订阅开关开且边界在到期前；`currency_controller_test.dart` 新增“切换币种锚定 active-since 边界”。迁移测试补齐 v1/v6/v8 夹具对 `auto_post_eligible` 列的删除，schemaVersion 断言升为 10；`backup_service_test` 与 `account_lifecycle_test` 的旧版夹具/自动入账开关相应补齐。

验收全绿：`test/unit/core` + `test/unit/features/ledger` + `test/unit/features/settings` 共 435 通过，`flutter analyze` 仅 repo 级既有 info（deprecated_member_use）。

## 共同约束

- 先在已确认的公开测试接缝编写本票首个行为的失败测试，运行并确认失败；再以最小实现通过，逐条重复，不先批量编写所有测试。接缝为账本、账户、周期及备份 service 和真实测试数据库；界面与通知行为使用 widget 测试及现有通知平台适配边界。
- 预计文件按当前代码列出；实施前核对并优先复用现有模块。需要界面文案时同步 en、zh、zh_Hans、zh_Hant 四个 ARB 并运行生成器；Drift 和 Riverpod 生成文件由生成器更新。
- 任务 28 的自动入账保护在任务 48 验收前保持，测试可通过受控测试配置验证各阶段行为；任何阶段不得删除或重置现有数据。完成时运行适用测试及静态分析。
- 完整产品规则与范围以[多币种规格](../spec.md)为准；涉及尚未验证的期次身份、资格历史及恢复算法时，先用有界原型与行为测试验证，不能把候选实现视为既定事实。
