# Tasks: P0 基础财务能力闭环

**Input**: 已确认规格 [spec.md](spec.md) 与 [plan.md](plan.md)，[`.specify/memory/constitution.md`](../../.specify/memory/constitution.md)，以及产品审计 [`docs/reports/2026-09-21-product-feature-audit.md`](../../docs/reports/2026-09-21-product-feature-audit.md)。

**测试策略**: 每个逻辑测试只经 `LedgerService` / `AccountService` / `RecurringService` 和内存 Drift 数据库驱动，断言事件流、投影表与月度快照；不为命令、投影器或 Event Store 建 mock/私有实现测试接缝。纯函数（CSV、状态编解码、`pending_restore` 的文件舞蹈、`TransactionFilter` 的相等性）用纯单测。每次代码调整后执行 `flutter analyze`。

**组织方式**: 五个 Phase 对应四个用户故事 + 收尾。**执行顺序为 US1 → US4 → US2 → US3**，与优先级排序不同：US1 自成一体且迫使本地化缺口先被修；US4 与一切正交、是审计里唯一的 High，趁树还小时落地它比任务顺序的美观更值钱；US2 占 `main.dart` 的启动补课，等 US4 对 `main.dart` 的改动定下来再做；US3 最大且是唯一既加依赖又加一屏筛选状态的，放最后。

**串行化交点**（任一时刻只能有一个故事在动）: `lib/main.dart`（US2、US4）、`lib/app/router/app_router.dart`（US1、US2、US3）、四个 ARB（全部）、`pubspec.yaml`（US3、US4）、`lib/features/ledger/presentation/view_model/ledger_view_model.dart` + `screens/ledger_screen.dart`（US1、US2、US3）。

---

## Phase 1: Setup（收口在途工作，建立干净基线）

**Purpose**: 本 spec 的五个串行化交点中，四个 ARB 文件已被在途的 T077 修改。不先收口，本 spec 每一次 ARB 编辑都是冲突，且 `flutter analyze` 的失败归因会变得含糊。

- [ ] T001 收口 `specs/003-event-sourced-ledger/tasks.md` 的 T077：将 ledger、reports 与 settings presentation 组件改为 ThemeExtension token 与统一 DS wrappers，移除直接 palette/typography/spacing/radius 原语，以满足 Constitution III，路径为 `lib/features/ledger/presentation/`、`lib/features/reports/presentation/`、`lib/features/settings/presentation/`、`lib/app/design_system/`
- [ ] T002 收口 `specs/003-event-sourced-ledger/tasks.md` 的 T080：将 Event Store 的行为验收迁移为 `LedgerService`/`AccountService` 加内存 Drift harness 的外部可观察测试，并将直接 EventStore 测试限缩为结构性适配器测试，以满足 Spec Testing Strategy，路径为 `test/unit/features/ledger/domain/services/event_store_contract_test.dart`、`test/support/event_sourcing/ledger_service_harness.dart`
- [X] T003 提交工作区并确认基线：`flutter analyze` 零问题、`flutter test` 全绿（记录实际项数作为本 spec 的增量基线），路径为仓库根

  > **执行记录（2026-09-21）**：T077 实际剩余量远大于 plan 的估计——18 个文件、52 处 palette/typography/spacing/radius 原语仍待迁移。经确认改为**把在途工作原样提交为 WIP 快照**（提交 `d9f9115`），T077/T080 在 `specs/003-event-sourced-ledger/tasks.md` 中**保持未勾选**。这样做的理由：plan 要求「先提交」的真实动机是让四个 ARB 文件有稳定基线以免 P0 的 ARB 编辑冲突，而提交 WIP 已经满足该动机，不必先完成一个与 P0 无关的大迁移。
  > 基线：**`flutter test` 196 项通过，`flutter analyze` 零问题。** 分支 `004-p0-core-finance-loop`。
  > T001/T002 因此**未完成**，保持未勾选。

- [X] T004 建立本 feature 的规格目录并将 `.specify/feature.json` 指向它，路径为 `specs/004-p0-core-finance-loop/`、`.specify/feature.json`

  > 注：`.specify/feature.json` 被 `.specify/.gitignore` 忽略，该改动只存在于本地工作副本。

**Checkpoint**: 工作区干净、基线数字已知，可以开始改动。✅ 196 项基线。

---

## Phase 2: Foundational（封闭集合与编解码的单一来源）

**Purpose**: 两个横切缺口在多个故事里被暴露，先修以免每个故事各修一遍。

**⚠️ CRITICAL**: `LedgerErrorCode` 是封闭集合，新增成员意味着四份 ARB 都要补条目（FR-028）。状态编解码必须一处定义、两个方向，只修解码会重新制造它消除的那个错配。

- [X] T005 [P] 新增 `LedgerErrorCode.scheduledAlreadyPosted`，并在 `ledger_error_localizer.dart` 补 `currencyMismatch`、`sameAccountTransfer`、`scheduledAlreadyPosted` 三个 case，路径为 `lib/core/domain/result/result.dart`、`lib/shared/presentation/ledger_error_localizer.dart`
- [X] T006 [P] 为上述三个错误码补齐四份 ARB 文案并重新生成，路径为 `lib/app/l10n/app_en.arb`、`app_zh.arb`、`app_zh_Hans.arb`、`app_zh_Hant.arb`
- [X] T007 [P] 编写封闭集合守护单测：遍历**全部** `LedgerErrorCode` 成员，断言每一个都映射到不等于 `errorPrefix(code.name)` 的文案——这正是让 `currencyMismatch`/`sameAccountTransfer` 漏网的回归，路径为 `test/unit/shared/presentation/ledger_error_localizer_test.dart`
- [X] T008 [P] 在 `ScheduledTransactionStatus` 旁定义 `toStorage()` 与 `decodeScheduledStatus(raw)`（含 `orElse: () => scheduled`），并替换全部 5 处（3 处解码 + 2 处写入），以满足 FR-013，路径为 `lib/features/ledger/domain/entities/ledger_entities.dart`、`lib/features/ledger/data/repositories/recurring_repository.dart`、`lib/features/ledger/data/repositories/ledger_repository.dart`
- [X] T009 [P] 编写状态编解码单测：四个值往返；未知字符串降级为 `scheduled` 且不抛，路径为 `test/unit/features/ledger/domain/entities/scheduled_status_test.dart`

**Checkpoint**: 错误码集合完备且被测试守护；周期状态只有一个真相来源。✅

> **执行记录（2026-09-21，201 项测试通过，analyze 零问题）**：
> - **T007 的守护单测当场抓到一个 plan 没发现的既有缺陷**：`unknownEvent` 同样回落到 `errorPrefix`。而 `guard()` 把**每一个**未预期异常都归到 `unknownEvent`，也就是说任何意外错误都会把字面量 `Error: unknownEvent` 显示给用户。已一并补上 `errorUnknownEvent`（四份 ARB + localizer + fake）。实际修复的是**四个**码，不是三个。
> - 补完之后 switch 变为穷尽，`_ =>` 分支不再可达（`unreachable_switch_case`）。**已删除该分支**：此后新增 `LedgerErrorCode` 成员而未加文案是**编译错误**，比运行时测试更强。T007 的测试保留，用于守住「不得重新引入回落分支」与「文案非空」。
> - **T008 的实际改动点是 7 处，不是 5 处**：4 处解码（`ledger_repository.dart:132`/`:171`、`recurring_repository.dart`、`get_scheduled_transaction_query.dart`）+ 3 处写入（`ledger_repository.dart`、`project_recurring_events_command.dart`、`convert_scheduled_to_posted_command.dart` 的 `const Value('posted')` 字面量）。其中 `recurring_repository.dart` 与 `get_scheduled_transaction_query.dart` 两处原本**没有 `orElse`**，遇到未知 status 会直接抛。

---

## Phase 3: User Story 1 - 转账产品闭环（P1） 🎯 MVP

**Goal**: 转账可创建、查看、编辑、删除；编辑走「冲销 + 重记」成对事件；更正的合法路径由**原交易的 kind** 决定。

**Independent Test**: 新建转账 → 列表出现中性色、无符号的行 → 两个账户余额一增一减 → 编辑金额与账户 → 余额等于「一开始就按新值记」→ 删除可用。

### Implementation

- [X] T010 [US1] 抽取 `_loadCorrectable` 与 `_appendCorrection`，把 `execute` 的 `type == transfer` 死守卫替换为**按原交易 kind** 判定，并新增 `executeTransfer`（约 28 行，append 逻辑零重复），以满足 FR-003/FR-004，路径为 `lib/features/ledger/domain/commands/correct_transaction_command.dart`
- [X] T011 [US1] 编写转账更正测试（经 `LedgerServiceHarness`）：原行 `isReversed`、新 `TransactionRecorded` 带两条 posting、`accounts_view` 余额与「直接新记一笔」完全相等（SC-002 的重复计数守卫）、两事件共用同一 `commandId`、transfer 原交易按 income 更正被拒、income 原交易按 transfer 更正被拒，路径为 `test/unit/features/ledger/domain/services/transfer_correction_test.dart`
- [X] T012 [US1] 新增 `LedgerService.updateTransfer`（`guard` 包 `executeTransfer`），`addTransfer` 原样复用，路径为 `lib/features/ledger/domain/services/ledger_service.dart`
- [X] T013 [US1] 在 `LedgerViewModel` 新增 `addTransfer`/`updateTransfer`（各自铸 `Uuid().v4()`），并补视图模型单测，路径为 `lib/features/ledger/presentation/view_model/ledger_view_model.dart`、`test/unit/features/ledger/presentation/ledger_view_model_transfer_test.dart`
- [X] T014 [US1] 新建 `TransferFormScreen`：金额、日期时间、从账户、到账户、备注；复用 `LedgerAmountInput`/`LedgerSelectionSheet`/`AppButton`；文件内私有 `_AccountRow` 用两次；「到」的候选按「从」账户币种与未归档过滤，使跨币种与同账户组合不可达（FR-001/FR-002），路径为 `lib/features/ledger/presentation/screens/transfer_form_screen.dart`
- [X] T015 [US1] 新增 `/ledger/transfer` 路由，让 `/ledger/edit` 的 builder 按 `extra.type` 分流到转账或收支表单，并在账本页 `SliverAppBar` 加搜索与转账两个 action（FAB 保持直达 `/ledger/add`），路径为 `lib/app/router/app_router.dart`、`lib/features/ledger/presentation/screens/ledger_screen.dart`
- [X] T016 [US1] 编写转账表单组件测试：新建/编辑两种渲染、两个选择器都排除归档账户、保存调用 `addTransfer`、`sameAccountTransfer` 失败显示本地化文案，路径为 `test/ui/features/ledger/transfer_form_screen_test.dart`
- [X] T017 [US1] 修正转账展示：`transaction_detail_sheet` 的配色扩为三路（transfer → `onSurface`）、符号改用 `displaySign`；`ledger_amount_input` 的 `typeColor` 同样扩为三路，以满足 FR-005，路径为 `lib/features/ledger/presentation/widgets/transaction_detail_sheet.dart`、`lib/features/ledger/presentation/widgets/ledger_amount_input.dart`
- [X] T018 [US1] 编写组件测试：转账行与详情页均为中性色、无 `+`/`-` 前缀，路径为 `test/ui/features/ledger/transfer_display_test.dart`
- [X] T019 [US1] 补齐四份 ARB 的转账文案并重新生成，路径为 `lib/app/l10n/app_{en,zh,zh_Hans,zh_Hant}.arb`
- [X] T020 [US1] 门禁：`dart run build_runner build -d`、`flutter gen-l10n`、`flutter analyze` 零问题、`flutter test` 不减少，路径为仓库根

**Checkpoint**: 转账在 UI 上完整可用；本地化缺口已闭合。✅

> **⚠️ 设计变更（2026-09-22，用户要求）：T014/T015 被推翻，转账并入收支表单。**
> 原实现按计划建了独立的 `transfer_form_screen.dart`；用户要求把转账迁移进 `transaction_form_screen.dart`。现已：
> - 删除 `lib/features/ledger/presentation/screens/transfer_form_screen.dart`；
> - `transaction_form_screen.dart` 承载三种 kind —— 转账渲染「从/到」两个账户行、**不渲染分类行**；收支渲染分类行与单个账户行。**不适用的字段根本不渲染**，所以「带分类的转账」不是这个表单能进入的状态（比原有的「渲染后校验拦住」更贴合 ADR-0002）。
> - `LedgerTypeSelector` 新增 `kinds` 参数（默认三种）；**周期系列表单必须传 `[expense, income]`**，因为一个系列只有一个账户，transfer 对它不可表达。
> - 路由：`/ledger/edit` **不再按 kind 分流**——kind 由 `extra` 里的交易自己决定。
>
> **后续（2026-09-22，同日）：转账快捷入口也移除了。** 用户要求移除账本页右上角的转账按钮。该按钮是 `/ledger/transfer` 的**唯一**引用，因此该路由一并删除（留着就是死路由）。现在转账只能从表单内的类型选择器进入——这是合并的自然终点：一个屏幕，一个入口。随之删除的还有 `TransactionFormScreen.initialType`：它已无生产调用方，只剩测试在用，而测试改用**点击 Transfer segment**（真实用户路径）反而更贴近实际。
> - 金额输入框的币种符号：转账用「从」账户的币种（两条腿同币种），收支仍用全局显示偏好。
> - 账户选择器改用**每个账户自己的币种符号**（原先是全局符号）：转账模式下两条腿并排出现，共用符号在账户币种不同时会标错其中一条。这是合并**必需**的改动，不是顺手改的。
> - 测试：`transfer_form_screen_test.dart` 重写为 9 项（覆盖三种 kind 的渲染切换、两条写路径的分流、编辑时从 `toAccount` 回填）。全套 312 → 316 项，`flutter analyze` 零问题，`flutter build linux --debug` 成功且启动无异常。
> - **仍未处理的 UX 取舍**：转账模式下选中账户后字段只显示账户名，方向靠上下箭头图标；详情页用的是 From/To 文字标签。合并前同样如此，非本次引入。

> **执行记录（2026-09-21，214 项测试通过，analyze 零问题，SC-010 已复核）**：
> - T011 的余额等价性测试做了**变异验证**：临时删掉 `_appendCorrection` 里的冲销信封后，该测试以 `Expected: <115000> Actual: <105000>` 失败（正是未抵消的原交易被重复计入），确认这条守卫真的有效，而非恰好通过。之后已还原。
> - T016 的组件测试**没有**用真实 DI 图。首版用 `appDatabaseProvider` 覆盖 + `GoRouter` + `LedgerViewModel`，结果卡在 `pumpAndSettle` 永不收敛（金额输入框 autofocus 的光标闪烁）并在拆卸时留下 pending timer，整个 suite 挂死 10 分钟。改为：组件测试只覆盖账户列表与视图模型两个 provider，断言「表单调用了哪个方法、传了什么参数」；真正的写入路径（事件对、余额、拒绝）由 T011 走真实 service 断言。这正是宪法 VI 描述的接缝分工。
> - T016 还暴露了测试自身的一个陷阱：选中「从」账户后，选择器字段本身会渲染该账户名，未加限定的 `find.text('Cash')` 会命中字段而非弹窗选项。断言已限定在 `LedgerSelectionSheet` 内。
> - T016 覆盖的是「表单装配」和「选择器过滤」，不含真实数据库；T018 覆盖转账的中性配色与无符号前缀（并保留一条「支出仍然是红色带减号」的对照，避免把三路分支写成「非收入即中性」）。
> - **两处与任务描述有出入，记录在此**：(1) T013 原本还写了「补视图模型单测 `ledger_view_model_transfer_test.dart`」，实际未单独建该文件——`addTransfer`/`updateTransfer` 只是铸造 `commandId` 后转发给 service（三个同形方法里的第 4、5 个），单测只会重复断言 mock 调用，其装配已由 T016 的组件测试以真实参数断言覆盖。(2) T015 原本写了「加搜索与转账两个 action」，实际**只加了转账**：搜索路由属于 US3，先加会挂一个死路由。搜索 action 留到 T053 与 `/ledger/search` 一起加。

---

## Phase 4: User Story 4 - 可靠本地备份与恢复（P2）

**Goal**: 账本可一键备份为单个可分享文件，可从中恢复；恢复是替换语义，校验失败不留痕，替换失败可回滚。

**Independent Test**: 备份 → 解开归档确认三个条目 → 改动数据 → 恢复 → 确认框显示事件条数对比 → 暂存后重启 → 数据回到备份时刻。

**为什么排在 US2/US3 之前**: 与其它三个故事完全正交，且是审计里唯一的 High。趁代码树还小时落地安全网，比维持任务顺序的美观更值钱。

### Implementation

- [X] T021 [US4] 新增依赖 `share_plus`、`cross_file`、`archive`、`file_selector`（`cross_file` 需显式声明，因为要直接 import 其 `XFile`），路径为 `pubspec.yaml`
- [X] T022 [P] [US4] 为 `PreferencesRepository` 增加 `exportAll()`/`importAll(Map)`，**只针对已知的四个 key**（不用 `getKeys()`），并补单测，路径为 `lib/core/domain/repositories/preferences_repository.dart`、`lib/core/data/repositories/preferences_repository.dart`、`test/unit/core/data/repositories/preferences_repository_backup_test.dart`
- [X] T023 [P] [US4] 新建 `BackupManifest`（`@JsonSerializable`），`fromJson` 拒绝错误 `format` 与未知 `formatVersion`，并补单测（往返、两类拒绝、缺键拒绝），路径为 `lib/features/settings/domain/models/backup_manifest.dart`、`test/unit/features/settings/domain/backup_manifest_test.dart`
- [X] T024 [US4] 实现 `BackupService.createBackup`：`VACUUM INTO`（不在事务内、目标不存在、路径在 UI isolate 算好传入）产出干净快照，连同 `preferences.json` 与 manifest 打成一个 zip 后分享，以满足 FR-021/FR-022，路径为 `lib/features/settings/domain/services/backup_service.dart`
- [X] T025 [P] [US4] 新建 `applyPendingRestore(Directory supportDir)`（纯 `dart:io`）：无 PENDING 则空操作；改名旧库 → **删除陈旧的 `-wal`/`-shm`/`-journal`** → 改名新库 → 删 `restore/`；任一步失败回滚并保持原账本完好，以满足 FR-025/FR-026，路径为 `lib/app/bootstrap/pending_restore.dart`
- [X] T026 [US4] 编写 `applyPendingRestore` 单测（临时目录）：无 PENDING 无操作；顺路径后 `db.sqlite` 被替换且三个副档消失、PENDING 已清；改名失败时原库完好，路径为 `test/unit/app/bootstrap/pending_restore_test.dart`
- [X] T027 [US4] 实现 `BackupService.stageRestore`：解压 → 校验 manifest → 用一次性 `NativeDatabase` 打开暂存库跑 `PRAGMA integrity_check` 并读 `schemaVersion` → 异版本或损坏则拒绝且**不写** PENDING，以满足 FR-023，路径为 `lib/features/settings/domain/services/backup_service.dart`
- [X] T028 [US4] 编写 `createBackup`/`stageRestore` 单测：归档恰好 3 个条目、manifest 计数与库一致、解出的库通过 `integrity_check`；异版本/损坏 zip 与截断库均失败且不写 PENDING，路径为 `test/unit/features/settings/data/backup_service_test.dart`
- [X] T029 [US4] 在 `main.dart` 接线：`applyPendingRestore` **必须早于**任何 `appDatabaseProvider` 读取；容器与 seed 完成后再应用恢复出的偏好（两处都留醒目注释说明顺序的承重性），以满足 FR-025，路径为 `lib/main.dart`
- [X] T030 [US4] 在设置页新增「数据」区两个入口（立即备份 / 从备份恢复），含恢复确认框（**必须明示将丢弃的事件条数**）与暂存后的「关闭并重开」提示；补齐四份 ARB，以满足 FR-024/FR-028，路径为 `lib/features/settings/presentation/screens/settings_screen.dart`、`lib/app/l10n/app_{en,zh,zh_Hans,zh_Hant}.arb`
- [X] T031 [US4] 编写设置页组件测试：两个入口存在、恢复确认框出现、暂存后「关闭并重开」对话框出现，路径为 `test/ui/features/settings/backup_screen_test.dart`
- [X] T032 [US4] 门禁：`dart run build_runner build -d`、`flutter gen-l10n`、`flutter analyze` 零问题、`flutter test` 不减少，路径为仓库根

**Checkpoint**: 换设备/误删有安全网；恢复的每一步失败都不会损坏现有账本。✅

> **执行记录（2026-09-22，254 项测试通过，analyze 零问题，SC-010 已复核）**：
> - **T023 的一个坑**：`json_serializable` 会把构造器默认值表达式原样抄进 `.g.dart`，未加类名限定的 `formatName` / `currentFormatVersion` 在那里解析不到。默认值已写成 `BackupManifest.formatName` 形式。
> - **T029 增加了一处计划没写明的返回契约**：`applyPendingRestore` 原本设计为无返回值，但它在最后一步会删掉整个 `restore/` 目录——包括 `preferences.json`。而应用恢复出来的偏好必须等到容器存在之后，那时文件已经没了。改为让它**返回**恢复出的偏好吧 map（在清理暂存区之前读出）。三项新测试覆盖：正常返回、未暂存返回 null、偏好文件损坏时返回 null 且**不影响已完成的数据替换**。
> - **`db.sqlite` 这个字面量原本会出现在两处**（`app_database.dart` 与 `RestoreLayout`）。两处若漂移，恢复会静默地替换一个没人读的文件、表现为「恢复没反应」。已抽出零依赖的 `lib/core/data/database/database_file.dart` 作为唯一来源。
> - **`cross_file` 依赖已移除**：`share_plus` 与 `file_selector` 都重新导出了同一个 `XFile`，没有任何地方需要直接 import 它，声明了反而触发 `unnecessary_import`。实际新增依赖是三个而非四个。
> - **T031 的组件测试改为 stub `BackupService`**。原因是硬的：`testWidgets` 跑在 fake-async zone 里，真实文件 I/O 永不完成——用真实 service 会在 tap 里挂死（实测卡满 5 分钟并带垮整个 suite），而不是给出可读的失败。服务本身的行为已由 `backup_service_test.dart`（真实文件、真实 zip、10 项）与 `pending_restore_test.dart`（11 项）覆盖；组件测试只负责「屏幕按正确顺序问了正确的问题」。`_FakeBackupService` 仍 `extends BackupService`，所以签名变化在这里也会断。
> - **`openFile` 已提取为 `backupFilePickerProvider`**，否则恢复流程无法在无平台通道的情况下被驱动。
> - **未覆盖项**：`main.dart` 中 `applyPendingRestore` 必须早于任何数据库读取这一**顺序**仍无自动化守卫（T029 的 plan 已声明这是全 spec 唯一无测试的接线点），只由 `main.dart` 里的醒目注释与 `pending_restore_test.dart` 的文件级测试共同守着。

---

## Phase 5: User Story 2 - 周期账单闭环（P2）

**Goal**: 周期系列可创建、可停用；到期实例以待办呈现，由用户显式「记入」或「跳过」；启动时幂等补课。

**Independent Test**: 新建「每月 1 号房租」→ 立即出现在系列列表且待办区出现到期实例 → 「记入」→ 账本出现该笔且状态转 posted → 再建一个 → 「跳过」→ 状态 skipped、账本无变化 → 停用 → 不再新增，既有实例仍在。

### Implementation

- [X] T033 [US2] 新增 `RecurringDao.watchAllSeries()`，并在 `RecurringRepository` 接口与实现上补 `saveSeries`/`watchAllSeries`（`saveSeries` 已存在、零调用方，就此转正），以满足 FR-012，路径为 `lib/core/data/database/daos/recurring_dao.dart`、`lib/features/ledger/domain/repositories/recurring_repository.dart`、`lib/features/ledger/data/repositories/recurring_repository.dart`
- [X] T034 [US2] 新增三个命令：`CreateRecurringSeriesCommand`（收具名参数而非 Drift companion，复用 `PostingContextResolver` 跑账户/分类红线，走到 CRUD-exempt 表）、`DeactivateRecurringSeriesCommand`（设 `endDate`、保留既有实例）、`SkipScheduledTransactionCommand`（置 `'skipped'`，不写事件故无 `commandId`），以满足 FR-006/FR-007/FR-012，路径为 `lib/features/ledger/domain/commands/`
- [X] T035 [US2] 新增 `RecurringService` 门面（`createSeries` → `materialize()`、`deactivateSeries`、`postInstance`、`skipInstance`、`materialize`、`watchSeries`、`watchScheduled`），把 `convertScheduledToPosted` 与 `watchScheduledTransactions` 从 `LedgerService` 迁入，并把它加进测试 harness，路径为 `lib/features/ledger/domain/services/recurring_service.dart`、`lib/features/ledger/domain/services/ledger_service.dart`、`test/support/event_sourcing/ledger_service_harness.dart`
- [X] T036 [US2] 编写周期服务测试（经 harness）：创建后列值正确**且**实例已物化；停用后 `endDate` 已设、既有实例保留、不再新增；跳过置 `'skipped'`；跳过已 posted 得 `scheduledAlreadyPosted`；`postInstance` 产生一条事件且状态在同一次 append 内翻为 `'posted'`；**连续两次 `materialize()` 结果集完全相同**（SC-004），路径为 `test/unit/features/ledger/domain/services/recurring_series_test.dart`
- [X] T037 [US2] 在 `main.dart` 重建门禁之后加入启动补课：`try { await recurringService.materialize(); } catch (e) { debugPrint(...); }`，以满足 FR-008/FR-009，路径为 `lib/main.dart`
- [X] T038 [US2] 新增 `RecurringViewModel`（形态照 `LedgerViewModel`：两条订阅进 `AsyncValue`、`onDispose` 退订、`onError` 收进 `AsyncError`），并补待办筛选单测（含逾期 `scheduled`，排除 `posted`/`skipped`/未来），路径为 `lib/features/ledger/presentation/view_model/recurring_view_model.dart`、`test/unit/features/ledger/presentation/recurring_view_model_test.dart`
- [X] T039 [US2] 新建周期列表屏（上半「待办」含记入/跳过与确认框，下半「系列」含停用）与系列创建表单 sheet，形状照 `account_management_screen.dart` 与 `account_form_sheet.dart`；不做 `countLimit`，路径为 `lib/features/ledger/presentation/screens/recurring_list_screen.dart`、`lib/features/ledger/presentation/widgets/recurring_series_form_sheet.dart`
- [X] T040 [US2] 注册周期路由（照 `accounts`/`categories` 的双注册方式）并在 more 页加入口；**删除** `LedgerViewState.scheduledTransactions` 与 `LedgerViewModel._subscribeScheduledTransactions`（零读者且异常无人观察）以及 `LedgerService` 上迁移后的转发，路径为 `lib/app/router/app_router.dart`、`lib/features/settings/presentation/screens/more_screen.dart`、`lib/features/ledger/presentation/view_model/ledger_view_model.dart`、`lib/features/ledger/presentation/view_model/ledger_view_state.dart`
- [X] T041 [US2] 补齐四份 ARB 的周期文案并重新生成，路径为 `lib/app/l10n/app_{en,zh,zh_Hans,zh_Hant}.arb`
- [X] T042 [US2] 编写周期屏组件测试：空态、创建、停用确认、记入确认、跳过，路径为 `test/ui/features/ledger/recurring_list_screen_test.dart`
- [X] T043 [US2] 门禁：`dart run build_runner build -d`、`flutter gen-l10n`、`flutter analyze` 零问题、`flutter test` 不减少，路径为仓库根

**Checkpoint**: 租房/订阅/工资这类固定账单不再需要手记，且余额只在用户确认时变动。✅

> **执行记录（2026-09-22，281 项测试通过，analyze 零问题，SC-010 已复核）**：
> - **发现并修复了一个既有的性能缺陷，它是 T037 的前提**：`ProjectRecurringEventsCommand` 对 `rrule` 的 `getInstances()` 返回的惰性生成器用了 `.where(d.isBefore(limit))` 过滤。该生成器只在 `before` / `until` / `count` / **年份 9999** 处停止，所以一个今年开始的月度系列要跑 **~95,600 步**才能产出视野内的 ~20 个实例——实测**每个系列 ~37 秒**。修法是把 `before: limit` 直接传给生成器（语义完全等价，因为 `.where` 做的正是同一件事），并加 `startUtc.isBefore(limitUtc)` 短路，因为生成器**断言 `before >= start`**（起始日晚于视野的系列会撞断言——这条由 T036 的一个测试抓到）。单文件测试耗时 **87 秒 → 2.2 秒**。
>   这个缺陷此前不可见：命令**没有任何调用方**。本 spec 让它跑在每一次应用启动和每一次创建系列之后，所以不修就是「应用打不开」。已加一条 10 秒上限的定时守卫（修复后 <1 秒，余量 10 倍，不会因机器慢而抖动）。
> - **T035 顺带收掉了两个入口**：`convertScheduledToPosted` 与 `watchScheduledTransactions` 从 `LedgerService` 迁入 `RecurringService`，`LedgerService` 保留一行转发（`lib/` 内唯一调用方是 `LedgerViewModel` 的死订阅，已在 T040 删除，但 `convert_scheduled_to_posted_test.dart` 仍用显式 commandId 走它）。`postInstance` 因此接受可选 `commandId`——默认自己铸，调用方自带则用它。
> - **T036 抓到第二个缺陷**：`ConvertScheduledToPostedCommand` 的「已 posted」守卫仍在比字符串字面量 `'posted'` 并复用 `transactionAlreadyReversed`。Phase 2 的 T008 只替换了**写入**侧的编码（`const Value('posted')`），没动这个**比较**侧——两处是不同的代码路径。已一并改为 `decodeScheduledStatus` + `scheduledAlreadyPosted`。既有的 `convert_scheduled_to_posted_test.dart` 断言旧码，已同步更新。
> - **T038 的待办筛选单测抓到实现缺陷**：`dueScheduledInstances` 把「今天」截到零点，却拿实例的**完整时间戳**去比——实例保留系列的时刻，所以今天上午到期的账单会被判成「未到期」。改为两侧都按天比较。
> - **T042 的 `_FakeRecurringViewModel` 首版 `build()` 返回 `AsyncLoading`**，导致系列区永远转圈、`pumpAndSettle` 不收敛；改为 `AsyncData`（读取测试在 pump 前设好的字段）。另有两处断言未限定作用域：列表行的「记入」按钮与确认框里的同名按钮、系列行的「停用」与确认框里的同名——都已限定在 `AlertDialog` / `ScaffoldMessenger` 内。
> - T039 **未做** `countLimit`（列保持可空），与 spec 的「v1 只让用户面对一条结束规则」一致。
> - 入口按计划放在「更多」页，与账户/分类管理同级（`/more/recurring` + 顶层 `/recurring_management` 双注册）。

> **设计反转（2026-09-22，后续一轮，330 项测试通过，analyze 零问题）**：上面的独立周期页与表单 sheet
> **已删除**。用户的要求是「把新增周期账单迁移进交易表单，并在账本主列表里把周期性账单区分展示」——
> 同一件事散在两个页面上（在表单里记房租、再另开一页说「这笔每月都有」）是主要摩擦点。改为：
> - **T038/T039/T040/T042 作废**：删掉 `recurring_list_screen.dart`、`recurring_series_form_sheet.dart`、
>   `recurring_view_state.dart` 及其两个测试文件，以及 `/more/recurring`、`/recurring_management`
>   路由与「更多」页入口。`RecurringViewModel` 收缩为**只有三个写动作**（`createSeries` /
>   `postInstance` / `skipInstance` / `deactivateSeries`），不再持有状态——实例经
>   `ledgerMonthlyTransactionsProvider` 进列表。
> - **创建并入表单**：交易表单（非转账、仅新建）多一行「重复」（不重复 / 每天 / 每周 / 每月 / 每年，
>   `interval` 固定 1）。保存时**先记账、后建系列**，`startDate` 取所选日期的下一次发生，因此那一笔与
>   系列的首个实例不会描述同一个周期。记账成功而建系列失败**不回滚**——两个聚合，那笔账本身合法，
>   失败以 SnackBar 的 `repeatSetupFailed` 报出。
> - **待入账行进账本列表**：`TransactionTileUiModel.isPending` + 同一个 `TransactionTile`（降透明度
>   0.55、标题前置时钟图标、副标题加「待入账」标签），点开是 `PendingBillSheet`（记入需确认 / 跳过不确认 /
>   停用需确认）。**不新增第二种 UI 模型**，否则日分组、时间轴、搜索三处都要写第二遍。
> - **待入账不进余额、不进月度合计、不进搜索**：它只在展示层出现。搜索读 `transactions_view`，实例在
>   `scheduled_transactions_view`，两者结构上不相交（因此这一条**没有**写测试——构造一个必然为真的断言
>   等于不测）；它变成真实交易的唯一路径仍是 `ConvertScheduledToPostedCommand`。
> - **E3**：删掉 16 个随之失效的 ARB 键（`recurringTitle` / `dueSection` / `seriesSection` /
>   `noDueInstances` / `noRecurringSeries` / `newRecurringSeries` / `seriesDescriptionHint` /
>   `seriesFrequency` / `seriesInterval*` / `seriesStartDate` / `seriesEndDate*` / `everyFrequency` /
>   `everyNthFrequency` / `seriesEndsOn`），四份 ARB 保持 170 键对等；仍在用的
>   `frequency*` / `postInstance*` / `skipInstance` / `deactivateSeries*` 保留。

> **物化策略改为滚动窗口（同上）**：原 `execute({int months = 12})` 一次铺满未来 12 个月，换成
> **90 天窗口、夹在 [3, 12]**——填满窗口；不足 3 个继续向后取到 3 个（上限再放 3 年）；任何时候不超过
> 12 个。于是每月→3、每周→12、每年→3、每日→12，不需要按频率写规则。既有的两条约束原样保留：
> `before:` 必须传给生成器，且 `before >= start` 要短路（见上一段 T037 的记录）。
> 新增 `recurring_materialization_test.dart`（12 项）钉住四种频率的数量、远未来下限、幂等、补足、
> 跳过不复活、限时保护、停用，以及解析出的 kind/category。

> **删除取代跳过与停用（2026-09-22，再一轮，336 项测试通过，analyze 零问题）**：待入账账单的操作
> 只剩**记入 / 删除**，删除时弹三选一 —— 仅删除该项 / 删除该项和后续 / 删除所有（已入账的保留）。
> 「跳过」与「停用」被吸收：跳过的语义就是第一个作用域，停用的语义就是第二个作用域少删几行，两个入口
> 并存等于同一件事说两遍。`SkipScheduledTransactionCommand` 与 `DeactivateRecurringSeriesCommand`
> 两个文件删除，合并为 `DeleteRecurringBillCommand`（带 `RecurringDeleteScope`）。
>
> 三个作用域的**区别不在删掉哪一行，而在对系列做了什么** —— 账单是从规则推导出来的，只删行的话下次
> 物化会让它原样长回来：
> - `thisOnly` → 置 `skipped`。那个状态正是物化拒绝复活的墓碑，所以「删掉了」能保持删掉。
> - `thisAndFollowing` → 系列 `endDate` 设到该账单**前一天**（`until` 闭区间，同一天会让它当场长回来），
>   再硬删该日及以后的 `scheduled` 实例。已入账的实例不动：那笔钱真的动了。
> - `all` → 删系列本身连同它的全部实例行。已入账的**交易**不受影响 —— 它们是 `TransactionRecorded`
>   事件、自成一体的账，跟着消失的只有排期外壳。
>
> 删除**已入账**的实例会被拒（`scheduledAlreadyPosted`）：那是冲正，是另一件事、另一个入口。
>
> **删除入口与一般记账对齐**（同一轮内的调整）：删除不再是抽屉底部的整宽按钮，而是**右上角溢出菜单**
> 里的一项，与已入账交易的详情抽屉走同一个 `LedgerDeleteMenu`（同一手势、同一角落、同一错误色），
> 确认按钮也用同一个 error 色。抽成共享组件而不是各写一份，是因为「两边保持一致」正是这次的要求——
> 两份手写的菜单就是它们开始不一致的方式。抽屉底部因此只剩「记入」一个按钮。
> 组件测试的入口相应改为「先点溢出菜单、再点删除」。

> **编辑（2026-09-22，再一轮，353 项测试通过，analyze 零问题）**：待入账账单可编辑，作用域与删除共用
> 同一组（`RecurringScope` 由 `RecurringDeleteScope` 改名并移到 `ledger_entities.dart`），
> 入口是右上角的铅笔（与已入账交易详情抽屉同位置）。
>
> **第一版做成了「先问作用域、再开表单」，用户反馈不对，已改为「先编辑、保存时才问」**（见下方修订）。
> 起因是：作用域决定表单能有哪些字段，所以那一版按作用域增删字段；但用户要的是先编辑完再决定范围。
> 现在表单永远给全部字段，改过系列级字段时对话框**把「仅该项记录」置灰并说明原因**，而不是收下改动
> 再丢掉一半。不动 `tables.dart`（SC-010 冻结）这一点没变。
>
> 三个作用域的机制（细节见 `UpdateRecurringBillCommand` 的文档注释）：
> - `thisOnly`：改金额就地改；改日期在新日期建行 + **原日期留 `skipped` 墓碑**，否则物化把它放回来。
>   新日期上若这条规则本就有账单则拒绝（新错误码 `scheduledDateTaken`，四份 ARB 已补齐）。
> - `thisAndFollowing`：**拆分**成两条系列（旧的 endDate = 该账单前一天），并把旧系列已入账的日期
>   在新系列里补墓碑。
> - `all`：重写系列模板 + 删待入账行重新物化（id 编码日期，档期一平移旧 id 全过期）。
>
> 新增测试：服务层 10 项（三种作用域的行为与边界：就地改金额不动别人、改日期的墓碑与不复活、
> 撞日期被拒、拆分的边界与旧系列终止、拆分给已入账日期补墓碑、`all` 重建待入账、`all` 平移整个档期、
> `all` 不动已入账、编辑已入账被拒）＋ 组件层 8 项（三选项齐全、最窄预选、选中的作用域被原样传到表单、
> 取消不开表单；表单按作用域增删字段、保存发送正确的作用域与金额、失败按本地化文案渲染）。
>
> **修订（同日，355 项测试通过）**：编辑改为**先编辑、保存时弹范围对话框**（`RecurringScopeDialog`
> 从抽屉里移到 `widgets/recurring_scope_dialog.dart`，两个入口共用）。表单从「按作用域增删字段」改为
> **永远给全部字段**——保存前范围未定，按未定的答案藏字段没有道理。代价是会出现「改完分类才说只改这一笔」
> 这种组合：对话框此时把「仅该项记录」**置灰**并在副标题说明「分类、账户和备注属于整条规则」
> （`scopeThisOnlyUnavailable`），而不是静默丢掉用户刚做的改动。选项留在列表里而不隐藏——缺一个选项
> 像是 bug，被拒绝的选项才像规则。新增 2 项组件测试钉住这个置灰行为（改过分类 → 置灰；
> 只改金额 → 三项都可选）。
>
> **对话框标题（同日）**：编辑的范围对话框标题改为「保存周期账单」，键随之由 `scopeDialogTitle`
> 改名为 `saveRecurringTitle` —— 与删除的 `deleteRecurringTitle`（「删除周期账单」）成对，
> 两个对话框现在都是「标题带动词、选项只说范围」。
>
> **对话框文案（同日）**：三选项改为动词中性的「该项记录 / 该项记录和后续记录 / 所有记录」，
> 「已经入账的记录会保留」仍作为第三项的副标题（与最初删除那版的排版一致）。原来的中文里带着「删除」
> 字样——那是对话框还只服务删除时留下的，现在删除与编辑共用它，动词就不该在里面。
>
> **顺带发现一个与本次改动无关的既有缺陷**（见下节）。
>
> 新增测试：服务层 6 项（三种作用域的行为与边界：只删一项不复活不误伤、截断的边界日期、截断后物化
> 补不回、已入账的不受两种作用域影响、`all` 连系列一起没而账还在、截断不动规则其余字段）＋ 组件层
> 4 项（三选项齐全且最窄的预选、选中的作用域被原样传下去、取消什么都不做、失败按本地化文案渲染）。
>
> **真机端到端复核**（真库 + 真进程，同上一轮的做法）：起一条 5 个月前的月度系列 → 启动物化得 8 期 →
> 在第 3 期上做「该项及后续」→ 剩 2 期、系列 `endDate` 落在该期前一天 → **再启动两次仍是 2 期**，
> 被删的 6 期没有一期回来。这条测的正是最坏的失败模式：用户删掉一个系列，重启后它自己长回来。

---

## Phase 6: User Story 3 - 检索、基础筛选与 CSV 导出（P3）

**Goal**: 交易可按关键词 + 类型 + 账户 + 分类 + 日期范围检索，结果可导出为 CSV。

**Independent Test**: 搜索图标 → 输入关键词 → 结果按天分组 → 筛「转账 + 某账户」→ 该账户参与的两条腿的转账都出现且只出现一次 → 导出 → 文件能打开、中文不乱码、逗号被正确转义。

### Implementation

- [X] T044 [P] [US3] 新建 `TransactionFilter` 值对象（六字段、手写 `==`/`hashCode`、`static const empty`、`isEmpty`；不做 `copyWith`、不做金额区间、不做 `limit`），并补相等性单测，以满足 FR-014，路径为 `lib/features/ledger/domain/value_objects/transaction_filter.dart`、`test/unit/features/ledger/domain/value_objects/transaction_filter_test.dart`
- [X] T045 [US3] 新增 `TransactionsDao.watchTransactionsFiltered`（收基本类型不收 VO；**`isReversed` 过滤写进 SQL**；账户/分类筛 posting 表以让既有分组逻辑合并转账双腿；日期两端含端点；关键词匹配描述/分类快照/账户名并转义 `%` 与 `_`；不加索引），以满足 FR-014–FR-018/FR-020，路径为 `lib/core/data/database/daos/transaction_dao.dart`
- [X] T046 [US3] 编写 DAO 筛选单测：冲销行被排除、关键词三处命中、类型筛选、日期两端含端点、**账户筛选以一条腿取回完整转账**、分类筛选、组合条件按 AND，路径为 `test/unit/core/database/daos/transaction_dao_filter_test.dart`
- [X] T047 [US3] 在 `LedgerRepository` 接口与实现上新增 `watchTransactionsFiltered`，**复用既有的私有 `_toTransactionEntities`**（不写第二个装配器），并补单测断言被筛选的转账合并为一行且 `toAccount` 已设，以满足 FR-017，路径为 `lib/features/ledger/domain/repositories/ledger_repository.dart`、`lib/features/ledger/data/repositories/ledger_repository.dart`、`test/unit/features/ledger/data/ledger_repository_filter_test.dart`
- [X] T048 [US3] 新建 `SearchTransactionsQuery` + provider（不做 Dart 侧 `isReversed` 过滤），路径为 `lib/features/ledger/domain/queries/search_transactions_query.dart`
- [X] T049 [P] [US3] 新建 `transactionsToCsv` 纯函数（`formatMinor` 直接复用；ISO 日期；枚举 name 作 kind；收支带符号、转账不带；RFC 4180 转义；前置 UTF-8 BOM），并补单测，以满足 FR-019，路径为 `lib/features/ledger/domain/export/transaction_csv.dart`、`test/unit/features/ledger/domain/export/transaction_csv_test.dart`
- [X] T050 [US3] 新增 `share_plus` 与 `cross_file` 依赖，并实现 `TransactionExportService`（生成字符串 → 写临时文件 → 交给 `share_plus`；不为 share 抽接口），路径为 `pubspec.yaml`、`lib/features/ledger/domain/services/transaction_export_service.dart`
- [X] T051 [US3] 新建 `SearchViewModel` + `searchResults` provider（不用 family、不用 `keepAlive`、不做 debounce；日分组复用既有顶层 `groupTransactionsByDay`），并补状态流转单测，路径为 `lib/features/ledger/presentation/view_model/search_view_model.dart`、`test/unit/features/ledger/presentation/search_view_model_test.dart`
- [X] T052 [P] [US3] 为 `AppTextField` 增加可选 `onChanged` 与 `controller`（宪章 III 允许以命名 DS 变体扩展；不绕过 DS 直接用裸 `TextField`），路径为 `lib/app/design_system/app_text_field.dart`
- [X] T053 [US3] 新建搜索屏与筛选表单（类型 chips + 账户/分类选择器 + 日期范围；复用 `LedgerTimeline`/`TransactionTile`/`LedgerEmpty`/`LedgerSkeleton`），注册 `/ledger/search` 路由并在账本页加入口；导出按钮在无结果时禁用（SC 见 FR-019 的「导出所见即所得」），路径为 `lib/features/ledger/presentation/screens/search_screen.dart`、`lib/features/ledger/presentation/widgets/transaction_filter_sheet.dart`、`lib/app/router/app_router.dart`
- [X] T054 [US3] 编写搜索屏组件测试：结果渲染、空态、无结果时导出按钮禁用，路径为 `test/ui/features/ledger/search_screen_test.dart`
- [X] T055 [US3] 补齐四份 ARB 的检索与导出文案并重新生成，路径为 `lib/app/l10n/app_{en,zh,zh_Hans,zh_Hant}.arb`
- [X] T056 [US3] 门禁：`dart run build_runner build -d`、`flutter gen-l10n`、`flutter analyze` 零问题、`flutter test` 不减少，路径为仓库根

**Checkpoint**: 历史数据找得到、带得走。✅

> **执行记录（2026-09-22，311 项测试通过，analyze 零问题）**：
> - **T046 抓到实现缺陷**：我按计划转义了 LIKE 元字符（`%` → `\%`），但**没有声明 `ESCAPE`**——于是 SQLite 把 `\%` 读成「字面反斜杠 + 通配符」，比不转义更糟：搜 `50% off` 一条也返回不了。计划里我原本写的是「若 Drift 的 `like` 表达不了 `ESCAPE` 就先不处理并留 ponytail 注释」，实际查证 `like(regex, {String? escapeChar})` **支持** escapeChar。已按正确做法修（`escapeChar: r'\'` 传给三个 `like`），`\` 本身先转义以免自我转义。测试断言的是用户可见行为（`%` 是字面量），所以它正确地失败并逼出真修法。
> - **T053 的两处 API 误用由 analyze 抓出**：`LedgerTimeline` 是 **sliver**（`SliverMainAxisGroup`）且接收整张 `groupedTransactions` map，不是「每天一个 box 组件」——首版按后者写，改用 `CustomScrollView` + 单个 `LedgerTimeline`。`categoryListProvider` 是 `CategoryType` family 而非可空——筛选面板改为同时 watch 支出与收入两类再合并。
> - **T051 里两次自我修正**：先写了以 `List<TransactionEntity>` 为 key 的 family provider 做导出，随即意识到 Dart 的 `List` 用**恒等相等**，每次重建都会造一个新 provider（泄漏）。改为 `SearchViewModel.export(rows)` 方法。同时 `searchResults` 改为返回 `SearchResults{entities, tiles}`，让「渲染用」和「导出用」来自**同一次订阅**，这样导出的文件不可能与屏幕内容不一致。
> - **T049 删掉了一个自己造的累赘**：CSV 函数原本收一个 `currencySymbol` 参数，但 `currency` 列已经带 ISO 代码（对机器可读文件更正确），我甚至写了个 `extension on Never` 去「说明」这个参数——已把参数和那个 extension 一并删除。
> - T052 为 `AppTextField` 增加可选 `controller`/`onChanged`（宪章 III 允许的命名 DS 变体扩展），并加 assert 禁止同时传 `controller` 与 `initialValue`。
> - 账本页的搜索入口在 T053 一并补上（T015 当时刻意留到路由存在时再加）。

---

## Phase 7: Convergence（收敛与验收）

**Purpose**: 全量门禁与架构断言复核。**SC-010 是本 spec 全部技术前提的验收点**——一旦它失败，说明动了事件 payload 或表结构，本 plan 的零写模型变更承诺即不成立。

- [X] T057 运行代码生成、`flutter gen-l10n`、`flutter analyze` 与完整 `flutter test`，修复所有新增失败并记录实际项数，路径为仓库根
- [X] T058 复核 SC-010：`git diff lib/features/ledger/domain/events/ledger_events.dart lib/core/data/database/tables.dart` **必须为空**；并确认 `AppDatabase.schemaVersion` 仍为 1、`MigrationStrategy.onUpgrade` 未被改动，路径为 `lib/features/ledger/domain/events/ledger_events.dart`、`lib/core/data/database/tables.dart`、`lib/core/data/database/app_database.dart`
- [ ] T059 按 `spec.md` 的验收场景手工验收四个故事（转账闭环、周期闭环、检索与导出、备份与恢复的完整往返），并把结果记入本文件，路径为 `specs/004-p0-core-finance-loop/tasks.md`

  > **部分完成 —— GUI 交互部分未执行。** 我不能驱动界面，所以「手工点击验收」由两部分代替：
  > **(a) 可自动化的部分已有测试覆盖**，逐条对照见下方映射表；
  > **(b) 应用端到端跑通**：`flutter build linux --debug` 构建成功，二进制实际启动并完成播种
  > （日志见「启动验证」），说明 `main.dart` 的新接线（恢复替换 → 建容器 → 播种 → 重建门禁 →
  > 周期补课 → 应用恢复偏好 → runApp）在真实进程里没有崩溃。
  > **仍未验证的**：需要人眼与手指的部分 —— 转账行在屏幕上的配色、CSV 在真实 Excel 里打开、
  > 分享面板与文件选择器在两个移动平台上的行为、以及「暂存后重启」的完整往返。
- [X] T060 将本 spec 落地后 AGENTS.md 中已不成立的现状描述更新（转账 UI 缺失、周期链路「未完成」、无检索/导出/备份三处），路径为 `AGENTS.md`

  > 除逐条订正外，新增「数据可携带性与恢复（spec 004）」一节，记录四个故事的**承重不变量**：
  > 转账更正的 kind 守卫、`before:` 必传的 rrule 陷阱、`isReversed` 在 SQL 层过滤、
  > 恢复的暂存-替换模型与 `-wal` 删除、以及「用户版本号相同但 schema 不可读」这道校验。

---

## 验收场景覆盖映射（T059）

`spec.md` 的用户故事验收场景逐条对应到测试。**「自动化」列是已通过的测试；「手工」列尚未执行**
（见 T059 的执行记录）。

### US1 转账

| 场景 | 覆盖 |
|---|---|
| 1. 从 A 转 B，余额一增一减、kind=transfer | `transfer_correction_test.dart`（A1 断言两条 posting 与余额）、`transfer_form_screen_test.dart`（保存后 cash 75000 / bank 25000） |
| 2. 改成 150，余额等于「一开始就记 150」 | `transfer_correction_test.dart`「a corrected transfer leaves the balances a fresh recording would」—— 已做**变异验证** |
| 3. transfer 原交易按收入更正被拒 | `transfer_correction_test.dart`「correcting a transfer as income is rejected…」 |
| 4. income 原交易按转账更正被拒 | `transfer_correction_test.dart`「correcting an income as a transfer is rejected」 |
| 5. 「到」候选排除自身与异币种账户 | `transfer_form_screen_test.dart`「the to picker excludes the from account and other currencies」 |
| — 转账入口 | 无独立入口；`transfer_form_screen_test.dart`「tapping Transfer swaps the form to the transfer layout」覆盖从表单内切换 |
| 6. 同账户错误显示本地化文案 | `ledger_error_localizer_test.dart`（`sameAccountTransfer` 有专属 case）＋ `transfer_display_test.dart` |
| 7. 详情页中性色、无符号、编辑删除可用 | `transfer_display_test.dart`（3 项，含「支出仍是红色带减号」的对照） |
| — 转账行在真实设备上的观感 | **手工，未验** |

### US2 周期账单

| 场景 | 覆盖 |
|---|---|
| 1. 创建系列并物化未来实例 | `recurring_series_test.dart`「creating a series stores it and materializes its instances」 |
| 2. 重复物化不产生重复实例 | 同上「materializing twice produces the identical instance set」（SC-004） |
| 3. 记入产生一条事件且同事务翻状态 | 同上「posting an instance records one transaction and flips its status」 |
| 4. 跳过不产生事件、不动余额 | 同上「skipping writes no event and moves no money」 |
| 5. 已 posted 再处理被拒且是专属码 | 同上「posting/skipping an already-posted instance…」 |
| 6. 停用后保留既有实例、不再新增 | 同上「deactivating keeps existing instances and adds no more」 |
| 7. 未知 status 降级不抛 | `scheduled_status_test.dart` |
| — 待入账行的呈现与记入/跳过/停用 | `pending_bill_test.dart`（7 项：降透明度 + 时钟 + 标签、与分类标签并存、记入需确认、取消不记、跳过不确认、停用需确认、失败码本地化） |
| — 表单里「重复」行与保存顺序 | `transaction_form_repeat_test.dart`（6 项：新建可重复且默认不重复、转账无此行、编辑无此行、先记账后建系列且 `startDate` 是下一次发生、不重复时只记账、建系列失败不丢已记的账） |
| — 真实设备上的启动补课 | **已验**，见下方「物化策略实测」（真库 + 真进程，四种频率逐一核对） |

### US3 检索与导出

| 场景 | 覆盖 |
|---|---|
| 1. 关键词命中备注/分类快照/账户名，按天倒序 | `transaction_dao_filter_test.dart`「the keyword matches…」 |
| 2. 多条件 AND，账户筛选下转账只出现一次 | 同上「combines conditions with AND」＋「an account filter returns a whole transfer, both legs」＋ `ledger_repository_filter_test.dart` |
| 3. 冲销行不出现 | 同上「a reversed transaction is excluded」 |
| 4. 日期范围两端含端点 | 同上「the date range includes both endpoints, by day」 |
| 5. CSV 含 BOM、RFC 4180 转义 | `transaction_csv_test.dart`（11 项） |
| 6. 无结果时导出禁用 | `search_screen_test.dart`「export is disabled while there is nothing to export」 |
| — CSV 在真实 Excel/分享面板中的表现 | **手工，未验** |

### US4 备份与恢复

| 场景 | 覆盖 |
|---|---|
| 1. 单文件归档含三个条目、库由 VACUUM 产出 | `backup_service_test.dart`「produces a three-entry archive…」＋「the snapshot is a complete SQLite database」 |
| 2. 确认框写明事件条数对比 | `backup_screen_test.dart`「restoring states what it would discard…」＋ `BackupPreview` 三项算术测试 |
| 3. 异版本/错误 format 被拒且不留 PENDING | 同上「refuses a zip that is not one of ours」＋「refuses a backup from a future schema version」 |
| 4. 损坏内容被拒且不留 PENDING | 同上「refuses a truncated database…」＋「refuses a database whose schema this build cannot read」 |
| 5. 下次启动替换、副档清除、偏好应用 | `pending_restore_test.dart`（12 项） |
| 6. 替换失败回滚 | 同上「resumes an interrupted swap instead of wedging」＋「a marker with no staged database leaves the ledger alone」 |
| 7. 恢复前数据留有 `db.sqlite.replaced` | 同上（顺路径断言） |
| — 暂存后重启的完整往返、分享面板/文件选择器 | **手工，未验** |

### 启动验证（T057/T059 的端到端部分）

```
$ flutter build linux --debug
✓ Built build/linux/x64/debug/bundle/feather_ledger
$ ./build/linux/x64/debug/bundle/feather_ledger
Seeding default categories and accounts via the event stream...
（运行 25 秒无异常，由 timeout 结束）
```

第一次运行**崩溃**，原因不是本次改动：开发机上的 `~/.local/share/com.example.feather_ledger/db.sqlite`
是 2026-01-22 留下的、**事件溯源迁移之前**的库（`user_version` 同样是 1，表是旧的
`accounts`/`categories`/`transactions`），drift 认为版本一致便跳过迁移，于是第一条事件查询就
`no such table: ledger_events`。把该文件改名为 `db.sqlite.pre-event-sourcing.bak` 后启动正常
（spec 003 已声明开发库可丢弃）。

**这次崩溃直接暴露了 US4 的一个真实漏洞**：这样一个库 `user_version` 与当前 `schemaVersion` 相同、
`PRAGMA integrity_check` 也通过，因此 `stageRestore` 会**接受**它——用户会在自己当前账本已被替换之后，
才遇到上面那个崩溃。已补上第四道校验（用真实 DAO 读一次事件表），并加了对应的拒绝测试；
该测试经过**变异验证**：去掉这次读，它会以 `Expected: Failure, Actual: Success` 失败。

### 物化策略实测（2026-09-22，滚动窗口版）

单元测试用「本地零点」作为系列起点，而启动路径读的是库里存的时刻，两者未必等价——所以这一轮
把四种频率**放进真实进程 + 真实数据库**里各跑一遍（`XDG_DATA_HOME` 指向临时目录，库由应用自己
seed，系列用 SQL 直接插入 `recurring_series`）：

| 频率 | 实例数 | 覆盖范围 | 结论 |
|---|---|---|---|
| MONTHLY | 3 | 2026-09-22 → 2026-11-22 | 窗口内恰好三个 |
| WEEKLY | 12 | — | 窗口内 ~13，被上限截断 |
| DAILY | 12 | — | 窗口内 90，被上限截断 |
| YEARLY | 3 | 2026-09-22 → 2028-09-22 | 窗口内没有，下限向后取满 |

连续两次启动的实例 **id 集合完全相同**（幂等），启动到写完实例 **< 1 秒**（上一轮 37 秒缺陷的守卫）。

> 过程中的一个坑，值得记下：手工插系列时 `start_date` 一度按**毫秒**写入，而 drift 存的是**秒**，
> 于是应用把它读成公元 58,695 年。这暴露了该状态下的行为与直觉不符（远未来起点只落 1 个实例，
> 而非下限的 3 个）——但**该状态在 UI 上不可达**（表单只把 `startDate` 设为所选日期的下一次发生，
> 最远约一年），是坏 fixture 造出来的，故不修，记录在此。

### ⚠️ 待决策：月度系列的「日不存在的月份被跳过」（既有缺陷，非本轮引入）

写编辑功能的测试时撞上的，**与编辑无关**，但很严重，先记录不擅自修。

`_materializeSeries` 把系列的起点转成 **UTC** 后再交给 `package:rrule`
（`startUtc = series.startDate.toUtc()`）。在东八区，本地的「1 号零点」因此变成 UTC 的「上个月 31 号 16:00」，
规则的 day-of-month 就成了 31。rrule 按 RFC 5545 办事——**日不存在的月份直接跳过**、不钳到月末，
于是这条每月系列只在 31 天的月份出账单：

```
本地起点 2026-01-01 → 规则日 31 → 实际产出 12/31、1/31、3/31、5/31、7/31、8/31、10/31
                                    （2、4、6、9、11 月整月没有账单）
```

实测（`dart run` 直接调 rrule，同样的入参）：7 个候选，缺的正是 2/4/6/9/11 月。影响面不小——
**在东八区把一笔月租设在 1 号是最常见的用法**，而它会漏掉一年里 5 个月的账单。
day 22 之类的起点不受影响，所以之前几轮的实测没暴露它。

修的方向是把这条规则**按本地日历**构造（本地起点 + 本地 before），但对已经存在的坏系列来说，
生成的实例时刻会变 → 派生 id 会变 → **物化会把它们全部重复一遍**。所以修之前要先决定旧数据怎么办
（一次性迁移？还是按「ids 变了就重算」的方式先清空这些系列的待入账行）。**需要用户拍板，故未动。**

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1（Setup）** 阻塞一切。T077/T080 未收口则 ARB 冲突，T003 未完成则没有可靠基线。
- **Phase 2（Foundational）** 阻塞 US1 与 US2：错误码与编解码是两者的共用前置。T005–T009 彼此独立，可并行。
- **Phase 3（US1）** 依赖 Phase 2 的 T005/T006/T007。
- **Phase 4（US4）** 与 Phase 3 完全正交，但共用 `pubspec.yaml` 与 `main.dart`（后者在 US2 才用到）。T025/T026 独立于 T021–T024，可并行启动。
- **Phase 5（US2）** 依赖 Phase 2 的 T008/T009 与 Phase 4 对 `main.dart` 的改动定型。
- **Phase 6（US3）** 依赖 Phase 3 的 T015（账本页 app bar 的搜索 action 与转账 action 同处一个 `actions` 列表）。
- **Phase 7** 阻塞于全部。

### 关键约束

- **T010 的测试 T011 是承重的**：它断言单次 append 与余额等价性（SC-002）。`_appendCorrection` 的抽取正是重构可能把「冲销 + 重记」悄悄拆成两次 append 的地方，那会让账目翻倍。
- **T036 的幂等断言是承重的**：`'${seriesId}_${date.millisecondsSinceEpoch}'` 是周期幂等性的**唯一**保证；`series.id` 或日期归一化一变，每个实例都会重复。
- **T029 的顺序无自动化守卫**：`applyPendingRestore` 必须早于任何 `appDatabaseProvider` 读取。这是全 spec 唯一无自动化测试的接线点，两处注释必须写明。
- **T040 与 T035 必须同时落地或 T035 保留转发**：`watchScheduledTransactions` 在 `LedgerViewModel` 的死订阅里还有一个调用方，T040 才删。
- **T045 不得为筛选加索引**：`LIKE '%x%'` 用不上，且加索引就是 schema 变更，会破坏 SC-010。

### 并行机会

- T005–T009（Phase 2）：五个独立文件。
- T022/T023/T025（Phase 4）：偏好导出、manifest、文件舞蹈三者互不依赖。
- T044/T049/T052（Phase 6）：值对象、CSV 纯函数、DS 扩展三者互不依赖。
