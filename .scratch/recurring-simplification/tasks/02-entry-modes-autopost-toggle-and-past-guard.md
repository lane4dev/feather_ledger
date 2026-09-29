# 02: 三档录入形态、`autoPost` 独立开关记忆与过去起点即时自动入账

**What to build:** 将交易新建页收敛为「普通 / 计划 / 重复」三档 `TransactionFormMode`；在选择「计划」或「重复」时均展示 `autoPost` 开关并各自独立记忆上次选择（`lastPlannedAutoPost` 与 `lastRepeatingAutoPost`，默认 `false`，不随 `.flbackup` 导出导入；`planned` 始终保持「计划」标签）；取消创建时过去期次拦截保护——创建 `autoPost = true` 规则（`planned` 或 `repeating`）且起点在过去或当天时，物化出的实例保持 `manualOnly = false` 并在保存后当场对当前币种该规则触发 `catchUpAutoPosted` 自动入账（跨币种静默）。

**Blocked by:** 01: Schema v15 洁净重构与废旧状态机清除

**Status:** ready-for-agent

## Pre-agreed TDD Seams
1. `TransactionFormViewModel` 接缝：验证三档模式切换、`lastPlannedAutoPost` 与 `lastRepeatingAutoPost` 各自独立读取与持久化回写、`planned` 与 `repeating` 均按 `autoPost` 开关值保存。
2. `RecurringService.createSeries` 接缝：验证创建 `autoPost = true` 且起始日含过去或当天日期时，首轮物化中 `effectiveDate <= now` 的实例保持 `manualOnly = false`，并对当前币种当场自动生成已入账交易记录（跨币种静默留待切回弹窗）。
3. 交易新建表单 Widget 接缝：验证三档选择器渲染、「自动入账」开关在「计划」与「重复」均可见、`planned` 保持「计划」标签且各自记忆独立生效。

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
- [ ] 新建页仅保留「普通 / 计划 / 重复」三档入口，「自动入账」开关在「计划」与「重复」均可见且各自独立记忆上次选择（默认关闭），`planned` 始终保持「计划」标签；
- [ ] `planned` 与 `repeating` 均按开关值落库 `autoPost`；
- [ ] 创建 `autoPost = true` 规则且含当日或过去日期时不再打 `manualOnly` 拦截，保存后当场对当前币种自动入账并反馈结果；
- [ ] `flutter gen-l10n`、`flutter analyze` 零错误、全量测试绿灯。
