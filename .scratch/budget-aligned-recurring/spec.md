# 面向预算管理的周期系列与物化机制优化

Triage: ready-for-agent

## Problem Statement

当我以预算为核心管理每月开销时，当前的周期系列物化机制会从多个方向破坏预算与账本的可信度：

1. **当月高频固定支出被截断**：每日或每周重复的周期系列（如通勤、午餐、每周采买）最多只物化 3 期未来账单，导致我在当月跟踪预算（Track）和记账实时预算提示中看到的「待入账占用」和「预计剩余」明显偏低，无法判断本月真正可自由支配的额度。
2. **自然月被滚动 90 天切碎，远期规划断档**：物化窗口按“今天起滚动 90 天”截止，常常把第 3 或第 4 个自然月拦腰截断（月末固定账单消失）；而当我翻到未来更远的月份做预算规划（Plan，例如检查半年后的保险、学费、年付订阅高峰）时，周期账单几乎全部缺失，页面只能给出“仅含已物化排期”的降级提示。
3. **跨零点与时区切换导致归属漂移**：周期排期以 UTC 计算与生成去重键，本地凌晨的账单（如 UTC+8 的每月 1 日 00:30）会偏移到上月月底，与按本地自然月统计的预算口径冲突。
4. **过去较远起点与长期休眠存在性能与财务风险**：历史回填没有任何上限，如果我把老合约/分期的起始日期设在 1–2 年前，或者停用应用 1–2 年后重新打开，应用会在冷启动前同步生成数百条逾期账单，甚至在开启自动入账时瞬间扣穿账户余额、污染过去 1–2 年的预算复盘记录。
5. **编辑与批量入账边界隐患**：批量自动入账时每入账一笔就重复全库物化；修改限次规则的排期时总次数未扣减已入账期数；新建周期系列曾默认把首笔直接入账，导致首期失去源账单关联（预算归类为弹性支出而非固定支出）。

## Solution

建立一套以**预算自然月精确性**和**财务安全**为核心的「近端自然月对齐物理物化 + 远端按需预算虚拟投影」双层周期体系，共享同一个本地日历日展开内核：

1. **当月与近月完整可见、无半月截断**：物理物化窗口改为严格对齐本地自然月月末（覆盖当月完整 + 未来 2 个完整自然月），并取消窗口内 `3` 期的条数截断，让每日/每周/每月固定账单在账本列表、预算和提醒中完整呈现；年付等低频规则仍保底生成最近 1 期。
2. **任意未来月预算 100% 精确**：预算模块在跟踪（Track）与规划（Plan）模式下，通过同一展开内核对目标自然月按需推演所有活跃支出周期系列，并与数据库中的已入账、已跳过、单期改价/改期物理记录叠加（Overlay）合并，彻底移除高频与远期降级提示。在规划视图点击远期虚拟账单即可按需落库并单期编辑或跳过。
3. **本地日历日唯一真相**：所有排期推演与逻辑去重键均采用本地日历日，确保「每月 1 号」在任何时区与夏令时下都严格归属本地 1 号所在自然月。
4. **远古起点与长期休眠的双重安全护栏**：
   - 新建或改起点时，若起始日期早于两个月前，保存前给出简洁确认——默认推荐「仅从今天起生成」（保留原日期作为排期与总期数锚点），或由用户主动选择「补齐最近 N 天待入账（默认 30 天、可自定义、仅手动核对）」，绝不提供一键自动扣过去 1–2 年的危险选项。
   - 已有规则在长期休眠重启时，历史回填受「最近 12 个自然月且单系列最多 100 条（最近优先）」硬天花板保护；自动入账对超过 30 天前的逾期或大批量积压触发熔断，自动转为仅手动入账（`Manual-only bill`）由用户显式确认。

## User Stories

1. 作为依赖预算控制日常花销的人，我希望当月内每日、每周、每月的活跃支出周期系列全部计入当月待入账占用（Pending bill exposure）与固定支出基线（Committed spend），以便看到准确的可自由支配额度与超支预警。
2. 作为规划未来预算的人，我希望切换至下月、下季度或明年任意月份（Plan 模式）时，都能看到该月完整的固定支出基线（含月付、季付、年付大额账单），以便提前识别支出高峰并设定合理分类预算。
3. 作为打开账本查看近期安排的人，我希望物理待入账账单完整覆盖当月及未来两个完整自然月，而不会在第 3 个月末尾被滚动 90 天窗口拦腰截断。
4. 作为有年付订阅或半年付保险的人，我希望即便下一次到期日在未来两个自然月之外，账本与提醒仍保底展示最近 1 期未来待入账账单，以便提前知晓并按需调整。
5. 作为在预算规划视图查看远期月份的人，我希望点击某笔尚未物理物化的远期预期账单后，可以直接单期修改金额、改期或跳过该期，且修改立即反映在预算与后续账本中。
6. 作为跨月调整单期账单日期的人，当我把某月月末的待入账账单单期改期到次月初时，我希望原月份的待入账占用立即减少、目标月份的待入账占用立即增加，既不重复计算也不漏算。
7. 作为已经入账或跳过某期账单的人，我希望已入账期次只计入固定实耗而不重复计入待入账占用，已跳过期次从预算待入账占用中剔除且不再复活，并在限次规则中正常计入已消耗次数。
8. 作为查看历史月份预算复盘（Review 模式）的人，我希望过去月份不会凭空展开虚拟待入账账单，只提示确实遗留在数据库中的未处理逾期账单，以便复盘口径干净。
9. 作为在交易表单记账的人，我希望选择支出分类后看到的实时预算余量提示包含当月所有未发生的高频与普通周期账单，且选择「计划」或「重复」模式时按待入账占用而非即时实耗预览影响。
10. 作为新建周期系列的人，我希望保存后首期不会在未开启自动入账时被直接记为实账；仅当开启自动入账且首期已到期时，才通过标准入账流程转为带源账单（Source bill）关联的真实交易，使其在预算中准确归类为固定支出。
11. 作为录老合约或老分期（例如起始日在 1–2 年前、共 36 期）的人，我希望保存前看到清晰确认：默认「仅从今天起生成（推荐）」，保留原始起始日作为每月扣款日和总期数计算锚点，避免过去 1–2 年的账单轰炸账本或双重扣减账户余额。
12. 作为录老规则但想顺手补记近期几期的人，我希望在同一确认弹窗中可以选择「补齐最近 N 天待入账（默认 30 天，允许自行修改天数）」，且补齐的历史期次全部标为仅手动入账待我逐笔核对，绝不静默扣款。
13. 作为把起始日期设在过去两个月以内的新建或修改规则用户，我希望早于今天的期次即使开启了自动入账也会标记为仅手动入账，避免保存瞬间静默扣掉过去多期余额，而当日已到期的自动入账项仍正常自动入账。
14. 作为一两年未打开应用后重新回归的用户，我希望休眠期间的历史逾期回填按最近优先最多补齐最近 12 个自然月且单系列不超过 100 条，确保冷启动迅速完成而不卡死，并在有更早排期被截断时通过会话级横幅得到告知。
15. 作为开启了自动入账但长期未打开应用的用户，我希望超过 30 天前的逾期自动入账项或超出批量阈值的积压账单触发熔断，转为仅手动入账并交由我显式确认，避免打开应用瞬间余额被意外扣穿。
16. 作为生活在非零时区或经历夏令时切换的用户，我希望「每月 1 号 00:30」的周期账单始终按本地日历日生成并归属本地 1 号所在自然月，跨时区出行重跑物化也不会重复生成账单。
17. 作为修改有限次数周期规则排期的人，当我调整开始日期或重复频率时，我希望系统扣除历史上已入账的期数来推进剩余期次，使全生命周期总发生次数与我设定的次数一致而非凭空多出已入账期数。
18. 作为使用本地到期提醒的用户，我希望取消每系列 3 期上限后，高频周期系列能正常排入更多未来提醒，同时系统整体仍严格遵守最多 60 条待发系统通知的平台预算。
19. 作为归档账户的用户，我希望已到期未处理的账单保留为一次性计划待办（且规则字段合法可编辑），未来待入账与活跃周期规则停止生成，同时历史上已入账交易与其源账单的追溯关系保持完整。

## Implementation Decisions

### 架构原则与 ADR 对齐

- 严格遵守 **ADR-0004**（最小金额单位正整数）、**ADR-0005**（独立 UUID 主键 + `(series_id, occurrence_key)` 唯一键 + 二元作用域编辑）与 **ADR-0006**（预算阶梯时间轴与 CRUD 豁免边界）。
- **对 ADR-0005 的补充演进**：`occurrence_key` 的语义明确为**本地日历日 `YYYY-MM-DD`**（一次性计划保持 `'single'`）；远期月份尚未物化的虚拟期次在用户发起单期编辑或跳过时，按 `(series_id, occurrence_key)` **按需落库（Materialize-on-Write）**，再无缝进入既有单期稀疏覆盖或跳过流程。
- **取代既有预算降级约定**：本规格取代先前预算规格中“仅读取 90 天 / `maxKeep = 3` 已物化行并展示降级提示”的临时妥协，删除预算摘要与界面中的 `hasHighFrequencyPending` 与 `isFarFutureMaterializedOnly` 标记及对应免责提示文案。

### 1. 统一本地日历日展开内核（`RecurrenceExpander`）

- 新增纯领域展开模块 `RecurrenceExpander`（无数据库、无时钟副作用），同时服务于**物理物化命令**与**预算虚拟投影**，杜绝双套排期算法漂移。
- **本地日历日推演（Local Civil Date）**：
  - 规则的 `startDate` 与 `endDate` 取其本地 `(year, month, day)` 构造无时区日历锚点交由 RRULE 引擎推进；`BYDAY` 直接按本地星期语义解释，不再做 UTC 星期偏移换算。
  - 每个产出的日历日拼回规则的本地时刻 `(hour, minute, second)` 形成本地 `scheduledDate`，并以本地 `YYYY-MM-DD` 作为 `occurrenceKey`（`planned` 模式固定 `'single'`）。
  - 结束条件与次数语义：`endDate` 按本地日历日闭区间截断；`countLimit` 始终表示该系列全生命周期总次数，展开内核传给 RRULE 的实际有效次数为 `countLimit - completedCountOffset`（`completedCountOffset` 默认 `0`，在 `updateRule` 修改基础排期并前移 `startDate` 时重算为已 `posted` 实例数 `k`）；`posted`、`skipped` 以及未物化的历史已过期次均正常占位消耗次数，不向后顺延补期。
- **单一规则数据源**：周期规则的 `frequency`、`interval`、`endDate`、`countLimit` 与 `weekdays` 以结构化字段为统一输入，规范化生成 `rrule` 文本；展开内核统一通过单一解析入口读取，消除 `BYDAY` 仅靠正则反解析及 `UNTIL` 写死 `T000000Z` 造成的双写偏差。

### 2. 数据库 Schema 演进（CRUD 豁免表升级）

- 升级 `AppDatabase` 的 `schemaVersion`（仅触及 CRUD 豁免表，**不提升 `ledgerProjectionVersion`**，不触发事件溯源视图重建，严守 `onUpgrade` 仅增量演进、绝不删空事件溯源投影表的红线）：
  - **`recurring_series` 新增列 `materialize_from`**（`DateTime`，非空，迁移时以现有行的 `start_date` 回填）：
    - `start_date` 永远作为 RRULE 排期日历锚点与 `count_limit` 起算基准；
    - `materialize_from` 定义允许物化与纳入未来/当月待入账的下界日期（仅 `occurrenceDate >= materialize_from` 的未落库期次才会进入物理物化与预算虚拟投影）。
  - **`recurring_series` 新增列 `completed_count_offset`**（`INTEGER`，非空，默认 `0`）：记录该系列在最近一次排期重置前已经完结（`posted`）的期数。`count_limit` 在数据库与 UI 上始终表示规则总次数；当 `updateRule` 改变基础排期并重置 `start_date` 时，在同一事务内将 `completed_count_offset` 幂等重算为当前已 `posted` 行数 `k`（校验 `count_limit >= k + 1`），展开内核使用 `count_limit - completed_count_offset` 推进剩余期次，彻底杜绝 `k + nextCountLimit` 的次数膨胀及二次编辑重复扣减。
  - **历史 `occurrence_key` 迁至本地日历日**：在 `onUpgrade` 中遍历现有 `scheduled_transactions_view` 的 `repeating` 行，按各行 `scheduled_date.toLocal()` 重算本地 `YYYY-MM-DD` 的 `occurrence_key`（冲突时保留优先级 `posted > failed > scheduled > skipped`）。

### 3. 层一：自然月对齐的物理物化规则

- **物化对象**：所有 `isActive == true` 且关联账户 `!archived && !deleted` 的周期系列。
- **近端前瞻窗口（自然月月末对齐）**：
  - 计算当前本地年月 `nowYm`，物理前瞻终点固定为 **`horizonEnd = endOfMonth(nowYm + 2)`**（即完整覆盖当月 + 下月 + 下下月共 3 个完整自然月，彻底消除滚动 90 天的半月截断）。
  - 在 `(now, horizonEnd]` 内取消 `maxKeep = 3` 限制，按规则完整物化全部缺失期次；保留单系列单次前瞻安全阀（上限 `120` 条，足以完整覆盖 3 个自然月的每日规则而不截断正常使用）。
  - **稀疏规则保底**：若某活跃 `repeating` 系列在 `(now, horizonEnd]` 内尚无任何 `scheduled` 实例，继续向后探测至规则终止条件或年份上限，保底物化最近 `1` 期（`minKeep = 1`）。
  - `planned` 系列保持原有行为：若 `'single'` 尚不存在则直接幂等插入。
- **休眠重启历史回填硬上限（Phase 0 Safety Cap）**：
  - 对 `effectiveLowerBound = max(series.materializeFrom, startOfMonth(nowYm - 11))` 至 `now` 之间（即**最多回溯最近 12 个完整自然月**）的历史缺失期次进行回填。
  - 单系列历史未物化回填设硬天花板 **最多 100 条，按距离 `now` 最近优先截取**（即先推演至 `now`，若超过 100 条则仅保留最近 100 条，丢弃更早的远古期次）。
  - 物化命令返回结构化结果：包含需用户手动核对的新增逾期条数，以及是否存在因超 12 个月 / 100 条上限被跳过的远古期次标志，供会话级 `OverdueMaterializationBanner` 向用户透明提示。
- **批量事务与性能优化**：
  - 每个系列的物理插入合并为**单次数据库事务 + 批量 `insertOrIgnore`**（事务内校验一次系列活跃与账户未归档/未删除），替代逐条开事务。
  - `RecurringService` 的批量自动入账（`catchUpAutoPosted` / `settleCurrencyBacklog`）在处理单条入账时**不再内联触发全库 `materialize()`**，而是在整批循环结束后统一执行 **1 次** `materialize()`，消除 $O(N^2)$ 级放大与通知风暴。
  - `RecurringRepository` 读路径直接复用 SQL `JOIN` 产出的系列、账户与分类字段，消除按系列逐条查询的 N+1 开销；并区分“仅活跃/未结清/按月范围”查询与全量历史查询。

### 4. 新建/改起点设在过去与自动入账熔断护栏

- **新建或 `updateRule` 改起点设在过去**：
  - 保持已修复的创建语义：无论 `planned` 还是 `repeating`，保存时不直接调用即时记账命令，统一创建周期系列，首期由物化与自动入账规则决定归宿（保证入账后必携带 `sourceScheduledBillId`）。
  - **远过去判定阈值（早于两个月前）**：当新建 `repeating` 系列或 `updateRule` 变更基础排期后，目标 `startDate` 严格早于「当前本地日期减去 2 个自然月」时，在保存前弹出简洁确认对话框，提供且仅提供两个选项（绝不提供一键自动扣过去 1–2 年）：
    1. **「仅从今天起生成（推荐）」**：保留用户选择的 `startDate` 作为排期与 `countLimit` 锚点，将 `materializeFrom` 设为**今日零点（`startOfDay(now)`）**，跳过今天之前的全部历史期次。
    2. **「补齐最近 N 天待入账（手动核对）」**：内含可编辑数字输入，默认 `N = 30`（允许用户输入 `1..365` 整数，且仍受单系列 100 条硬上限约束）；确认后将 `materializeFrom` 设为 `max(startDate, startOfDay(now - N days))`，并且将本次物化出的所有严格早于 `startOfDay(now)` 的历史期次统一标记为 **`manualOnly = true`**，留待用户在待入账列表手动「记入」或「跳过」。
    - 用户取消弹窗则中止保存，不写任何数据。
  - **近过去（两个月以内且早于今天）**：不弹远过去确认框，`materializeFrom` 等于 `startDate`；但新建或改起点落库的所有严格早于 `startOfDay(now)` 的历史期次，即使系列开启 `autoPost` 也标记为 `manualOnly = true`，仅当日已到期（`startOfDay(now) <= effectiveDate <= now`）的期次允许按 `autoPost` 规则即时自动入账。
- **休眠重启自动入账熔断（Auto-Post Circuit Breaker）**：
  - `catchUpAutoPosted` 筛选当前币种待自动入账实例（`isActive && autoPost && !manualOnly && status == scheduled && !account.archived && effectiveDate <= now`）后，执行两道熔断检查：
    1. **单笔时效熔断**：任何 `effectiveDate < now - 30 days`（超过 30 天前）的逾期实例，禁止静默自动入账，直接标记为 `manualOnly = true`。
    2. **批量积压熔断**：剩余 30 天内的待自动入账实例总数若超过批量熔断阈值（`> 10` 笔），本次冷启动同样不静默扣款，将其全部标记为 `manualOnly = true`（或交给显式积压确认弹窗由用户选择「全部入账 / 保留待手动核对」），并在 UI 给出清晰提示。
  - 正常场景（30 天内且 `<= 10` 笔）维持既有首帧后非阻塞自动入账与确定性 `autopost-<instanceId>` 幂等键。

### 5. 层二：预算按需虚拟投影（Overlay 模式）与按需落库

- **预算待入账查询改造（`BudgetDao` / `BudgetRepository` / `BudgetCalculator`）**：
  - **Review 模式（`targetYm < nowYm`）**：不执行虚拟展开；仅汇总物理表中有效日期落在 `targetYm` 且状态为 `scheduled / failed` 的支出账单，用于 `hasLeftoverPendingInReview` 提示。
  - **Track / Plan 模式（`targetYm >= nowYm`）**：
    1. 查询满足条件（`currencyCode == targetCurrency`、`includeInTotals == true`、`!deleted`、`!archived`、`type == expense`、`isActive == true`）的所有支出周期系列，以及这些系列与 `targetYm` 相关的物理实例行（包括逻辑 `occurrenceKey` 落在 `targetYm` 的全部状态行，以及 `effectiveDate` 落在 `targetYm` 的全部 `scheduled / failed` 支出物理行——涵盖非活跃系列或归档账户拆出的遗留逾期计划单）。
    2. 对每个活跃支出系列，调用 `RecurrenceExpander` 计算落在 `targetYm` 且 `scheduledDate >= series.materializeFrom` 的全部逻辑发生项，与物理行按 `(seriesId, occurrenceKey)` 叠加合并：
       - 命中物理行且 `status == posted` → 忽略（已计入 `committedActualMinor`，严防重复计算）。
       - 命中物理行且 `status == skipped` → 忽略（用户已跳过）。
       - 命中物理行且 `status ∈ {scheduled, failed}` → 若 `dateOverride` 将其移至其他月份，则不在 `targetYm` 计入；否则采用物理行的 `amountOverrideMinor ?? series.amountMinor` 与 `memoOverride ?? series.description`。
       - 未命中物理行 → 生成**虚拟待入账项（Virtual Pending）**，携带 `(seriesId, occurrenceKey, scheduledDate, templateAmount, templateDescription, isVirtual: true)` 计入 `targetYm` 的 `pendingMinor` 与贡献列表。
    3. 并入物理表中因 `dateOverride` 从其他月份挪入 `targetYm` 的 `scheduled / failed` 行（以及遗留的非活跃/归档账户一次性计划待办），实现跨月改期总额守恒。
  - **记账表单实时预算提示（`watchCategoryBudgetHint`）**：同步复用上述 Overlay 逻辑计算目标分类在目标月份的 `pendingMinor`，使当月高频与远期月份的记账预算余量提示同样 100% 精确。
- **远期虚拟账单按需落库（Materialize-on-Write）**：
  - `RecurringService` 新增幂等方法（例如 `ensureMaterialized(seriesId, occurrenceKey)`）：在事务内校验系列活跃且账户有效后，按 `(seriesId, occurrenceKey)` `insertOrIgnore` 一条标准 `scheduled` 物理行并返回其 UUID。
  - 预算详情页（L3 分类详情的贡献流水列表）展示远期虚拟待入账项时，点击进入待入账操作抽屉或编辑表单前先完成按需落库，后续单期改价、改期、跳过与规则更新完全复用既有 UUID 写路径与二元作用域交互，无需新增表单或状态机。

### 6. 写入原子性与生命周期一致性修正

- **单事务更新与停用**：将 `UpdateRecurringBillCommand` 的模板更新与清理未入账/已跳过行、以及 `DeleteRecurringBillCommand` 的 `isActive = false` 与清理非 `posted` 行分别包裹在单一数据库事务内，防止半成品状态。
- **单期改期碰撞拦截**：`UpdateRecurringBillCommand(thisOnly)` 修改 `dateOverride` 时，校验同系列是否已存在其他非 `skipped` 实例落在同一本地日历日，若冲突则拒绝并返回明确错误码（`scheduledDateTaken`），避免同系列同日出现双账单。
- **账户归档数据完整性**：账户归档保留已到期逾期账单为一次性 `planned` 待办时，只设置 `startDate == endDate`、保持 `countLimit == null`（遵守 `endDate` 与 `countLimit` 互斥不变量）；原周期系列置为 `isActive = false` 并仅删除未入账与已跳过实例，**保留历史 `posted` 实例行**，避免 `sourceScheduledBillId` 断链（账户恢复时不会重新激活 `isActive == false` 的系列，与 `CONTEXT.md` 语义一致）。

### 7. 本地化与文案要求

- 新增远过去保存确认弹窗、可自定义补齐天数输入与超长历史截断提示文案，同步覆盖 `en`、`zh`、`zh_Hans`、`zh_Hant` 四个 ARB 文件（`zh` 与 `zh_Hans` 保持同步），并移除不再使用的「仅含已物化排期」降级提示渲染。

## Testing Decisions

### 测试原则

- 仅断言外部可观测行为（数据库写入的待入账集合、事件流中的 `TransactionRecorded` 与 `sourceScheduledBillId`、预算服务的月度汇总与表单提示输出、UI 可见文案与交互结果），不绑定内部私有实现或 mock 命令/DAO/展开器。

### 测试接缝（已与用户确认）

1. **主接缝（单一核心集成接缝）**：扩展现有 `LedgerServiceHarness`（共享真实内存 `FakeAppDatabase` 与可注入 `FixedClock`），接入真实的 `BudgetService`，让 `RecurringService`、`LedgerService`、`AccountService`、`CategoryService` 与 `BudgetService` 在同一份内存数据库上端到端联调。
   - **先例参考**：现有周期物化服务测试与预算服务测试均采用同一内存数据库与固定时钟模式。
   - **核心验收用例**：
     - **自然月对齐与高频完整物化**：固定时钟为某月 26 日（如 11 月 26 日），创建 `DAILY`、`WEEKLY`、`MONTHLY`、`YEARLY` 周期系列，断言物理实例完整覆盖至 `nowYm + 2` 月末（2 月 28/29 日，无半月截断且不再被 `maxKeep = 3` 截断）；`YEARLY` 保底 1 期；重复调用 `materialize()` 完全幂等。
     - **本地日历日与跨时区一致性**：创建本地 1 日 00:30（UTC 为上月月底）的月度规则，断言 `occurrenceKey` 与归属自然月均为本地 1 日所在月；切换不同时区重跑物化零重复。
     - **预算双层 Overlay 精确性**：
       - **Track 当月**：`DAILY` 与 `WEEKLY` 支出规则在当月的 `committedBaselineMinor`、`pendingMinor`、`projectedRemainingMinor` 完整计入当月所有未发生期次；`watchTransactionBudgetHint` 同步准确。
       - **Plan 远期月（如 M+6 与次年同月）**：超出物理窗口的月付、年付及有限次分期规则在 `BudgetService.watchMonthBudget` 中准确产出预期 `pendingMinor` 与贡献列表；已达到 `countLimit` 或超过 `endDate` 的月份归零。
       - **叠加守恒**：当月某期入账后从 `pendingMinor` 转移到 `committedActualMinor` 且总额不变；某期跳过后从 `pendingMinor` 扣除；将某月月末期次单期 `dateOverride` 改期到次月后，原月减少、次月增加；`Review` 历史月不生成虚拟待入账。
     - **远期虚拟账单按需落库**：对 M+6 的虚拟发生项调用按需落库并执行 `thisOnly` 改价或跳过，断言物理表幂等落入单行且 `BudgetService` 立即反映新金额或剔除该期。
     - **远过去创建与休眠熔断**：
       - 新建 `startDate` 为 2 年前的 36 期月度分期，选择「仅从今天起生成」→ `materializeFrom = today`，历史 24 期不物化，未来剩余 12 期在预算 Plan 中完整准确、第 13 期起为 0；选择「补齐最近 30 天」→ 仅补齐近 30 天内期次且全标 `manualOnly = true`，即便开启 `autoPost` 也不静默入账。
       - 休眠 2 年重启：`DAILY` 系列历史回填严格封顶 100 条（最近 100 天），`MONTHLY` 封顶 12 个自然月；开启 `autoPost` 且逾期超 30 天或批量超 10 笔时触发熔断转为 `manualOnly`，余额不被静默扣除。
       - 批量自动入账（如 5 笔 30 天内合规账单）断言每笔带 `sourceScheduledBillId`、归类为固定支出，且物化只做收尾单次补齐。
     - **编辑与归档不变量**：限次规则已入账 `k` 期后通过 `updateRule` 修改排期，断言总发生次数（历史已入账 + 新规则剩余）严格等于目标 `countLimit`；单期改期撞同日返回 `scheduledDateTaken`；归档账户后逾期单转 `planned` 可正常编辑、原 `posted` 行保留且恢复账户不复活原系列。

2. **表层补充接缝（UI 与平台提醒）**：
   - **预算与表单组件测试**：沿用现有 `BudgetScreen`、`BudgetCategoryDetailScreen` 与 `TransactionFormScreen` 组件测试，验证：
     - 预算页与分类详情不再出现高频/远期「仅含已物化排期」降级提示；
     - 在远期 Plan 月份点击虚拟待入账贡献项能正常打开单期编辑/跳过流程；
     - 交易表单将 `repeating` 起点设在两个月前并点击保存时弹出两选项确认框，支持修改补齐天数，且无「自动补扣全部历史」选项。
   - **提醒调度测试**：沿用现有 `RecurringReminders` 单元测试，验证高频系列在取消 `maxKeep = 3` 后仍按最近到期优先排序并严守 60 条系统待发通知上限。

## Out of Scope

- 不把 `recurring_series` 或 `scheduled_transactions_view` 纳入事件溯源（维持 ADR-0005 / ADR-0006 的 CRUD 豁免边界）。
- 不支持转账类（`transfer`）周期系列或跨币种周期系列（维持 ADR-0002 单账户约束）。
- 不在预算模块新增「收入预算」「跨月结余滚存（Rollover）」或「年度总览新页面」；本规格聚焦让既有月度 Track / Plan / Review 预算与记账提示在任意周期频率与任意未来月下精准可信。
- 不支持在没有触发打开应用的情况下通过后台守护进程强行自动入账（继续遵循启动/前台驱动的自动入账与本地通知提醒模型）。
- 不做 Google Calendar 式历史子系列拆分（坚持 ADR-0005 的二元作用域模型）。

## Further Notes

- **首期默认入账缺陷已先期修复**：表单「重复」模式不再先写即时交易再从 `nextOccurrence` 启动规则，而是直接从所选 `startDate` 创建周期系列，已为本规格的 `materializeFrom`、预算固定支出归类与远过去确认流程扫清前置障碍。
- **文档同步提醒**：本规格落地后需同步更新仓库根 `AGENTS.md` 中严重滞后的「周期与预约交易」章节，以及补充或修订 ADR-0005（记录本地日历日 `occurrence_key`、`materialize_from` 与按需落库约定）。
