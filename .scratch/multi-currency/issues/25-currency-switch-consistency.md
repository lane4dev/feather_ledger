# 25: 切换币种时的异步一致性

Type: task
Triage: ready-for-agent
Status: resolved

Blocked by: 23、24

**交付：** 快速切币不会以新符号标旧数据。

**先写失败测试：** 先延迟旧币种结果并验证切换后不能覆盖新结果。

**验收条件：**

- [ ] 快速切换及相邻月份缓存中金额、标签及空状态一致。
- [ ] 旧请求迟到不会覆盖新币种结果。

**预计修改的生产文件：**

- `lib/features/ledger/presentation/view_model/ledger_view_model.dart`
- `lib/features/ledger/presentation/view_model/ledger_view_state.dart`
- `lib/features/ledger/presentation/screens/ledger_screen.dart`

**预计修改的测试文件：**

- `test/ui/features/ledger/ledger_month_switch_test.dart`
- `test/unit/features/ledger/presentation/ledger_currency_test.dart`
## 共同约束

- 先在已确认的公开测试接缝编写本票首个行为的失败测试，运行并确认失败；再以最小实现通过，逐条重复，不先批量编写所有测试。接缝为账本、账户、周期及备份 service 和真实测试数据库；界面与通知行为使用 widget 测试及现有通知平台适配边界。
- 预计文件按当前代码列出；实施前核对并优先复用现有模块。需要界面文案时同步 en、zh、zh_Hans、zh_Hant 四个 ARB 并运行生成器；Drift 和 Riverpod 生成文件由生成器更新。
- 任务 28 的自动入账保护在任务 48 验收前保持，测试可通过受控测试配置验证各阶段行为；任何阶段不得删除或重置现有数据。完成时运行适用测试及静态分析。
- 完整产品规则与范围以[多币种规格](../spec.md)为准；涉及尚未验证的期次身份、资格历史及恢复算法时，先用有界原型与行为测试验证，不能把候选实现视为既定事实。

## Answer

ledgerCurrency 改为以设置为唯一来源（不再由账户推导），列表、头部、符号一致；快速切换与相邻月份缓存一致，迟到的旧订阅不覆盖新结果。见 ledger_view_model.dart、ledger_currency_test.dart、ledger_summary_currency_test.dart。
