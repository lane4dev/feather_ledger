# Quickstart：事件化账务迁移（003-event-sourced-ledger）

> 本文件是本 feature 的可执行开发者步骤（T003）。实施依据为已确认规格 [spec.md](spec.md) 与 [tasks.md](tasks.md)；`plan.md`、`data-model.md`、`contracts/` 是迁移前文档，已标记过期，不得据此实现。

## 1. 环境准备

```bash
flutter pub get
```

要求：Flutter stable（Dart 3.x）。依赖 Drift/SQLite、Riverpod（codegen）、`rrule`、`uuid`、`clock`。

## 2. 代码生成

改完下列任一内容后，必须重新生成再分析/测试：

| 变更内容 | 位置 | 生成物 |
|---|---|---|
| Drift 表（`Table` 子类）、`@DriftDatabase` 表/DAO 列表、schema 版本 | `lib/core/data/database/tables.dart`、`app_database.dart` | `app_database.g.dart`、各 `*.g.dart` |
| Riverpod provider（`@riverpod` / `@Riverpod` 注解函数） | 各 command/query/service/repository 文件 | 同文件 `*.g.dart` |
| 事件 payload JSON 类（`@JsonSerializable`） | `lib/core/domain/events/`、`lib/features/ledger/domain/events/` | 同文件 `*.g.dart` |

```bash
dart run build_runner build -d
```

- `-d`（delete-conflicting-outputs）：生成物冲突时直接覆盖，本地开发用。
- CI / 提交前校验用：`dart run build_runner build`（不带 `-d`，冲突即失败）。
- 只改了 `.dart` 逻辑没动注解时不需要重跑。

## 3. 静态检查（Constitution V 门禁）

```bash
flutter analyze
```

零告警是硬性要求（`.specify/memory/constitution.md` 原则 V）；每次代码调整后执行并修复全部 issue。

## 4. 测试

```bash
# 全量测试
flutter test

# 单个文件（示例：迁移共享装配冒烟测试）
flutter test test/support/event_sourcing/ledger_service_harness_test.dart

# 事件化逻辑测试（经 LedgerService/AccountService + 内存 Drift）
flutter test test/unit/features/ledger/domain/
```

测试布局与策略（见 tasks.md「测试策略」）：

- 逻辑测试一律经领域服务驱动，断言**事件流**（`db.eventsDao`）、**投影表**、（Phase 7 起）**月度快照**三类外部可观察输出；不为命令、投影器或 Event Store 建 mock 接缝。
- 共享装配：`test/support/event_sourcing/ledger_service_harness.dart`（T002）——内存 Drift + 全套命令/查询/服务接线 + 事件工厂注册。
- 事件 JSON 工厂目前仅在测试（harness）中注册，生产 bootstrap 注册在 US2（T021）落地。
- Widget 测试只测投影驱动的 UI 行为（`test/ui/`）。

## 5. 审计 / 调试

查看原始事件流（Android Studio App Inspector 或 sqlite3 CLI）：

```sql
SELECT * FROM ledger_events ORDER BY id DESC;
```

- `id` 即全局序列号（GSN）；当前信封为迁移前结构（无 streamId/streamVersion/commandId），US2（T018–T022）重建表后生效最终信封。
- 投影重建（rebuild）入口：迁移前的 `rebuildProjections()` 示例已删除（该方法从未实现）；正式实现位于 US8（T057 `ledger_rebuild_service.dart`），设置页开发者入口见 T059。

## 6. 迁移期开发循环

每个切片（US）完成时：

1. `dart run build_runner build -d`（若改了表/注解）。
2. `flutter analyze` 零告警。
3. `flutter test` 全绿。
4. 在 `tasks.md` 勾选完成任务，并按「迁移核销基线（T004）」核销对应旧路径——**删除所替代的旧代码，禁止双轨写入**。

## 6. Phase 12 终验记录（T076，2026-09-07）

- 代码生成：`dart run build_runner build -d`（schema v7：定期两表金额列更名 `amountMinor`）✅
- `flutter analyze`：No issues found ✅
- `flutter test`：**180 个测试全部通过**（含 golden 等价、账务不变量、快照、冲正/修改、转账、转换与报表 widget 测试）✅
- 12 项财务风险回归矩阵：`checklists/financial-risk-regression.md`（T075）✅
- 治理文档：constitution 原则 VII（事件溯源纪律）、AGENTS.md 最终架构（T074）✅

迁移完成：Event Store 是唯一事实来源，所有读模型可从事件重放恢复，无双轨账务系统。
