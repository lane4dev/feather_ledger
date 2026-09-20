# 42: 恢复批次分别确认及延期

Type: task
Triage: ready-for-agent
Status: resolved

Blocked by: 40、41

**交付：** 恢复候选按批次展示并允许同意、拒绝或延期。

**先写失败测试：** 先测试两个批次一个延期、一个同意时只记入后者。

**验收条件：**

- [ ] 展示币种、数量、日期范围和不同步风险。
- [ ] 新旧批次分别确认不互相阻塞。
- [ ] 拒绝转手动，同意后失败可重试，延期不入账。

**预计修改的生产文件：**

- `lib/features/settings/domain/services/backup_service.dart`
- `lib/features/settings/presentation/screens/settings_screen.dart`
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

实现：候选 = 仍为 scheduled 且 `autoPostEligible` 且在批次窗口 `(backupExportedAt, createdAt]` 内的期次。`RecurringService` 新增三个公开方法：

- `restoreConfirmationEligible(batchId)` —— 候选再经 `_isEligible`（开关 + 币种 + 资格）过滤，供 UI 与确认复用同一计算。
- `confirmRestoreBatch(batchId)` —— 对每个符合资格的候选调用 `_postInstance`（确定性 commandId `restore-confirm-<id>`），失败留作 scheduled 可重试；随后把批次标记 `confirmed`。
- `rejectRestoreBatch(batchId)` —— 对每个窗口候选 `markAutoPostIneligible`（转手动）后把批次标记 `rejected`。

延期 = 不动作（批次保持 `pending`）。新旧批次分别确认：每个批次有独立窗口（`createdAt` 可显式传入），互不阻塞。

UI：`pendingRestoreConfirmationSummariesProvider` 从仓储读取 pending 批次、逐个计算 eligible 候选，`SettingsScreen` 在备份与开发者分组之间渲染「恢复确认」`AppCard.group`，每批一行（币种 · 数量 · 日期范围 · 不同步风险），点开 SimpleDialog 提供「记入 / 转为手动 / 稍后」三选项。

测试：`restore_confirmation_test.dart` 7 条（屏障、分别确认、拒绝转手动、开关关闭时转手动、改期保留资格、改金额加锁）；`restore_confirmation_screen_test.dart` 3 条纯 UI（渲染、拒绝、延期）。全部通过。
