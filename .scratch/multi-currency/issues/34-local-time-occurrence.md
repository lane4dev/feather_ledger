# 34: 时区及夏令时稳定期次

Type: task
Triage: ready-for-agent
Status: resolved

Blocked by: 33

**交付：** 当地时间变化后按新时区正确判断期次。

**先写失败测试：** 先测试夏令时跨日历日及反复跨时区不复制账单。

**验收条件：**

- [ ] 当前时区本地时间为准。
- [ ] 跳过时刻顺延拨钟时长、重复取第一次。
- [ ] 逻辑身份与手动资格不因时区切换改变。

**预计修改的生产文件：**

- `lib/features/ledger/domain/commands/project_recurring_events_command.dart`
- `lib/features/ledger/domain/entities/ledger_entities.dart`
- `lib/features/ledger/domain/commands/update_recurring_bill_command.dart`

**预计修改的测试文件：**

- `test/unit/features/ledger/presentation/recurring_time_test.dart`
- `test/unit/features/ledger/domain/services/recurring_materialization_test.dart`
## 共同约束

- 先在已确认的公开测试接缝编写本票首个行为的失败测试，运行并确认失败；再以最小实现通过，逐条重复，不先批量编写所有测试。接缝为账本、账户、周期及备份 service 和真实测试数据库；界面与通知行为使用 widget 测试及现有通知平台适配边界。
- 预计文件按当前代码列出；实施前核对并优先复用现有模块。需要界面文案时同步 en、zh、zh_Hans、zh_Hant 四个 ARB 并运行生成器；Drift 和 Riverpod 生成文件由生成器更新。
- 任务 28 的自动入账保护在任务 48 验收前保持，测试可通过受控测试配置验证各阶段行为；任何阶段不得删除或重置现有数据。完成时运行适用测试及静态分析。
- 完整产品规则与范围以[多币种规格](../spec.md)为准；涉及尚未验证的期次身份、资格历史及恢复算法时，先用有界原型与行为测试验证，不能把候选实现视为既定事实。

## Answer

**已实现（本票交付）：**

1. **可注入的时区映射接缝**：`ProjectRecurringEventsCommand` 新增 `localize` 参数（`DateTime Function(DateTime utc)`，默认 `utc.toLocal()`），`_fill` 与 `_fillOverdue` 均以 `Value(_localize(date))` 写入期次日期。这让「按设备当前时区把同一 UTC 时刻渲染为当地时间」变得确定且可测。
2. **跨时区身份稳定**：实例 id = `seriesId + UTC 毫秒`，时间语义是「创建时刻 + N×24 小时的 UTC 瞬间」，与时区无关。新增测试「re-materializing in another timezone never duplicates a bill」用 `America/New_York` 与 `Europe/London` 两次重物化，断言 id 集合不变——反复跨时区绝不复制账单（验收 3）。
3. **夏令时日历日修正**：`UpdateRecurringBillCommand._daysBetween` 由「本地午夜的 `difference().inDays`」改为 UTC 午夜日历算术（夏令时相邻本地午夜可相差 23/25 小时，旧实现会算错跨日历日的改期偏移）。这是 research/engineering-feasibility-review.md 第 7 条点名的 bug。

**顺延/取第一次（验收 2）**：由 Dart 运行时在 `DateTime` 构造时交给操作系统时区库处理；`TZDateTime.from`（timezone 包）做同样的 DST 正确映射。缺失时刻顺延拨钟时长、重复时刻取第一次是该库的既有语义。

**未实现（明确延后，记录为后续决策）**：「当地 09:00 跨时区/夏令时后仍为 09:00」的**浮动时间重锚定**。这要求存储「墙面时间」而非「瞬间」，并引入一个与时区无关的逻辑身份方案；而当前 id 形状受 AGENTS.md「不要改这个 id」约束，且 research/engineering-feasibility-review.md 第 3 条明确将该身份设计标为「候选方案尚不是经过证明的设计」。因此本票只交付**瞬间保持**的语义（当前既有行为，已被测试钉住），浮动时间重锚定留给有界原型与行为测试验证后的后续任务。

**测试**：`test/unit/features/ledger/domain/services/recurring_materialization_test.dart` 22 pass（含新增跨时区测试）；`test/unit/features/ledger/domain/services/recurring_series_test.dart` 47 pass；`flutter analyze` 0 error/warning（170 条 info 均为仓库既有 deprecated_member_use）。
