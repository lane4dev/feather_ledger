# 05: 自动入账、恢复水线、币种切回补录与 `failed` 失败闭环

**What to build:** 打通自动入账、备份恢复水线、多币种静默与切回补录以及 `failed` 失败重试全链路：`ConvertScheduledToPostedCommand` 读取实例有效覆盖值（`effectiveDate` / `effectiveAmountMinor` / `effectiveMemo`）并同时接受 `scheduled` 与 `failed`，事件 `TransactionRecorded.sourceScheduledBillId` 写入实例 UUID；`RecurringService.catchUpAutoPosted` 按极简谓词（`isActive && autoPost && !manualOnly && currency == current && effectiveDate <= now`，同时覆盖 `planned` 与 `repeating` 及其补齐的历史缺失期次）每 20 条分批让出事件循环，并在启动及表单保存开启 `autoPost` 的规则后立即对当前币种执行并弹出兼容计划与订阅的泛化入账汇总 SnackBar，单笔失败置 `failed` 不阻塞其余项；恢复备份重启后执行 `markPreRestoreManualOnly` 冻结全币种历史到期项；切换回含合资格积压项的币种时弹出二选一确认（「全部入账」/「保留为待入账」）；`PendingBillSheet` 置顶警示 `failed` 并支持重试记入或跳过。

**Blocked by:** 01: Schema v15 洁净重构与废旧状态机清除, 02: 三档录入形态、`autoPost` 独立开关记忆与过去起点即时自动入账, 04: 二元编辑作用域、单期跳过与停止周期规则

**Status:** ready-for-agent

## Pre-agreed TDD Seams
1. `ConvertScheduledToPostedCommand` 接缝：验证优先取覆盖金额/日期/备注、同时接受 `scheduled` 与 `failed`、正确写入 `sourceScheduledBillId = bill.id`。
2. `RecurringService.catchUpAutoPosted`、`markPreRestoreManualOnly`、`getCurrencyBacklog`、`settleCurrencyBacklog` 接缝：验证谓词过滤（含 `planned` + `repeating` 及无上限历史补齐实例）、>= 20 条分批让出、异常转为 `failed` 不阻断队列、保存开启 `autoPost` 的规则后即时补账、恢复水线将全币种 `<= now` 置 `manualOnly = true`、币种切回仅命中 `autoPost && !manualOnly && <= now`。
3. `PendingBillSheet` 失败重试 + `CurrencyBacklogDialog` UI 接缝：验证失败横幅提示与重试弹出具体 `LedgerErrorCode` 本地化文案，以及币种切回二选一交互。

## File Changes
- **Create**:
  - `lib/features/ledger/presentation/widgets/currency_backlog_dialog.dart`
  - `test/unit/features/ledger/domain/services/auto_post_catchup_test.dart`
  - `test/ui/features/ledger/currency_backlog_dialog_test.dart`
- **Modify**:
  - `lib/app/bootstrap/pending_restore.dart`（恢复交换成功后写入轻量 `restore_applied` 标记供启动链消费后删除）
  - `lib/main.dart`（按 `applyPendingRestore -> rebuild -> materialize -> markPreRestoreManualOnly -> catchUpAutoPosted` 执行，并展示入账汇总 SnackBar）
  - `lib/features/ledger/domain/commands/convert_scheduled_to_posted_command.dart`
  - `lib/features/ledger/domain/services/recurring_service.dart`
  - `lib/core/data/database/daos/recurring_dao.dart`
  - `lib/features/ledger/domain/repositories/recurring_repository.dart`
  - `lib/features/ledger/data/repositories/recurring_repository.dart`
  - `lib/features/ledger/presentation/widgets/pending_bill_sheet.dart`
  - `lib/features/ledger/presentation/mappers/transaction_ui_mapper.dart`
  - `lib/features/ledger/presentation/models/transaction_tile_ui_model.dart`
  - `lib/features/settings/presentation/screens/settings_screen.dart`（及/或根壳层监听 `currencyControllerProvider` 切换以触发 `CurrencyBacklogDialog`）
  - `lib/app/l10n/app_en.arb`、`lib/app/l10n/app_zh.arb`、`lib/app/l10n/app_zh_Hans.arb`、`lib/app/l10n/app_zh_Hant.arb`（+ `flutter gen-l10n`）
  - `test/unit/app/bootstrap/pending_restore_test.dart`
  - `test/unit/features/ledger/domain/services/convert_scheduled_to_posted_test.dart`
  - `test/unit/features/settings/data/backup_service_test.dart`
  - `test/ui/features/ledger/pending_bill_test.dart`

## Acceptance Criteria
- [ ] 恢复备份后启动不自动补扣备份导出前到期项；
- [ ] 非当前币种完全静默，切回时仅对 `autoPost && !manualOnly && <= now` 积压项弹二选一；
- [ ] 单笔失败置 `failed` 且不中断后续自动入账，可在详情抽屉重试或跳过；
- [ ] `flutter gen-l10n`、`flutter analyze` 零错误、全量测试绿灯。
