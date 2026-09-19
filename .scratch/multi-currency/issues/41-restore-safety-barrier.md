# 41: 恢复屏障与未物化候选

Type: task
Triage: ready-for-agent

Blocked by: 30、33、39

**交付：** 恢复后任何入口不会绕过待确认屏障。

**先写失败测试：** 先构造恢复后重启及旧备份未物化候选，断言未确认无入账。

**验收条件：**

- [ ] 备份后至恢复前到期含未物化期次纳入候选。
- [ ] 目标设备设置生效。
- [ ] 恢复事务中断重试不自动误记或部分提交。

**预计修改的生产文件：**

- `lib/features/settings/domain/services/backup_service.dart`
- `lib/main.dart`
- `lib/features/ledger/domain/services/recurring_service.dart`
- `lib/core/data/database/tables.dart`

**预计修改的测试文件：**

- `test/unit/features/settings/data/backup_service_test.dart`
- `test/ui/features/settings/backup_screen_test.dart`

**预计新建的文件（实施时先核对是否可复用现有模块）：**

- 建议新建 `lib/features/settings/domain/models/restore_confirmation_batch.dart`：待确认批次领域数据。
- 建议新建 `test/unit/features/settings/domain/restore_confirmation_test.dart`：恢复屏障与候选完整性测试。
## 共同约束

- 先在已确认的公开测试接缝编写本票首个行为的失败测试，运行并确认失败；再以最小实现通过，逐条重复，不先批量编写所有测试。接缝为账本、账户、周期及备份 service 和真实测试数据库；界面与通知行为使用 widget 测试及现有通知平台适配边界。
- 预计文件按当前代码列出；实施前核对并优先复用现有模块。需要界面文案时同步 en、zh、zh_Hans、zh_Hant 四个 ARB 并运行生成器；Drift 和 Riverpod 生成文件由生成器更新。
- 任务 28 的自动入账保护在任务 48 验收前保持，测试可通过受控测试配置验证各阶段行为；任何阶段不得删除或重置现有数据。完成时运行适用测试及静态分析。
- 完整产品规则与范围以[多币种规格](../spec.md)为准；涉及尚未验证的期次身份、资格历史及恢复算法时，先用有界原型与行为测试验证，不能把候选实现视为既定事实。
