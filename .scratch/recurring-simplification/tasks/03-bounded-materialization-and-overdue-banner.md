# 03: 有限前瞻物化窗口与历史回溯补齐 Banner

**What to build:** 保留未来前瞻窗口为「未来 90 天最多 3 期（保底 1 期）」并移除 3 年兜底与 `skipped` 顺延补齐（`skipped` 正常消耗 `countLimit`），跳过 `isActive = false` 或归档账户的规则；**历史期次改为从 `startDate` 起全量补齐所有缺失历史实例且不设硬截断上限**（取消 30 天 / 3 期截断），开启 `autoPost` 者由自动入账生成已入账交易记录、关闭 `autoPost` 者保留为 `scheduled` 待入账记录；`newlyMaterializedOverdueCount` **仅统计新补齐且不会自动入账、需手动核对的过期实例**（`autoPost == false` 或 `manualOnly == true`），大于 0 时在账本页顶部展示纯会话级可关闭非阻塞 Banner（`"新补齐了 N 笔已到期账单"`）。

**Blocked by:** 01: Schema v15 洁净重构与废旧状态机清除

**Status:** ready-for-agent

## Pre-agreed TDD Seams
1. `ProjectRecurringEventsCommand` / `RecurringService.materialize` 接缝：验证未来 90 天最多 3 期、跨度超 90 天保底 1 期、**从 `startDate` 到 `now` 全量补齐所有缺失历史发生日（无天数/期数截断上限）**、`skipped` 计入 `countLimit` 而不顺延、跳过 `isActive = false` 与已归档账户、`newlyMaterializedOverdueCount` 仅计 `!autoPost || manualOnly` 的新补齐过期实例、重复调用幂等。
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
- [ ] 未来窗口（90 天最多 3 期 / 保底 1 期）严格生效，历史缺失期次从 `startDate` 起全量补齐且幂等，无 3 年未来兜底扫描与 30 天/3 期历史截断；
- [ ] 有限次数规则 `skipped` 一期正常消耗 `countLimit`，不再在末尾顺延补期；
- [ ] 补齐待手动处理的过期账单后账本页展示可关闭会话级 Banner，且无任何截断弹窗；
- [ ] `flutter gen-l10n`、`flutter analyze` 零错误、全量测试绿灯。
