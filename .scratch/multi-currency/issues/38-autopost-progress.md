# 38: 启动补记分批和进度

Type: task
Triage: ready-for-agent
Status: resolved

Blocked by: 31、33

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
## 共同约束

- 先在已确认的公开测试接缝编写本票首个行为的失败测试，运行并确认失败；再以最小实现通过，逐条重复，不先批量编写所有测试。接缝为账本、账户、周期及备份 service 和真实测试数据库；界面与通知行为使用 widget 测试及现有通知平台适配边界。
- 预计文件按当前代码列出；实施前核对并优先复用现有模块。需要界面文案时同步 en、zh、zh_Hans、zh_Hant 四个 ARB 并运行生成器；Drift 和 Riverpod 生成文件由生成器更新。
- 任务 28 的自动入账保护在任务 48 验收前保持，测试可通过受控测试配置验证各阶段行为；任何阶段不得删除或重置现有数据。完成时运行适用测试及静态分析。
- 完整产品规则与范围以[多币种规格](../spec.md)为准；涉及尚未验证的期次身份、资格历史及恢复算法时，先用有界原型与行为测试验证，不能把候选实现视为既定事实。

## Answer

补记从首帧前移到首帧后：`main.dart` 用 `WidgetsBinding.instance.addPostFrameCallback` 在 `runApp` 之后调度 `catchUpAutoPosted()`（`unawaited` + `catchError` 兜底），因此启动不再等待大批账单结算（US46）。冷启动通知响应仍优先——`reminders.hasPendingResponses` 时走 `deferAutoPostCatchUp()`。

`catchUpAutoPosted` 重写为有界批次：

- 启动截点固定：`now = DateTime.now()` 只取一次，`due = instances.where(!date.isAfter(now))`，前台期间新到期的账单等下次启动。
- 每 `_batchChunk = 8` 笔 `await Future<void>.delayed(Duration.zero)` 让出事件循环，首帧与账本 UI 持续刷新。
- 每笔结果经 `_settleMember` 落成 `AutomaticPostingMemberResult` 并 `setAutomaticPostingMemberResult(batchId, id, result)` 持久化，供进度显示（成功/失败/用户已处理/转手动）。

验收：'a catch-up creates a fixed-cutoff batch and posts its due bills' 验证批次截点 ≤ 现在、账单只贴一次、成员结果为 succeeded。
