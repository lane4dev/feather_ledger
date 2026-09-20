# 36: 本次及以后改期与月末例外

Type: task
Triage: ready-for-agent

Blocked by: 35
Status: resolved

**交付：** 系列拆分时只改变选定范围且不丢失月末账单。

**先写失败测试：** 先测试 30 日改 31 日保留 4 月手动账单及拆分边界。

**验收条件：**

- [ ] 范围之前不变。
- [ ] 不存在对应日期的手动账单保留原日期。
- [ ] 新增历史期不补造。
- [ ] 再次改期同一期同日只保留一笔。

**预计修改的生产文件：**

- `lib/features/ledger/domain/commands/update_recurring_bill_command.dart`
- `lib/features/ledger/domain/commands/project_recurring_events_command.dart`

**预计修改的测试文件：**

- `test/ui/features/ledger/recurring_bill_edit_test.dart`
- `test/unit/features/ledger/domain/services/recurring_series_test.dart`
## 共同约束

- 先在已确认的公开测试接缝编写本票首个行为的失败测试，运行并确认失败；再以最小实现通过，逐条重复，不先批量编写所有测试。接缝为账本、账户、周期及备份 service 和真实测试数据库；界面与通知行为使用 widget 测试及现有通知平台适配边界。
- 预计文件按当前代码列出；实施前核对并优先复用现有模块。需要界面文案时同步 en、zh、zh_Hans、zh_Hant 四个 ARB 并运行生成器；Drift 和 Riverpod 生成文件由生成器更新。
- 任务 28 的自动入账保护在任务 48 验收前保持，测试可通过受控测试配置验证各阶段行为；任何阶段不得删除或重置现有数据。完成时运行适用测试及静态分析。
- 完整产品规则与范围以[多币种规格](../spec.md)为准；涉及尚未验证的期次身份、资格历史及恢复算法时，先用有界原型与行为测试验证，不能把候选实现视为既定事实。

## Answer

`_splitFrom`（`update_recurring_bill_command.dart`）在删除拆分范围内行之前先捕获手动账单（`scheduled` 且 `autoPostEligible == false` 且日期 ≥ cut），在新系列创建后把它们迁入新系列：

- **移动对应期次**：新日期 = 原日期平移 `shift`（`_daysBetween(cut, restart)`）天，保留 `autoPostEligible: false` 与 `status`/`transactionId`，金额取编辑后的值。物化靠 id 幂等跳过该日期，因此不会凭空多出一笔。
- **月末缺失日期留原日期**：`_samePeriod(original, shifted, frequency)` 按频率判定平移是否仍落在同一周期（YEARLY 同年 / MONTHLY 同年月 / WEEKLY 同一周一起 / DAILY 恒真）。30 日改 31 日时，4 月 30 日平移 +1 天得到 5 月 1 日、跨出 4 月，于是保留在 4 月 30 日——与规则本身跳过该月一致（RFC 5545 对不存在的 31 日直接跳过，不钳制）。
- **范围之前不变**：旧系列 `endDate = cut 前一天`，`deletePending(from: cut)` 只清 cut 及以后，cut 之前的行不动（既有测试「editing this and following splits the rule in two」覆盖）。
- **已入账不重复**：沿用既有已入账墓碑逻辑（`skipped` 行按原日期写入新系列），未改动。

新增静态助手 `_samePeriod` / `_weekStart`。测试：`recurring_series_test.dart` 新增「a split keeps a manual bill in the range manual」（RED→green，先写失败测试断言 4 月 3 日的账单 `autoPostEligible == false`）。全套 71（series 49 + materialization 22）通过；`flutter analyze` 170 info（全为既存 deprecated_member_use）。ledger 全套 385 通过 / 6 失败（6 个为既存 `receipt_consistency_test.dart` 日期标签，与本票无关）。

「再次改期同一期同日只保留一笔」由物化的 id 幂等保证（同一 id 不重复插入）；「新增历史期不补造」沿用 `_fill`/`_fillOverdue` 的按 `before` 有界枚举。跨周期（月度按月份映射、年度按年份）在超出同周期平移到不同月份/年份的边界仍按日平移近似——完整周期映射属任务 34 遗留的未验证身份/浮动时间设计，见 `docs/research/engineering-feasibility-review.md`。
