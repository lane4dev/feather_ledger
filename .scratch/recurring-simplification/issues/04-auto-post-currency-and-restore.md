# 极简自动入账、多币种静默切回与恢复水线机制

Type: grilling
Label: wayfinder:grilling
Status: resolved
Triage: ready-for-human
Blocked by: 01

## Question

彻底废除 3 套全局开关、毫秒级资格历史、`auto_post_eligible` 永久锁与多批次确认状态机后，常规自动入账、非当前币种静默切回提醒以及备份恢复防误扣水线应如何以最简机制闭环？

## Context

Chart 阶段已锁定：
- 不设自动入账全局开关，每条周期规则自带 `autoPost` 开关（并在新建时记住用户上次选择）。
- **备份恢复**：使用恢复点水线保护，早于恢复点到期的账单不再自动入账，降级为普通待入账等用户手动操作；恢复后新到期的才照常自动入账。
- **多币种联动**：非当前币种下完全静默（不自动入账、不弹窗、不发通知），直到用户切回该币种，弹出提醒交给用户手动操作和自动补记。

本票需要把以下关键交互与状态收敛到零状态机的极简实现：
1. **「切回币种后弹出提醒交给用户手动操作和自动补记」的精确机制**：
   - 切回某一币种时，若该币种在静默期间有到期的 `autoPost` 订阅和普通手动到期账单：
     - 哪些交由用户通过弹窗一键确认/跳过，哪些直接自动补记？还是弹窗里按币种一次性列出切回期间积压的到期账单，让用户选「全部记入 / 逐条处理」？
     - 如何仅靠一条极简标记（例如不再使用毫秒级 `currencyActiveSince` 和复杂多批次表，或仅靠切换前后的待处理状态 / 启动与切币种统一触发）避免用户困惑？
2. **恢复备份水线的实现形态**：
   - 恢复 `.flbackup` 时，是在应用恢复的同一事务里直接把「`scheduledAt <= restoredAt` 且尚未入账的 `autoPost` 实例」打上一次性的 `manualOnly` / `autoPostBypassed` 标记（还是存一个全局 `restoredAt` 水线时间戳），以及恢复后首次进入账本是否展示一条轻量的横幅/提示提醒用户核对旧备份期间的待入账账单？
3. **常规启动自动入账的可见性与错误处理**：
   - 当前币种下启动时，符合条件的过期 `autoPost` 实例直接静默记入；若当次成功入账了 N 笔，是否用轻量 Toast/SnackBar 提示「已自动记入 N 笔订阅」，失败的笔数如何就地保留在待入账列表中并标注失败原因？
   - 取消复杂的进度条弹窗与多批次统计表后，大量补记是否仍做简单异步防卡顿即可？

## Comments

- 用户确认（Round 1）：`Q1: a; Q2: a; Q3: 1 选 (a), 2 选 (a), 3 确认; Q4: a`。

## Answer

1. **备份恢复水线（`.flbackup` 跨全币种防误扣）**：
   - 在 `ScheduledTransactionsView` 上增加布尔列 `manualOnly: bool`（默认 `false`），彻底废除 `RestoreConfirmationBatches` 表、`enabledSince` / `currencyActiveSince` / `lastSeenWallClock` 毫秒级资格水线、3 个本地自动入账开关以及设置页批次确认弹窗。
   - **承重启动顺序**：`applyPendingRestore` → `rebuild (if stale)` → `materialize()` → **`markPreRestoreManualOnly()`（检测到 `readRestoreBarrier` 时执行）** → `catchUpAutoPosted()`。
   - `markPreRestoreManualOnly()` **面向全币种**将库内所有 `status == scheduled && effectiveDate <= restoreTime` 的实例一次性标为 `manualOnly = true`（必须在 `materialize()` 之后执行，以兜住导出日至恢复日之间刚物化出的其他币种历史到期账单，确保日后切币种时不会误触发自动入账或进入一键补记弹窗）。
   - 若用户主动将某笔 `manualOnly == true` 的账单单期改期到未来（`effectiveDate > today`），清除 `manualOnly` 恢复自动资格。
   - 恢复后若当前币种存在被拦截的恢复前到期实例，账本页顶部展示一条会话级可关闭 Banner 提示核对。
2. **多币种静默与切回提醒（消灭 `currencyActiveSince`）**：
   - 仅当账单所属账户币种等于当前显示币种（`billCurrency == currentCurrency`）时，才执行自动入账与发送提醒；非当前币种完全静默。
   - 当用户将当前显示币种切换为 `C` 时，查询 `currency == C && status == scheduled && effectiveDate <= now && !manualOnly && series.autoPost == true` 的积压实例：
     - 仅在存在积压项时弹出轻量确认弹窗提供二选一：**「一键全部自动补记」**（立即转正为交易）或**「转为待手动处理」**（标为 `manualOnly = true`，留在账本待入账区逐条处理；切回后新到期的未来期次照常自动入账）。
     - 普通 `autoPost == false` 的手动到期账单与 `manualOnly == true` 的恢复前旧账单不进弹窗，直接呈现在待入账列表。
3. **当前币种常规启动自动入账、UI 提示与失败处理**：
   - 当前币种下，满足 `series.isActive && series.autoPost && !manualOnly && status == scheduled && effectiveDate <= now`（且账户未归档）的实例（包含 Ticket 02 在最近 30 天内新补齐的最多 3 期过期 `autoPost` 实例），在首帧后异步分片执行自动入账（每 20 笔 `Future.delayed(Duration.zero)` 让出事件循环），保留冷启动通知「跳过」优先于自动入账的 deferral 机制，并废除 `AutomaticPostingBatches` / `AutomaticPostingBatchMembers`。
   - 当次启动成功自动入账 `N >= 1` 笔时，弹出轻量 SnackBar 提示「已自动记入 N 笔订阅」。
   - 单笔入账失败时保留 `ScheduledTransactionStatus.failed` 状态（不阻塞同批其余实例），留在待入账列表置顶警示并允许用户点开 `PendingBillSheet` 重试「记入」或「跳过本期」。
4. **规则开关由关闭切为开启（`autoPost: false -> true`）**：
   - 在「更新规则」中开启 `autoPost` 时，仅对保存时刻之后新到期的未来期次生效；当时已经过期的既有 `scheduled` 实例自动标为 `manualOnly = true`，避免点保存瞬间误扣旧待入账。
