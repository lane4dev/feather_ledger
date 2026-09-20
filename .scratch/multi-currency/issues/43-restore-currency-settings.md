# 43: 恢复确认切币和开关例外

Type: task
Triage: ready-for-agent
Status: resolved

Blocked by: 31、42

**交付：** 延期批次在切币和开关状态变化后按规则处理。

**先写失败测试：** 先测试恢复时已关闭与恢复后主动关闭的不同结果。

**验收条件：**

- [ ] 切离保留，切回且开启立即重询。
- [ ] 恢复时已关闭开关保留既有待确认批次、其他逾期转手动。
- [ ] 恢复后主动关闭使待确认逾期转手动。

**预计修改的生产文件：**

- `lib/features/settings/domain/services/backup_service.dart`
- `lib/core/presentation/providers/currency_provider.dart`
- `lib/features/ledger/domain/services/recurring_service.dart`

**预计修改的测试文件：**

- `test/unit/features/settings/data/backup_service_test.dart`
- `test/ui/features/settings/backup_screen_test.dart`
## 共同约束

- 先在已确认的公开测试接缝编写本票首个行为的失败测试，运行并确认失败；再以最小实现通过，逐条重复，不先批量编写所有测试。接缝为账本、账户、周期及备份 service 和真实测试数据库；界面与通知行为使用 widget 测试及现有通知平台适配边界。
- 预计文件按当前代码列出；实施前核对并优先复用现有模块。需要界面文案时同步 en、zh、zh_Hans、zh_Hant 四个 ARB 并运行生成器；Drift 和 Riverpod 生成文件由生成器更新。
- 任务 28 的自动入账保护在任务 48 验收前保持，测试可通过受控测试配置验证各阶段行为；任何阶段不得删除或重置现有数据。完成时运行适用测试及静态分析。
- 完整产品规则与范围以[多币种规格](../spec.md)为准；涉及尚未验证的期次身份、资格历史及恢复算法时，先用有界原型与行为测试验证，不能把候选实现视为既定事实。

## Answer

切离与开关关闭两条路径都已覆盖，改动集中在 `RecurringService` 与设置页开关：

- **恢复时开关已关闭**：`catchUpAutoPosted` 现在先按 `_isEligible` 判定资格，再决定是否让账单停在恢复屏障后面——只有「窗口内且仍合格」的账单才继续等待确认；开关关闭或币种切离的窗口内账单落回 `_settleMember` 被转为手动（`markAutoPostIneligible`），不再被屏障保留。
- **恢复后主动关闭开关**：新增 `RecurringService.latchRestoreCandidatesForMode(mode)`，遍历所有待确认批次，把该模式仍合格的候选逐一转为手动；批次本身保持 `pending`，等待用户显式确认/拒绝。设置页的 `AutoPostSwitches.setMode` 在关闭时调用它（开启时仍只锚定 `enabledSince`）。
- **切离保留 + 切回立即重询**：`restoreConfirmationCandidates` 不检查 `currencyActiveSince`，切离币种不丢失待确认资格；设置页的 `pendingRestoreConfirmationSummariesProvider` 重新 `watch` 币种 provider，切回即重新查询展示。

测试（`restore_confirmation_test.dart`，共 5 个）新增两条：`a switch already off at restore latches its window candidates manual` 与 `turning a switch off after restore latches its pending candidates manual`。设置页 widget 测试改为纯 UI（canned summary provider + fake service），因为真实 Drift 流在 fake-async 测试时钟下不解析；真实 confirm/reject/latch 行为由 `restore_confirmation_test.dart` 覆盖。
