# 02: 三档录入形态、`autoPost` 开关记忆与创建时间保护

**What to build:** 将交易新建页收敛为「普通 / 计划 / 重复」三档 `TransactionFormMode`；仅在选择「重复」时展示 `autoPost` 开关并记忆用户上次选择（`lastRecurringAutoPost`，默认 `false`，不随 `.flbackup` 导出导入）；创建 `autoPost = true` 规则并完成首轮物化后，若存在当时已 `effectiveDate <= now` 的 `scheduled` 实例，自动标为 `manualOnly = true`（确保自动入账仅对未来新到期期次生效）。

**Blocked by:** 01: Schema v15 洁净重构与废旧状态机清除

**Status:** ready-for-agent

## Pre-agreed TDD Seams
1. `TransactionFormViewModel` 接缝：验证三档模式切换、`lastRecurringAutoPost` 读取与持久化回写、`planned` 强制以 `autoPost = false` 保存、`repeating` 按开关值保存。
2. `RecurringService.createSeries` 接缝：验证创建 `autoPost = true` 且起始日含过去或当天日期时，首轮物化中 `effectiveDate <= now` 的实例被标为 `manualOnly = true`，未来日期实例保持 `manualOnly = false`。
3. 交易新建表单 Widget 接缝：验证三档选择器渲染、「自动入账」开关仅在「重复」显示且切换记忆生效。

## File Changes
- **Create**:
  - `test/ui/features/ledger/transaction_form_recurring_mode_test.dart`
- **Modify**:
  - `lib/features/ledger/presentation/view_model/transaction_form_view_state.dart`
  - `lib/features/ledger/presentation/view_model/transaction_form_view_model.dart`（+ 重新生成 `.g.dart` 如有变更）
  - `lib/features/ledger/presentation/screens/transaction_form_screen.dart`
  - `lib/features/ledger/presentation/widgets/ledger_type_selector.dart`
  - `lib/features/ledger/presentation/widgets/recurring_mode_label.dart`
  - `lib/features/ledger/domain/commands/create_recurring_series_command.dart`
  - `lib/features/ledger/domain/services/recurring_service.dart`
  - `lib/app/l10n/app_en.arb`、`lib/app/l10n/app_zh.arb`、`lib/app/l10n/app_zh_Hans.arb`、`lib/app/l10n/app_zh_Hant.arb`（+ `flutter gen-l10n`）
  - `test/unit/features/ledger/presentation/transaction_form_view_model_test.dart`
  - `test/unit/features/ledger/domain/services/recurring_series_test.dart`

## Acceptance Criteria
- [ ] 新建页仅保留「普通 / 计划 / 重复」三档入口，「自动入账」开关仅在「重复」时可见并记忆用户上次选择（默认关闭）；
- [ ] `planned` 模式落库恒为 `autoPost = false`，`repeating` 按开关值落库；
- [ ] 创建 `autoPost = true` 规则且含当日或过去日期时，已到期实例自动标 `manualOnly = true`，未来实例保持 `false`；
- [ ] `flutter gen-l10n`、`flutter analyze` 零错误、全量测试绿灯。
