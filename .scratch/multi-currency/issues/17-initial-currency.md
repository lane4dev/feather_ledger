# 17: 首次语言映射与币种偏好

Type: task
Triage: ready-for-agent

Blocked by: 无

**交付：** 首次按语言选择币种，设置及重启后保留用户选择。

**先写失败测试：** 从 en-GB 首次 USD 和重启不覆盖两个行为各写一个失败测试。

**验收条件：**

- [ ] 中文/日语/英语/德语/法语及其他语言映射正确，en-GB 为 USD。
- [ ] 已保存选择不随语言变化。
- [ ] 新模型备份恢复币种。

**预计修改的生产文件：**

- `lib/core/presentation/providers/currency_provider.dart`
- `lib/app/config/app_currencies.dart`
- `lib/core/data/repositories/preferences_repository.dart`

**预计修改的测试文件：**

- `test/unit/core/presentation/currency_controller_test.dart`
- `test/unit/core/data/repositories/preferences_repository_backup_test.dart`
## 共同约束

- 先在已确认的公开测试接缝编写本票首个行为的失败测试，运行并确认失败；再以最小实现通过，逐条重复，不先批量编写所有测试。接缝为账本、账户、周期及备份 service 和真实测试数据库；界面与通知行为使用 widget 测试及现有通知平台适配边界。
- 预计文件按当前代码列出；实施前核对并优先复用现有模块。需要界面文案时同步 en、zh、zh_Hans、zh_Hant 四个 ARB 并运行生成器；Drift 和 Riverpod 生成文件由生成器更新。
- 任务 28 的自动入账保护在任务 48 验收前保持，测试可通过受控测试配置验证各阶段行为；任何阶段不得删除或重置现有数据。完成时运行适用测试及静态分析。
- 完整产品规则与范围以[多币种规格](../spec.md)为准；涉及尚未验证的期次身份、资格历史及恢复算法时，先用有界原型与行为测试验证，不能把候选实现视为既定事实。
