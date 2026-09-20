# 40: 补记失败重试和用户竞争

Type: task
Triage: ready-for-agent
Status: resolved

Blocked by: 39

**交付：** 失败账单和用户先行处理会更新原批次结果。

**先写失败测试：** 先测试成功 9 失败 1 后重试成功变成成功 10 失败 0。

**验收条件：**

- [ ] 失败留原月份可重试或手动。
- [ ] 重试成功替代失败计数。
- [ ] 手动记入或删除计用户处理。
- [ ] 实际修改计转手动，每笔仅一类。

**预计修改的生产文件：**

- `lib/features/ledger/domain/services/recurring_service.dart`
- `lib/features/ledger/domain/commands/convert_scheduled_to_posted_command.dart`
- `lib/features/ledger/domain/commands/update_recurring_bill_command.dart`

**预计修改的测试文件：**

- `test/unit/features/ledger/domain/services/recurring_series_test.dart`
- `test/unit/features/ledger/domain/services/convert_scheduled_to_posted_test.dart`
## 共同约束

- 先在已确认的公开测试接缝编写本票首个行为的失败测试，运行并确认失败；再以最小实现通过，逐条重复，不先批量编写所有测试。接缝为账本、账户、周期及备份 service 和真实测试数据库；界面与通知行为使用 widget 测试及现有通知平台适配边界。
- 预计文件按当前代码列出；实施前核对并优先复用现有模块。需要界面文案时同步 en、zh、zh_Hans、zh_Hant 四个 ARB 并运行生成器；Drift 和 Riverpod 生成文件由生成器更新。
- 任务 28 的自动入账保护在任务 48 验收前保持，测试可通过受控测试配置验证各阶段行为；任何阶段不得删除或重置现有数据。完成时运行适用测试及静态分析。
- 完整产品规则与范围以[多币种规格](../spec.md)为准；涉及尚未验证的期次身份、资格历史及恢复算法时，先用有界原型与行为测试验证，不能把候选实现视为既定事实。

## Answer

结果在原批次原地更新：`_resumeUnsettledMembers` 对 `failed` 成员重新走 `_settleMember`，重试成功则把该成员结果改写为 `succeeded`，不另建批次（US53）。`_settleMember` 的归类：

- 账单已被用户贴/删/跳过（`status != scheduled`）→ `userHandled`；`ConvertScheduledToPostedCommand` 的 `scheduledAlreadyPosted`/`transactionNotFound` 也归为 `userHandled`（并发用户操作）。
- 资格判定不通过（开关关闭/边界/币种未激活/`autoPostEligible == false`）→ `manual`，并 latch 一次。
- 其余失败 → `failed`，留待下次启动重试。
- 每笔在同一批次只持有一个当前结果（复合主键 `{batchId, scheduledId}` + 主循环 `isAutomaticPostingMember` 跳过）。

验收：'a failed member retries and updates its original batch result'（失败→重试→succeeded）；'a bill the user already posted is recorded as user-handled'（用户已贴→userHandled，不重复贴账）。
