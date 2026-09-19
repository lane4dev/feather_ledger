# 47: 来源账单与交易更正可重建

Type: task
Triage: ready-for-agent

Blocked by: 45、46

**交付：** 入账旧通知始终指向最新交易或已删除状态。

**先写失败测试：** 先测试账单入账、更正两次、重建后旧通知定位最新交易。

**验收条件：**

- [ ] 新交易事件保存来源账单及更正关联。
- [ ] 多次更正后打开最新交易。
- [ ] 删除后提示已删除。
- [ ] 事件重建和备份恢复等价，不重复记账。

**预计修改的生产文件：**

- `lib/features/ledger/domain/events/ledger_events.dart`
- `lib/features/ledger/domain/commands/convert_scheduled_to_posted_command.dart`
- `lib/features/ledger/domain/commands/correct_transaction_command.dart`
- `lib/features/ledger/data/projections/ledger_projector.dart`
- `lib/features/ledger/presentation/notifications/reminder_response_handler.dart`

**预计修改的测试文件：**

- `test/unit/features/ledger/domain/services/projection_rebuild_equivalence_test.dart`
- `test/ui/features/ledger/reminder_response_handler_test.dart`

**预计新建的文件（实施时先核对是否可复用现有模块）：**

- 建议新建 `test/unit/features/ledger/domain/services/source_bill_rebuild_test.dart`：来源账单关联的重建测试。
## 共同约束

- 先在已确认的公开测试接缝编写本票首个行为的失败测试，运行并确认失败；再以最小实现通过，逐条重复，不先批量编写所有测试。接缝为账本、账户、周期及备份 service 和真实测试数据库；界面与通知行为使用 widget 测试及现有通知平台适配边界。
- 预计文件按当前代码列出；实施前核对并优先复用现有模块。需要界面文案时同步 en、zh、zh_Hans、zh_Hant 四个 ARB 并运行生成器；Drift 和 Riverpod 生成文件由生成器更新。
- 任务 28 的自动入账保护在任务 48 验收前保持，测试可通过受控测试配置验证各阶段行为；任何阶段不得删除或重置现有数据。完成时运行适用测试及静态分析。
- 完整产品规则与范围以[多币种规格](../spec.md)为准；涉及尚未验证的期次身份、资格历史及恢复算法时，先用有界原型与行为测试验证，不能把候选实现视为既定事实。
