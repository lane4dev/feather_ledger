# 04: 规则编辑完整性、事务原子性与账户归档修正

Triage: ready-for-agent
Status: resolved

**Blocked by:** 01 · 本地日历日展开内核、Schema 升级与自然月物理物化

关联规格见 [spec.md](../spec.md)。

**What to build:** 根治周期规则编辑与账户归档中的数据完整性缺陷：修复限次规则经 `updateRule` 改排期时的总次数膨胀与二次编辑重复扣减，保证更新与停用规则的单事务原子性，阻止单期改期在同一天产生同系列双账单，并修正账户归档时的互斥字段冲突与历史源账单断链。

## 验收标准

- [x] `UpdateRecurringBillCommand` 在 `updateRule` 修改基础排期并重置 `startDate` 时，在同一事务内将 `completed_count_offset` 幂等重算为该系列当前已 `posted` 行数 `k`（校验 `countLimit >= k + 1`），`count_limit` 始终保持生命周期总次数；`RecurrenceExpander` 以 `countLimit - completedCountOffset` 推进剩余期次，确保历史已入账与新规则未来期次之和严格等于目标 `countLimit`，且多次连续修改排期不会重复扣减 `k`。
- [x] `UpdateRecurringBillCommand`（保存模板 + 清理过期 `scheduled/failed/skipped` 或重置 `failed`）与 `DeleteRecurringBillCommand`（软停用 `isActive = false` + 清理非 `posted` 实例）各自完整包裹在单一数据库事务内，任一步失败整体回滚。
- [x] `UpdateRecurringBillCommand` 在 `thisOnly` 作用域修改 `dateOverride` 时，校验同系列是否存在其他非 `skipped` 实例的有效日期落在同一本地日历日；若碰撞则拒绝并抛出 `CommandRejected(LedgerErrorCode.scheduledDateTaken, ...)`。
- [x] 账户归档将已到期未处理账单转存为一次性 `planned` 待办时，仅设置 `startDate == endDate`、保持 `countLimit == null`（遵守两者互斥不变量，确保保留的逾期计划单可被正常编辑）；原周期系列置为 `isActive = false` 并仅删除未入账与已跳过实例，保留历史 `posted` 实例行以维持 `sourceScheduledBillId` 溯源不断链；恢复归档账户仍不复活已停用规则。
- [x] 通过 `LedgerServiceHarness` 端到端验证：限次规则入账 3 期后连续两次 `updateRule` 改排期仍严格产生总计 `countLimit` 期；`thisOnly` 同日碰撞返回 `scheduledDateTaken`；归档账户后逾期 `planned` 单可编辑、历史 `posted` 关联完整、恢复账户不复活原系列。
- [x] `flutter analyze` 无新增错误或警告，全部相关单测通过。
