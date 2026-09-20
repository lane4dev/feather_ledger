# 41: 恢复屏障与未物化候选

Type: task
Triage: ready-for-agent
Status: resolved

Blocked by: 30、33、39

**交付：** 恢复后任何入口不会绕过待确认屏障。

**先写失败测试：** 先构造恢复后重启及旧备份未物化候选，断言未确认无入账。

**验收条件：**

- [x] 备份后至恢复前到期含未物化期次纳入候选。
- [x] 目标设备设置生效。
- [x] 恢复事务中断重试不自动误记或部分提交。

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

## Answer

恢复屏障（US58）以数据库持久化 + 崩溃安全标记两层实现，覆盖所有自动入账入口（只有 `catchUpAutoPosted` 一个入口）。

**候选窗口**：`(backupExportedAt, createdAt]`。备份导出时刻之后的未物化期次，在物化时本来就有默认 `autoPostEligible=true`；ticket 32 的创建即过期打标只针对"创建时已到期"，不误伤"物化时仍未来、后来到期"的候选。恢复后 `catchUpAutoPosted` 加载最近一条 `status=pending` 的 `RestoreConfirmationBatches`，对窗口内的到期实例直接 `continue`（不记入、不认领），等确认后才进入普通资格路径。

**目标设备设置生效**：开关与币种资格判断在跳过屏障前仍走 `_isEligible`；恢复覆盖偏好时 `importAll` 只导入四个已知键，本机开关（`autopost_*`、`autopost_*_since`、`currency_active_since_*`）不含在备份里，因此目标设备自己的开关决定资格。

**崩溃安全**：`applyPendingRestore` 在清空 staging 前把 `manifest.exportedAt` 原子写入 `restore_barrier.json`（staging 之外，随活库并排）。下一次启动 `main.dart` 在 DB 打开后立即 `createRestoreConfirmationBatch(exportedAt)` 再 `clearRestoreBarrier`。id 由 `exportedAt` 毫秒值派生（`restore-<millis>`），insertOnConflictUpdate 幂等，重试不会产生重复批次。

**实现落点**：
- `restore_confirmation_batch.dart`（settings/domain/models）：`RestoreConfirmationBatch{id,createdAt,backupExportedAt,status}` + `contains(moment)`（`moment > backupExportedAt && moment <= createdAt`）。
- `tables.dart` 新 CRUD 豁免表 `RestoreConfirmationBatches`（`@DataClassName('RestoreConfirmationBatchRow')`，schemaVersion 11→12，`createTable` 增量迁移）。
- `recurring_dao.dart`/`recurring_repository.dart`/`watch_scheduled_transactions_query.dart`：`createRestoreConfirmationBatch` + `latestPendingRestoreConfirmationBatch`。
- `recurring_service.dart` `catchUpAutoPosted`：屏障跳过逻辑。
- `pending_restore.dart`：`restoreBarrierMarker` 常量 + `_readStagedExportedAt`/`_writeRestoreBarrier`/`readRestoreBarrier`/`clearRestoreBarrier`。
- `main.dart`：DB 打开后记录批次并清标记。

**测试**：`restore_confirmation_test.dart`（屏障阻止自动入账，seed 类别事件计入 `eventsBefore` 基线）；`pending_restore_test.dart` 新增 3 条（manifest 写标记可读可清、无 exportedAt 不写、坏 manifest 不写且恢复仍完成）。
