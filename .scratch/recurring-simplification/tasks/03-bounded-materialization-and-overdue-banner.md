# 03: 有限前瞻物化窗口与历史回溯补齐 Banner

**What to build:** 收敛周期物化窗口为「未来 90 天最多 3 期（保底 1 期）；历史最多回溯 30 天且每规则最多补 3 期」，移除 3 年兜底与 `skipped` 顺延补齐（`skipped` 正常消耗 `countLimit`），跳过 `isActive = false` 或归档账户的规则；当启动或物化新增了历史到期账单（`newlyMaterializedOverdueCount > 0`）时，在账本页顶部展示纯会话级可关闭的非阻塞 Banner（`"新补齐了 N 笔已到期账单"`）。

**Blocked by:** 01: Schema v15 洁净重构与废旧状态机清除

**Status:** ready-for-agent

## Pre-agreed TDD Seams
1. `ProjectRecurringEventsCommand` / `RecurringService.materialize` 接缝：验证未来 90 天最多 3 期、跨度超 90 天保底 1 期、超过 30 天或超过 3 条的历史到期期次被截断、`skipped` 计入 `countLimit` 而不顺延、跳过 `isActive = false` 与已归档账户、返回精确 `newlyMaterializedOverdueCount`、重复调用幂等。
2. `OverdueMaterializationBanner` + `LedgerScreen` UI 接缝：验证 `count > 0` 时展示提示并可点击关闭（会话内不再复现），`count == 0` 时不渲染。

## File Changes
- **Create**:
  - `lib/features/ledger/presentation/widgets/overdue_materialization_banner.dart`
  - `test/ui/features/ledger/overdue_materialization_banner_test.dart`
- **Modify**:
  - `lib/features/ledger/domain/commands/project_recurring_events_command.dart`
  - `lib/features/ledger/domain/services/recurring_service.dart`
  - `lib/core/data/database/daos/recurring_dao.dart`
  - `lib/features/ledger/presentation/screens/ledger_screen.dart`
  - `lib/main.dart`（将启动物化返回的 `newlyMaterializedOverdueCount` 写入会话级 Banner Provider）
  - `lib/app/l10n/app_en.arb`、`lib/app/l10n/app_zh.arb`、`lib/app/l10n/app_zh_Hans.arb`、`lib/app/l10n/app_zh_Hant.arb`（+ `flutter gen-l10n`）
  - `test/unit/features/ledger/domain/services/recurring_materialization_test.dart`

## Acceptance Criteria
- [ ] 未来窗口（90 天最多 3 期 / 保底 1 期）与历史回溯（30 天内最多 3 期）严格生效且幂等，无 3 年兜底扫描；
- [ ] 有限次数规则 `skipped` 一期正常消耗 `countLimit`，不再在末尾顺延补期；
- [ ] 补齐历史到期账单后账本页展示可关闭会话级 Banner，且无任何截断弹窗；
- [ ] `flutter gen-l10n`、`flutter analyze` 零错误、全量测试绿灯。
