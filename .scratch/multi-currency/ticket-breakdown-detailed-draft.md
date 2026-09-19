# 多币种细粒度任务拆分草案

状态：待审阅，尚未发布为任务。原 01–16 为现有决策票；以下编号 17–48 为建议编号，避免覆盖。每项是可验证的纵向切片；具体文件为基于当前代码的预计新建或修改范围，实施前应再次核对，生成代码通过生成器更新。新用户要求明确列出文件，优先于技能对任务中避免文件路径的建议。

## 测试优先和共同约束

每票按所列首个行为：先在指定公开接缝写一个失败测试并运行确认失败，再用最小实现使其通过；逐条重复，不先批量编写所有测试。测试验证可观察行为而非私有方法。建议接缝：账本/周期/账户/备份 service 与真实测试数据库，必要时使用 widget 和通知平台适配边界；每票结束运行相关测试与分析。新用户界面文案须更新 `lib/app/l10n/app_en.arb`、`lib/app/l10n/app_zh.arb`、`lib/app/l10n/app_zh_Hans.arb`、`lib/app/l10n/app_zh_Hant.arb` 并运行生成器；表结构和 Riverpod 生成文件同理。自动入账在 28 的保护下保持关闭，直至 48 安全门解除；不授权删除任何现有数据。未确认的期次身份和恢复算法先在对应票内通过失败测试和原型验证，不将候选结构当成事实。

现有文件路径仅说明预计触点；如果同一责任需要新抽象，先确认不重复现有接缝，再将新增文件作为实施时的明确变更记录。

## 17. 首次语言映射与币种偏好

**依赖：** 无

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

## 18. 账户创建选择不可变币种

**依赖：** 17

**交付：** 创建时选择账户币种，写入与重建一致。

**先写失败测试：** 先测试人民币设置下新建美元账户及重放。

**验收条件：**

- [ ] 默认当前币种，可选择五种。
- [ ] 创建后不能修改。
- [ ] 事件重放保持账户币种。

**预计修改的生产文件：**

- `lib/features/settings/presentation/widgets/account_form_sheet.dart`
- `lib/features/settings/domain/services/account_service.dart`
- `lib/features/settings/domain/commands/create_account_command.dart`
- `lib/features/ledger/data/projections/ledger_projector.dart`

**预计修改的测试文件：**

- `test/ui/features/settings/account_form_sheet_test.dart`
- `test/unit/features/settings/domain/services/account_service_test.dart`
- `test/unit/features/ledger/domain/services/projection_rebuild_equivalence_test.dart`

## 19. 账户管理按币种筛选

**依赖：** 18

**交付：** 筛选其他或全部币种并区分同符号币种。

**先写失败测试：** 先测试 CNY 和 JPY 同符号混看与筛选。

**验收条件：**

- [ ] 默认当前币种。
- [ ] 创建其他币种后局部切换，不改变全局设置。
- [ ] 混看显示符号与代码，不混合合计。

**预计修改的生产文件：**

- `lib/features/settings/presentation/screens/account_management_screen.dart`
- `lib/features/settings/presentation/widgets/account_tile.dart`
- `lib/shared/presentation/models/account_ui_model.dart`

**预计修改的测试文件：**

- `test/ui/features/settings/account_tile_test.dart`
- `test/unit/shared/presentation/account_ui_model_test.dart`

## 20. 其他币种账户余额调整

**依赖：** 18

**交付：** 调整其他币种账户余额并明确其所属账本。

**先写失败测试：** 先测试 CNY 当前设置下调整 USD 账户及生成交易币种。

**验收条件：**

- [ ] 调整金额按账户币种。
- [ ] 显示币种与交易所在账本提示。
- [ ] 当前设置不变，调整不计收入支出。

**预计修改的生产文件：**

- `lib/features/settings/presentation/widgets/account_form_sheet.dart`
- `lib/features/settings/domain/services/account_service.dart`
- `lib/features/ledger/domain/commands/record_transaction_command.dart`

**预计修改的测试文件：**

- `test/ui/features/settings/account_form_sheet_test.dart`
- `test/unit/features/settings/domain/services/account_service_test.dart`

## 21. 写入时拒绝跨币种转账

**依赖：** 18

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

## 22. 交易表单锁定币种

**依赖：** 18、21

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

## 23. 账本列表隔离当前币种

**依赖：** 18

**交付：** 账本交易与待入账只展示当前币种。

**先写失败测试：** 先构造同月 CNY/USD 交易与账单并断言只显示所选币种。

**验收条件：**

- [ ] 当前币种查询同时限定交易与待入账。
- [ ] 归档及排除合计交易可见规则不变。
- [ ] 切换币种不改变数据。

**预计修改的生产文件：**

- `lib/features/ledger/domain/queries/watch_transactions_query.dart`
- `lib/features/ledger/domain/queries/watch_scheduled_transactions_query.dart`
- `lib/features/ledger/data/repositories/ledger_repository.dart`
- `lib/features/ledger/presentation/view_model/ledger_view_model.dart`

**预计修改的测试文件：**

- `test/unit/features/ledger/data/ledger_repository_filter_test.dart`
- `test/ui/features/ledger/pending_bill_test.dart`

## 24. 日月合计及空状态按币种

**依赖：** 23

**交付：** 账本合计、余额及空状态不混币。

**先写失败测试：** 先测试同日 CNY/USD 互不混加和有余额空状态。

**验收条件：**

- [ ] 日小计、月收支及余额先限定币种。
- [ ] 有账户无交易显示余额及零收支。
- [ ] 无账户显示零及创建引导。

**预计修改的生产文件：**

- `lib/features/ledger/domain/queries/watch_monthly_snapshot_query.dart`
- `lib/features/ledger/presentation/models/ledger_day_group.dart`
- `lib/features/ledger/presentation/widgets/ledger_empty.dart`
- `lib/shared/presentation/models/monthly_summary_ui_model.dart`

**预计修改的测试文件：**

- `test/unit/features/ledger/presentation/ledger_day_group_test.dart`
- `test/unit/features/ledger/domain/services/monthly_snapshot_test.dart`
- `test/ui/features/ledger/ledger_timeline_test.dart`

## 25. 切换币种时的异步一致性

**依赖：** 23、24

**交付：** 快速切币不会以新符号标旧数据。

**先写失败测试：** 先延迟旧币种结果并验证切换后不能覆盖新结果。

**验收条件：**

- [ ] 快速切换及相邻月份缓存中金额、标签及空状态一致。
- [ ] 旧请求迟到不会覆盖新币种结果。

**预计修改的生产文件：**

- `lib/features/ledger/presentation/view_model/ledger_view_model.dart`
- `lib/features/ledger/presentation/view_model/ledger_view_state.dart`
- `lib/features/ledger/presentation/screens/ledger_screen.dart`

**预计修改的测试文件：**

- `test/ui/features/ledger/ledger_month_switch_test.dart`
- `test/unit/features/ledger/presentation/ledger_currency_test.dart`

## 26. 搜索限定当前币种

**依赖：** 18

**交付：** 关键词和账户等条件在当前币种内搜索。

**先写失败测试：** 先测试相同关键词不同币种只返回当前币种。

**验收条件：**

- [ ] 组合关键词、账户、分类、类型、日期不跨币种。
- [ ] 账户管理筛选不影响搜索。
- [ ] 切换不会误标。

**预计修改的生产文件：**

- `lib/features/ledger/domain/queries/search_transactions_query.dart`
- `lib/features/ledger/domain/value_objects/transaction_filter.dart`
- `lib/features/ledger/presentation/view_model/search_view_model.dart`

**预计修改的测试文件：**

- `test/unit/features/ledger/presentation/search_view_model_test.dart`
- `test/ui/features/ledger/search_screen_test.dart`

## 27. 分类报表与热度图隔离币种

**依赖：** 18

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

## 28. 安全关闭旧自动入账入口

**依赖：** 无

**交付：** 在新资格与恢复屏障完成之前防止中间版本误自动记账。

**先写失败测试：** 先测试账户恢复与通知响应不能绕过安全门自动入账。

**验收条件：**

- [ ] 启动、账户恢复、通知响应不绕过统一安全门。
- [ ] 默认禁用自动记账。
- [ ] 手动记入不受阻。

**预计修改的生产文件：**

- `lib/main.dart`
- `lib/features/settings/domain/services/account_service.dart`
- `lib/features/ledger/presentation/notifications/reminder_response_handler.dart`
- `lib/features/ledger/domain/services/recurring_service.dart`

**预计修改的测试文件：**

- `test/unit/features/settings/domain/services/account_lifecycle_test.dart`
- `test/ui/features/ledger/reminder_response_handler_test.dart`
- `test/unit/features/ledger/domain/services/recurring_series_test.dart`

## 29. 保存账单创建模式

**依赖：** 22、28

**交付：** 计划、订阅、重复账单保留创建模式。

**先写失败测试：** 先测试三种模式创建后重启仍可区分。

**验收条件：**

- [ ] 创建时持久化模式，重启和备份保持。
- [ ] 创建后不可切换。
- [ ] 交易入账后仍普通展示。

**预计修改的生产文件：**

- `lib/core/data/database/tables.dart`
- `lib/core/data/database/app_database.dart`
- `lib/features/ledger/domain/commands/create_recurring_series_command.dart`
- `lib/features/ledger/presentation/view_model/transaction_form_view_model.dart`

**预计修改的测试文件：**

- `test/ui/features/ledger/transaction_form_repeat_test.dart`
- `test/unit/features/ledger/domain/services/recurring_series_test.dart`

## 30. 三种本机自动入账开关

**依赖：** 28、29

**交付：** 三类开关默认关闭且不随备份迁移。

**先写失败测试：** 先测试源设备开关不同于目标设备时恢复仍保留目标值。

**验收条件：**

- [ ] 计划、订阅、重复开关分别配置。
- [ ] 默认关闭并跨重启保存。
- [ ] 恢复保留目标设备设置，不备份开关或原始历史。

**预计修改的生产文件：**

- `lib/features/settings/presentation/screens/settings_screen.dart`
- `lib/core/domain/repositories/preferences_repository.dart`
- `lib/core/data/repositories/preferences_repository.dart`
- `lib/features/settings/domain/services/backup_service.dart`

**预计修改的测试文件：**

- `test/unit/core/data/repositories/preferences_repository_backup_test.dart`
- `test/unit/features/settings/data/backup_service_test.dart`

## 31. 关闭开关与币种暂停的手动资格

**依赖：** 23、29、30

**交付：** 关闭或切走币种时的逾期账单永久手动。

**先写失败测试：** 先测试开关开启与到期同毫秒和切回后不自动补记。

**验收条件：**

- [ ] 关闭/离开时已到期及关闭/暂停期间到期的期次永久手动，切回或开启后不补记。
- [ ] 同毫秒视为已到期。
- [ ] 资格跨重启保留。

**预计修改的生产文件：**

- `lib/core/data/database/tables.dart`
- `lib/features/ledger/domain/services/recurring_service.dart`
- `lib/features/ledger/data/repositories/recurring_repository.dart`
- `lib/core/presentation/providers/currency_provider.dart`

**预计修改的测试文件：**

- `test/unit/features/ledger/domain/services/recurring_series_test.dart`
- `test/unit/core/presentation/currency_controller_test.dart`

## 32. 创建及编辑时自动资格

**依赖：** 31

**交付：** 已到期账单修改后不被误自动入账。

**先写失败测试：** 先测试到期后修改金额与无变化保存分别产生手动和原资格。

**验收条件：**

- [ ] 创建已到期或改期到过去转手动。
- [ ] 到期前修改金额或描述保持原资格。
- [ ] 到期后实际改账务字段转手动，无变更不误转。
- [ ] 检测到不可靠回拨转手动。

**预计修改的生产文件：**

- `lib/features/ledger/domain/commands/create_recurring_series_command.dart`
- `lib/features/ledger/domain/commands/update_recurring_bill_command.dart`
- `lib/features/ledger/domain/services/recurring_service.dart`

**预计修改的测试文件：**

- `test/unit/features/ledger/domain/services/recurring_series_test.dart`
- `test/ui/features/ledger/recurring_bill_edit_test.dart`

## 33. 逾期账单按月增量补齐

**依赖：** 31、32

**交付：** 长期未启动的账单可逐月找回。

**先写失败测试：** 先测试每日系列停用超过 12 期后所有月份可找到。

**验收条件：**

- [ ] 超过 12 期可有界分页并接续。
- [ ] 原月份显示，月份选择器标记未物化待处理期。
- [ ] 失败及手动项不阻断后续。
- [ ] 手动记入沿用排定日期。

**预计修改的生产文件：**

- `lib/features/ledger/domain/commands/project_recurring_events_command.dart`
- `lib/features/ledger/domain/queries/watch_scheduled_transactions_query.dart`
- `lib/shared/presentation/widgets/feather_month_picker.dart`

**预计修改的测试文件：**

- `test/unit/features/ledger/domain/services/recurring_materialization_test.dart`
- `test/ui/features/ledger/pending_bill_test.dart`

## 34. 时区及夏令时稳定期次

**依赖：** 33

**交付：** 当地时间变化后按新时区正确判断期次。

**先写失败测试：** 先测试夏令时跨日历日及反复跨时区不复制账单。

**验收条件：**

- [ ] 当前时区本地时间为准。
- [ ] 跳过时刻顺延拨钟时长、重复取第一次。
- [ ] 逻辑身份与手动资格不因时区切换改变。

**预计修改的生产文件：**

- `lib/features/ledger/domain/commands/project_recurring_events_command.dart`
- `lib/features/ledger/domain/entities/ledger_entities.dart`
- `lib/features/ledger/domain/commands/update_recurring_bill_command.dart`

**预计修改的测试文件：**

- `test/unit/features/ledger/presentation/recurring_time_test.dart`
- `test/unit/features/ledger/domain/services/recurring_materialization_test.dart`

## 35. 整条系列改期保持期次状态

**依赖：** 32、33

**交付：** 整条系列改期时保留手动资格并避免已记账期次重复。

**先写失败测试：** 先测试每月 1 日改 3 日，手动与已入账期次各自保留语义。

**验收条件：**

- [ ] 手动期次对应移动，已入账保留原交易且对应新期不产生。
- [ ] 月末缺失日期不按生成序号对应。
- [ ] 跨周期以选中日期为锚。

**预计修改的生产文件：**

- `lib/features/ledger/domain/commands/update_recurring_bill_command.dart`
- `lib/features/ledger/domain/commands/project_recurring_events_command.dart`
- `lib/features/ledger/data/repositories/recurring_repository.dart`

**预计修改的测试文件：**

- `test/ui/features/ledger/recurring_bill_edit_test.dart`
- `test/unit/features/ledger/domain/services/recurring_series_test.dart`

## 36. 本次及以后改期与月末例外

**依赖：** 35

**交付：** 系列拆分时只改变选定范围且不丢失月末账单。

**先写失败测试：** 先测试 30 日改 31 日保留 4 月手动账单及拆分边界。

**验收条件：**

- [ ] 范围之前不变。
- [ ] 不存在对应日期的手动账单保留原日期。
- [ ] 新增历史期不补造。
- [ ] 再次改期同一期同日只保留一笔。

**预计修改的生产文件：**

- `lib/features/ledger/domain/commands/update_recurring_bill_command.dart`
- `lib/features/ledger/domain/commands/project_recurring_events_command.dart`

**预计修改的测试文件：**

- `test/ui/features/ledger/recurring_bill_edit_test.dart`
- `test/unit/features/ledger/domain/services/recurring_series_test.dart`

## 37. 有限次数删除与补期

**依赖：** 35、36

**交付：** 删除指定期后在系列末尾补足有效次数。

**先写失败测试：** 先测试 3 次系列删除中间期后末尾恰补一期。

**验收条件：**

- [ ] 已入账与保留手动期次占用原上限。
- [ ] 仅删除一期释放次数并补一期。
- [ ] 补期资格独立判断，原期不复活。

**预计修改的生产文件：**

- `lib/features/ledger/domain/commands/delete_recurring_bill_command.dart`
- `lib/features/ledger/domain/commands/project_recurring_events_command.dart`
- `lib/features/ledger/data/repositories/recurring_repository.dart`

**预计修改的测试文件：**

- `test/unit/features/ledger/domain/services/recurring_materialization_test.dart`
- `test/unit/features/ledger/domain/services/recurring_series_test.dart`

## 38. 启动补记分批和进度

**依赖：** 31、33

**交付：** 应用先进入界面，再分批处理启动前合格账单。

**先写失败测试：** 先测试大量账单不阻塞首帧并可观察处理进度。

**验收条件：**

- [ ] 启动截点固定。
- [ ] 前台期间新到期等下次启动。
- [ ] 逐步更新账本并显示成功、失败、用户处理及转手动。

**预计修改的生产文件：**

- `lib/main.dart`
- `lib/features/ledger/domain/services/recurring_service.dart`
- `lib/features/ledger/presentation/screens/ledger_screen.dart`

**预计修改的测试文件：**

- `test/unit/features/ledger/domain/services/recurring_series_test.dart`
- `test/ui/features/ledger/pending_bill_test.dart`

## 39. 补记中断接续及独立批次

**依赖：** 38

**交付：** 系统终止后恢复原批次，新增到期期次另建批次。

**先写失败测试：** 先测试处理一半终止并在新增到期后重启，两批次无重复。

**验收条件：**

- [ ] 后台尽力继续。
- [ ] 重启累计结果不丢，独立显示新批次。
- [ ] 历史未物化期次分批处理。
- [ ] 原子与幂等防重复。

**预计修改的生产文件：**

- `lib/features/ledger/domain/services/recurring_service.dart`
- `lib/features/ledger/domain/commands/convert_scheduled_to_posted_command.dart`
- `lib/core/data/database/tables.dart`

**预计修改的测试文件：**

- `test/unit/features/ledger/domain/services/convert_scheduled_to_posted_test.dart`
- `test/unit/features/ledger/domain/services/recurring_materialization_test.dart`

**预计新建的文件（实施时先核对是否可复用现有模块）：**

- 建议新建 `lib/features/ledger/domain/entities/automatic_posting_batch.dart`：批次和成员结果的领域表达。
- 建议新建 `test/unit/features/ledger/domain/services/automatic_posting_batch_test.dart`：跨中断的批次行为测试。

## 40. 补记失败重试和用户竞争

**依赖：** 39

**交付：** 失败账单和用户先行处理会更新原批次结果。

**先写失败测试：** 先测试成功 9 失败 1 后重试成功变成成功 10 失败 0。

**验收条件：**

- [ ] 失败留原月份可重试或手动。
- [ ] 重试成功替代失败计数。
- [ ] 手动记入或删除计用户处理。
- [ ] 实际修改计转手动，每笔仅一类。

**预计修改的生产文件：**

- `lib/features/ledger/domain/services/recurring_service.dart`
- `lib/features/ledger/domain/commands/convert_scheduled_to_posted_command.dart`
- `lib/features/ledger/domain/commands/update_recurring_bill_command.dart`

**预计修改的测试文件：**

- `test/unit/features/ledger/domain/services/recurring_series_test.dart`
- `test/unit/features/ledger/domain/services/convert_scheduled_to_posted_test.dart`

## 41. 恢复屏障与未物化候选

**依赖：** 30、33、39

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

## 42. 恢复批次分别确认及延期

**依赖：** 40、41

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

## 43. 恢复确认切币和开关例外

**依赖：** 31、42

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

## 44. 恢复确认编辑及竞争

**依赖：** 36、42、43

**交付：** 确认内容变化时重新询问，确认后修改不误记。

**先写失败测试：** 先测试确认期间金额变化但数量不变，旧确认不能生效。

**验收条件：**

- [ ] 待确认修改后重查，改未来保留资格。
- [ ] 对话框账务字段变化需重新确认。
- [ ] 同意后处理前实际修改转手动，原子竞争不重复记账。

**预计修改的生产文件：**

- `lib/features/ledger/domain/commands/update_recurring_bill_command.dart`
- `lib/features/settings/domain/services/backup_service.dart`
- `lib/features/ledger/domain/services/recurring_service.dart`

**预计修改的测试文件：**

- `test/unit/features/settings/data/backup_service_test.dart`
- `test/ui/features/ledger/recurring_bill_edit_test.dart`

## 45. 按币种协调提醒和通知操作

**依赖：** 23、31、33

**交付：** 非当前币种暂停未来提醒，旧通知仍可操作。

**先写失败测试：** 先测试 CNY 当前设置下通过 USD 通知记入且设置不变。

**验收条件：**

- [ ] 取消旧币种未触发提醒而保留已显示通知，切回不补发。
- [ ] 从旧通知可按原币种编辑或手动记入且设置不变。
- [ ] 入账后取消未触发提醒。

**预计修改的生产文件：**

- `lib/features/ledger/data/notifications/recurring_reminders.dart`
- `lib/features/ledger/presentation/notifications/reminder_response_handler.dart`
- `lib/features/ledger/presentation/screens/recurring_bill_form_screen.dart`

**预计修改的测试文件：**

- `test/unit/features/ledger/data/notifications/recurring_reminders_test.dart`
- `test/ui/features/ledger/reminder_response_handler_test.dart`

## 46. 通知追踪账单改期及删除

**依赖：** 36、45

**交付：** 旧通知能打开改期后的账单或报告已删除。

**先写失败测试：** 先测试通知显示后改期，再点击打开新日期。

**验收条件：**

- [ ] 多次改期、系列拆分后旧通知指向同一期。
- [ ] 单期和整个系列删除后保留精简记录，重启及备份恢复仍提示已删除。

**预计修改的生产文件：**

- `lib/features/ledger/domain/commands/update_recurring_bill_command.dart`
- `lib/features/ledger/domain/commands/delete_recurring_bill_command.dart`
- `lib/features/ledger/presentation/notifications/reminder_response_handler.dart`
- `lib/core/data/database/tables.dart`

**预计修改的测试文件：**

- `test/ui/features/ledger/reminder_response_handler_test.dart`
- `test/unit/features/ledger/domain/services/recurring_series_test.dart`

## 47. 来源账单与交易更正可重建

**依赖：** 45、46

**交付：** 入账旧通知始终指向最新交易或已删除状态。

**先写失败测试：** 先测试账单入账、更正两次、重建后旧通知定位最新交易。

**验收条件：**

- [ ] 新交易事件保存来源账单及更正关联。
- [ ] 多次更正后打开最新交易。
- [ ] 删除后提示已删除。
- [ ] 事件重建和备份恢复等价，不重复记账。

**预计修改的生产文件：**

- `lib/features/ledger/domain/events/ledger_events.dart`
- `lib/features/ledger/domain/commands/convert_scheduled_to_posted_command.dart`
- `lib/features/ledger/domain/commands/correct_transaction_command.dart`
- `lib/features/ledger/data/projections/ledger_projector.dart`
- `lib/features/ledger/presentation/notifications/reminder_response_handler.dart`

**预计修改的测试文件：**

- `test/unit/features/ledger/domain/services/projection_rebuild_equivalence_test.dart`
- `test/ui/features/ledger/reminder_response_handler_test.dart`

**预计新建的文件（实施时先核对是否可复用现有模块）：**

- 建议新建 `test/unit/features/ledger/domain/services/source_bill_rebuild_test.dart`：来源账单关联的重建测试。

## 48. 集成验收与解除安全门

**依赖：** 19、20、25、26、27、34、37、40、44、47

**交付：** 多币种、自动入账、恢复及通知形成可发布闭环。

**先写失败测试：** 先写跨币种恢复后仍需确认且无重复记账的端到端失败场景。

**验收条件：**

- [ ] 端到端覆盖混币隔离、长期历史、改期、恢复确认及通知更正。
- [ ] 重建/备份/中断一致。
- [ ] 通过相关测试及 flutter analyze，安全门仅在前置均通过后解除。

**预计修改的生产文件：**

- `lib/main.dart`
- `lib/features/ledger/domain/services/recurring_service.dart`

**预计修改的测试文件：**

- `test/unit/features/ledger/domain/services/ledger_invariants_test.dart`
- `test/unit/features/settings/data/backup_service_test.dart`
- `test/ui/features/ledger/ledger_timeline_test.dart`

