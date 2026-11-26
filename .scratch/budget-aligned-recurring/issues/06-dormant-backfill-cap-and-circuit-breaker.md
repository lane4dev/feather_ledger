# 06: 休眠重启历史回填上限与自动入账熔断

Triage: ready-for-agent
Status: resolved

**Blocked by:** 01 · 本地日历日展开内核、Schema 升级与自然月物理物化

关联规格见 [spec.md](../spec.md)。

**What to build:** 为长期未打开应用的休眠重启场景加上两道硬护栏——物理历史回填封顶「最近 12 个自然月且单系列最多 100 条（最近优先）」并在截断时通过会话级横幅透明提示；自动入账对超过 30 天前的逾期或大批量积压（`> 10` 笔）触发熔断，转为 `manualOnly` 交由用户显式确认；同时消除批量自动入账每条重复物化的性能放大。

## 验收标准

- [x] 物理物化 Phase 0 对历史回填实施硬天花板：起始下界取 `max(series.materializeFrom, startOfMonth(nowYm - 11))`（最多回溯最近 12 个完整自然月），且单系列单次历史未物化回填最多保留距离 `now` 最近的 **100 条**（丢弃更早远古期次）；同时保证休眠 40 天的 `DAILY` 系列（41 条）依然完整补齐。
- [x] 物化结果暴露「新增需手动核对逾期数」与「是否发生超限截断」信息；当发生截断时，账本顶部会话级 `OverdueMaterializationBanner` 向用户透明说明有更早的长期未处理排期已自动跳过（文案覆盖 `en`、`zh`、`zh_Hans`、`zh_Hant` 并运行 `flutter gen-l10n`）。
- [x] 启动 `catchUpAutoPosted` 实施两道自动入账熔断：
  1. 超过 30 天前（`effectiveDate < now - 30 days`）的逾期自动入账实例禁止静默入账，直接标记为 `manualOnly = true`；
  2. 剩余 30 天内的待自动入账实例总数超过 10 笔时触发批量熔断，不静默扣款，全部标记为 `manualOnly = true`（或交给显式积压确认流由用户决定），并向用户给出明确提示。
- [x] `catchUpAutoPosted` 与 `settleCurrencyBacklog` 批量处理自动入账时，单条入账不再内联触发全库 `materialize()`，改为整批结束后统一执行 **1 次** `materialize()`，消除 $O(N^2)$ 物化与通知重排放大。
- [x] 通过 `LedgerServiceHarness` 端到端验证：休眠 2 年的 `DAILY` 系列回填严格封顶 100 条（最近 100 天）且标记发生截断，`MONTHLY` 封顶 12 条；超 30 天逾期或 15 笔积压触发自动入账熔断转为 `manualOnly`、账户余额不被扣减；30 天内 5 笔合规自动入账正常转正并全部携带 `sourceScheduledBillId`。
- [x] `flutter analyze` 无新增错误或警告，全部相关单测与组件测试通过。
