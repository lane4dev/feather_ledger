# 39: 补记中断接续及独立批次

Type: task
Triage: ready-for-agent
Status: resolved

Blocked by: 38

**交付：** 系统终止后恢复原批次，新增到期期次另建批次。

**先写失败测试：** 先测试处理一半终止并在新增到期后重启，两批次无重复。

**验收条件：**

- [ ] 后台尽力继续。
- [ ] 重启累计结果不丢，独立显示新批次。
- [ ] 历史未物化期次分批处理。
- [ ] 原子与幂等防重复。

**预计修改的生产文件：**

- `lib/features/ledger/domain/services/recurring_service.dart`
- `lib/features/ledger/domain/commands/convert_scheduled_to_posted_command.dart`
- `lib/core/data/database/tables.dart`

**预计修改的测试文件：**

- `test/unit/features/ledger/domain/services/convert_scheduled_to_posted_test.dart`
- `test/unit/features/ledger/domain/services/recurring_materialization_test.dart`

**预计新建的文件（实施时先核对是否可复用现有模块）：**

- 建议新建 `lib/features/ledger/domain/entities/automatic_posting_batch.dart`：批次和成员结果的领域表达。
- 建议新建 `test/unit/features/ledger/domain/services/automatic_posting_batch_test.dart`：跨中断的批次行为测试。
## 共同约束

- 先在已确认的公开测试接缝编写本票首个行为的失败测试，运行并确认失败；再以最小实现通过，逐条重复，不先批量编写所有测试。接缝为账本、账户、周期及备份 service 和真实测试数据库；界面与通知行为使用 widget 测试及现有通知平台适配边界。
- 预计文件按当前代码列出；实施前核对并优先复用现有模块。需要界面文案时同步 en、zh、zh_Hans、zh_Hant 四个 ARB 并运行生成器；Drift 和 Riverpod 生成文件由生成器更新。
- 任务 28 的自动入账保护在任务 48 验收前保持，测试可通过受控测试配置验证各阶段行为；任何阶段不得删除或重置现有数据。完成时运行适用测试及静态分析。
- 完整产品规则与范围以[多币种规格](../spec.md)为准；涉及尚未验证的期次身份、资格历史及恢复算法时，先用有界原型与行为测试验证，不能把候选实现视为既定事实。

## Answer

新增 `automatic_posting_batches` 与 `automatic_posting_batch_members` 两张 CRUD 豁免表（schemaVersion 10→11；`@DataClassName('...Row')` 遵循既有表命名约定）。`catchUpAutoPosted` 现在的流程：

- 先 `_resumeUnsettledMembers`：把所有 `pending`/`failed` 的成员按其**原批次** `batchId` 重新结算（`_settleMember`），结果写回原批次——累计结果不丢。
- 再为本轮 `now` 建一个新批次，主循环里 `isAutomaticPostingMember(id)` 为真即跳过：一笔账单只属于一个批次，已存在批次保持其范围与结果，新到期期次才进新批次（US39）。
- 结算本身幂等：`ConvertScheduledToPostedCommand` 的确定性 `commandId`（`autopost-<instanceId>`）在 append 时去重，`insertOnConflictUpdate` 使重复声明安全（US52）。

验收：'a pending member from an interrupted run resumes without double posting'（中断的 pending 成员在原批次结算为 succeeded，账单只贴一次）；'a failed member retries and updates its original batch result'（failed 原地重试为 succeeded）。
