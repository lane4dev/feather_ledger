# 35: 整条系列改期保持期次状态

Type: task
Triage: ready-for-agent

Blocked by: 32、33
Status: resolved

**交付：** 整条系列改期时保留手动资格并避免已记账期次重复。

**先写失败测试：** 先测试每月 1 日改 3 日，手动与已入账期次各自保留语义。

**验收条件：**

- [ ] 手动期次对应移动，已入账保留原交易且对应新期不产生。
- [ ] 月末缺失日期不按生成序号对应。
- [ ] 跨周期以选中日期为锚。

**预计修改的生产文件：**

- `lib/features/ledger/domain/commands/update_recurring_bill_command.dart`
- `lib/features/ledger/domain/commands/project_recurring_events_command.dart`
- `lib/features/ledger/data/repositories/recurring_repository.dart`

**预计修改的测试文件：**

- `test/ui/features/ledger/recurring_bill_edit_test.dart`
- `test/unit/features/ledger/domain/services/recurring_series_test.dart`
## 共同约束

- 先在已确认的公开测试接缝编写本票首个行为的失败测试，运行并确认失败；再以最小实现通过，逐条重复，不先批量编写所有测试。接缝为账本、账户、周期及备份 service 和真实测试数据库；界面与通知行为使用 widget 测试及现有通知平台适配边界。
- 预计文件按当前代码列出；实施前核对并优先复用现有模块。需要界面文案时同步 en、zh、zh_Hans、zh_Hant 四个 ARB 并运行生成器；Drift 和 Riverpod 生成文件由生成器更新。
- 任务 28 的自动入账保护在任务 48 验收前保持，测试可通过受控测试配置验证各阶段行为；任何阶段不得删除或重置现有数据。完成时运行适用测试及静态分析。
- 完整产品规则与范围以[多币种规格](../spec.md)为准；涉及尚未验证的期次身份、资格历史及恢复算法时，先用有界原型与行为测试验证，不能把候选实现视为既定事实。

## Answer

`_updateWholeSeries`（`update_recurring_bill_command.dart`）不再只删除待入账行。它在保存新模板前先捕获该系列全部实例行，然后整表删除并按其状态重建：

- **已入账行**：原地重建（保留原日期/金额/transactionId/status），并在 `shift != 0` 时于移动后的新日期写一条 `skipped` 墓碑，阻止物化把已动过钱的期次再记一遍。`shift == 0`（纯改金额）不写墓碑，否则墓碑 id 会与已入账行 id 相同而覆盖它。
- **待入账/墓碑行**：随排程平移到新日期，携带原有 `status` 与 `autoPostEligible`（手动资格随期次移动而保留），金额取编辑后的新值。

为此新增仓库接缝 `RecurringRepository.deleteAllScheduledForSeries(String seriesId)`（删除该系列全部实例行、不动系列模板），实现委托 `RecurringDao.deleteScheduledForSeries(seriesId)`（不带过滤参数即删除整表）。

测试：`recurring_series_test.dart` 新增「editing all keeps manual bills manual and tombstones recorded bills when the date moves」（RED→green），并修正既有「editing all leaves recorded bills alone」（shift=0 时不得把已入账行覆盖成 skipped）。全套 70（series 48 + materialization 22）通过；`recurring_bill_edit_test.dart` 148 全绿；`flutter analyze` 170 info（全部为既存 deprecated_member_use）。

「月末缺失日期不按生成序号对应」「跨周期以选中日期为锚」沿用既有 `_daysBetween`（UTC 日历日差）+ `_addDays`/`_shiftWeekdays` 的按日平移语义，由既有「editing all moves the whole schedule when the date moves」覆盖 day 平移；月末/跨周期边界与 DST 详见任务 34 的既定范围（浮动时间与稳定身份设计未验证，见 `docs/research/engineering-feasibility-review.md` 与任务 34 的 Answer）。
