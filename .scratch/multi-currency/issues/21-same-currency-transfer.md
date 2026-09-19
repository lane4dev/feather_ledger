# 21: 写入时拒绝跨币种转账

Type: task
Triage: ready-for-agent

Blocked by: 18

**交付：** 同币种转账正常，任何写入入口拒绝跨币种。

**先写失败测试：** 先通过公开服务提交跨币种转账并断言拒绝且无事件。

**验收条件：**

- [ ] 同币种不同账户成功。
- [ ] 跨币种或同账户拒绝。
- [ ] 聚合验证与 posting context 校验覆盖服务入口。

**预计修改的生产文件：**

- `lib/features/ledger/domain/model/transaction.dart`
- `lib/features/ledger/domain/services/posting_context.dart`
- `lib/features/ledger/domain/commands/record_transaction_command.dart`
- `lib/features/ledger/domain/commands/correct_transaction_command.dart`

**预计修改的测试文件：**

- `test/unit/features/ledger/domain/ledger_transfer_test.dart`
- `test/unit/features/ledger/domain/services/transfer_correction_test.dart`
## 共同约束

- 先在已确认的公开测试接缝编写本票首个行为的失败测试，运行并确认失败；再以最小实现通过，逐条重复，不先批量编写所有测试。接缝为账本、账户、周期及备份 service 和真实测试数据库；界面与通知行为使用 widget 测试及现有通知平台适配边界。
- 预计文件按当前代码列出；实施前核对并优先复用现有模块。需要界面文案时同步 en、zh、zh_Hans、zh_Hant 四个 ARB 并运行生成器；Drift 和 Riverpod 生成文件由生成器更新。
- 任务 28 的自动入账保护在任务 48 验收前保持，测试可通过受控测试配置验证各阶段行为；任何阶段不得删除或重置现有数据。完成时运行适用测试及静态分析。
- 完整产品规则与范围以[多币种规格](../spec.md)为准；涉及尚未验证的期次身份、资格历史及恢复算法时，先用有界原型与行为测试验证，不能把候选实现视为既定事实。
