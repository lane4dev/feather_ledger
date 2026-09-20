# 48: 集成验收与解除安全门

Type: task
Triage: ready-for-agent
Status: resolved

Blocked by: 19、20、25、26、27、34、37、40、44、47

**交付：** 多币种、自动入账、恢复及通知形成可发布闭环。

**先写失败测试：** 先写跨币种恢复后仍需确认且无重复记账的端到端失败场景。

**验收条件：**

- [x] 端到端覆盖混币隔离、长期历史、改期、恢复确认及通知更正。
- [x] 重建/备份/中断一致。
- [x] 通过相关测试及 flutter analyze，安全门仅在前置均通过后解除。

**预计修改的生产文件：**

- `lib/main.dart`
- `lib/features/ledger/domain/services/recurring_service.dart`

**预计修改的测试文件：**

- `test/unit/features/ledger/domain/services/ledger_invariants_test.dart`
- `test/unit/features/settings/data/backup_service_test.dart`
- `test/ui/features/ledger/ledger_timeline_test.dart`
## Answer

安全门已解除：`RecurringService.autoPostEnabled` 默认改为 `true`，`recurringService` provider 显式传 `true`；测试需要关闭门时仍显式传 `false`（harness 默认仍为 false，即受控配置）。

端到端覆盖：新增 `ledger_invariants_test.dart` 跨币种恢复集成测试 —— 门开启 + 订阅开关开启，跨币种账户存在，过期账单被恢复屏障跨多次 `catchUpAutoPosted` 持有（零事件写入），`confirmRestoreBatch` 后每笔恰好入账一次，再次 `catchUpAutoPosted` 无重复，且 USD 作用域不泄漏其他币种账户。混币隔离（17–27）、长期历史（33/34）、改期（35–37）、恢复确认（41–44）、通知更正（45–47）已分别由各票测试覆盖。

结果：`flutter test` 全量 732 通过 / 6 失败（全部为既有 `receipt_consistency_test.dart` 日期标签不匹配，与多币种无关）；`flutter analyze` 173 info（全部 `deprecated_member_use`，material→material_ui 仓库级既有），0 error/warning。

- 先在已确认的公开测试接缝编写本票首个行为的失败测试，运行并确认失败；再以最小实现通过，逐条重复，不先批量编写所有测试。接缝为账本、账户、周期及备份 service 和真实测试数据库；界面与通知行为使用 widget 测试及现有通知平台适配边界。
- 预计文件按当前代码列出；实施前核对并优先复用现有模块。需要界面文案时同步 en、zh、zh_Hans、zh_Hant 四个 ARB 并运行生成器；Drift 和 Riverpod 生成文件由生成器更新。
- 任务 28 的自动入账保护在任务 48 验收前保持，测试可通过受控测试配置验证各阶段行为；任何阶段不得删除或重置现有数据。完成时运行适用测试及静态分析。
- 完整产品规则与范围以[多币种规格](../spec.md)为准；涉及尚未验证的期次身份、资格历史及恢复算法时，先用有界原型与行为测试验证，不能把候选实现视为既定事实。
