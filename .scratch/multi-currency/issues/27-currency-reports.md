# 27: 分类报表与热度图隔离币种

Type: task
Triage: ready-for-agent
Status: resolved

Blocked by: 18

**交付：** 按当前币种计算分类和每日热度。

**先写失败测试：** 先测试同一分类的两币种交易不相加。

**验收条件：**

- [ ] 在聚合前按币种过滤。
- [ ] 排除合计规则保留。
- [ ] 切换及异步结果不误标。
- [ ] 无独立切换。

**预计修改的生产文件：**

- `lib/core/data/database/daos/reports_dao.dart`
- `lib/features/reports/data/repositories/reports_repository.dart`
- `lib/features/reports/presentation/providers/reports_providers.dart`

**预计修改的测试文件：**

- `test/unit/features/reports/data/repositories/reports_repository_test.dart`
- `test/ui/features/reports/reports_screen_test.dart`
## 共同约束

- 先在已确认的公开测试接缝编写本票首个行为的失败测试，运行并确认失败；再以最小实现通过，逐条重复，不先批量编写所有测试。接缝为账本、账户、周期及备份 service 和真实测试数据库；界面与通知行为使用 widget 测试及现有通知平台适配边界。
- 预计文件按当前代码列出；实施前核对并优先复用现有模块。需要界面文案时同步 en、zh、zh_Hans、zh_Hant 四个 ARB 并运行生成器；Drift 和 Riverpod 生成文件由生成器更新。
- 任务 28 的自动入账保护在任务 48 验收前保持，测试可通过受控测试配置验证各阶段行为；任何阶段不得删除或重置现有数据。完成时运行适用测试及静态分析。
- 完整产品规则与范围以[多币种规格](../spec.md)为准；涉及尚未验证的期次身份、资格历史及恢复算法时，先用有界原型与行为测试验证，不能把候选实现视为既定事实。

## Answer

分类报表与热度图在聚合前按币种过滤（SQL WHERE），无独立切换入口，跟随设置币种。见 reports_dao.dart、reports_repository.dart、reports_providers.dart。
