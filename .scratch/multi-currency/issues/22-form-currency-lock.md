# 22: 交易表单锁定币种

Type: task
Triage: ready-for-agent

Blocked by: 18、21

**交付：** 新建及编辑表单始终只选择原币种账户。

**先写失败测试：** 先测试填到一半切换设置后仍按表单原币种保存。

**验收条件：**

- [ ] 打开表单后设置变化不清空输入或改变币种。
- [ ] 编辑现有交易及转账只能选择原币种账户。

**预计修改的生产文件：**

- `lib/features/ledger/presentation/view_model/transaction_form_view_model.dart`
- `lib/features/ledger/presentation/view_model/transaction_form_view_state.dart`
- `lib/features/ledger/presentation/screens/transaction_form_screen.dart`

**预计修改的测试文件：**

- `test/unit/features/ledger/presentation/transaction_form_view_model_test.dart`
- `test/ui/features/ledger/transfer_form_screen_test.dart`
## 共同约束

- 先在已确认的公开测试接缝编写本票首个行为的失败测试，运行并确认失败；再以最小实现通过，逐条重复，不先批量编写所有测试。接缝为账本、账户、周期及备份 service 和真实测试数据库；界面与通知行为使用 widget 测试及现有通知平台适配边界。
- 预计文件按当前代码列出；实施前核对并优先复用现有模块。需要界面文案时同步 en、zh、zh_Hans、zh_Hant 四个 ARB 并运行生成器；Drift 和 Riverpod 生成文件由生成器更新。
- 任务 28 的自动入账保护在任务 48 验收前保持，测试可通过受控测试配置验证各阶段行为；任何阶段不得删除或重置现有数据。完成时运行适用测试及静态分析。
- 完整产品规则与范围以[多币种规格](../spec.md)为准；涉及尚未验证的期次身份、资格历史及恢复算法时，先用有界原型与行为测试验证，不能把候选实现视为既定事实。
