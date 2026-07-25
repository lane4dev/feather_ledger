# 期初余额与余额更正：主流产品模式调研

**调研日期：** 2026-09-22  
**目的：** 为 Feather Ledger 的「创建账户时非零余额会生成一笔使用系统分类
“余额更正”的普通收支交易」这一体验问题，梳理可验证的上游做法。本文只记录一手
文档与上游源码；没有证据的 UI 细节会明确标注，不能据此推断。

## 可验证的产品做法

| 产品 | 创建账户的期初余额 | 后续余额不符时 | 在账本中的可见性 / 可编辑性 | 与普通分类的关系 |
| --- | --- | --- | --- | --- |
| [Actual Budget](https://actualbudget.org/) | 创建账户时填余额，会产生 **Starting Balance** 交易；官方指引允许用户改该交易日期。源码文档给它独立的 `starting_balance_flag`。 | 官方对账工具展示账面与银行的差额并以 cleared/reconciled 状态完成对账；本次查到的资料未确认它是否自动生成一笔 adjustment。 | **可见、可编辑**：官方指引明确让用户编辑 starting-balance transaction 的日期；信用卡迁移指引还让用户改它的分类。 | 不是仅凭名称辨识：有独立 flag。它在预算产品中可参与分类（例如旧信用卡债务），这是其 envelope-budget 语义，不应直接照搬到收支报表。 |
| [YNAB](https://www.ynab.com/) | **Starting Balance** 是账户 register 中日期最早的一笔交易；官方让用户直接在 register 中双击/点按后改金额和日期。 | 强制推荐经 reconciliation：确认后自动写入一笔命名为 **Reconciliation Balance Adjustment** 的交易；删除该实际交易即可撤销这次调整。 | **可见、可选择、可删除**。它把例外交易显式命名，而不是让用户面对不可见的分类。 | 已核实的文档没有宣称它以用户可选的“余额更正”普通分类来建模；可确认的是交易目的在 UI 上清晰可见。 |
| [GnuCash](https://www.gnucash.org/) | 建账对话框有仅在新账户创建时可见的 Opening Balance 页；默认从标准的 **Equity:Opening Balances** 账户转入，也可改选另一个转出账户。 | 这是完整复式账本：后续修正应是有来源/去向的普通双边分录；本次未找到一个简化的“对账差额自动交易”说明。 | Opening balance 作为账户 register 内的普通两账户交易存在；官方手册说明在合法范围内可以在 register 修正/补充。 | 采用**权益账户**，不是收入或支出分类。因此期初资产/负债不会污染当期损益/现金流报表。该账户是标准账户，不靠本地化显示名作为身份。 |
| [Firefly III](https://www.firefly-iii.org/) | 建账户时 `AccountFactory` 会调用 `storeOpeningBalance`；配置明确为 `OPENING_BALANCE` 交易类型配对 `INITIAL_BALANCE` 账户类型，而不是普通 income/expense。 | 有另一种独立的 `RECONCILIATION` 交易类型/账户类型配对；这说明项目在数据层明确区分期初与对账。未在本次文档证据中确认具体前端编辑限制。 | 可由官方源码确认它们是特殊交易类型及对方账户类型；是否每个前端版本都可在通用编辑器修改，**未确认**。 | 独立 account type / transaction type，避免把系统含义塞进一条可与用户重名的分类文字。 |
| [ezBookkeeping](https://ezbookkeeping.mayswind.net/) | 只允许在**新建账户**时填写 initial balance。 | 不允许直接改账户余额；要记收入/支出，或在 Reconciliation Statement 的 **Update Closing Balance** 中由系统算出差额并预填“新交易”页面。 | 文档确认后续调整会落回新交易页；对 initial-balance 生成交易的详情/编辑限制，**未确认**。 | 对轻量个人记账是实现简单的路径，但其官方说明确实会把后续差额视作收入或支出；它不解决“起始余额是否应计入本月收支”的报表语义问题。 |

## 一手证据

### Actual Budget

- [Starting Fresh](https://actualbudget.org/docs/getting-started/starting-fresh/)：创建账户时设定
  balance；若起始日早于当前日，应“edit the date on the starting balance transaction”。这直接
  证明起始余额是一笔可见交易，而不是只存在于账户元数据。
- [上游规则模板数据字段](https://github.com/actualbudget/actual/blob/master/packages/docs/docs/experimental/rule-templating.md#L222-L242)：
  `starting_balance_flag` 的说明是“Set if the transaction is a starting balance transaction”。
  因而业务身份不是显示名或分类名。
- [Carrying debt 指引](https://actualbudget.org/docs/budgeting/credit-cards/carrying-debt/)：要求把
  starting-balance 的 category 改成 `Bank Card Debt`。这证明至少该场景的起始余额可进入交易编辑
  与分类语义；它是 Actual 的预算规则，不等于建议 Feather 把期初余额计为收入。
- [Reconciliation](https://actualbudget.org/docs/accounts/reconciliation/)：对账以银行余额与
  cleared total 的差额为核心，并在账户账本里完成。资料没有直接说明“自动写差额交易”，故不作此主张。

### YNAB

- [The Starting Balance](https://support.ynab.com/en_us/the-starting-balance-an-overview-H1uozOfJs?mobile-help=true)：
  Starting Balance 是 register 中日期最早的交易；官方说明可在 account register 直接编辑日期和金额。
- [Balance Adjustments](https://support.ynab.com/en_us/balance-adjustments-a-guide-rko4OwILs)：
  对账完成的 `Create Adjustment & Finish` 自动创建 `Reconciliation Balance Adjustment`；删除这笔实际
  adjustment transaction 可以撤销。该流程保留 reconciliation 边界，而不是静默改余额。

### GnuCash

- [创建账户手册 §5.4](https://wiki.gnucash.org/docs/C/gnucash-manual/acct-create.html)：Opening Balance
  页只在创建账户时出现，默认“Use Opening Balances Equity account”，也可以选择另一个转出账户。
- [交易指南 §2.9](https://wiki.gnucash.org/docs/C/gnucash-guide/chapter_txns.html)：期初余额是
  Assets:Checking 与 Equity:Opening Balances 的普通两账户交易。
- [账户类型手册](https://wiki.gnucash.org/docs/C/gnucash-manual/acct-types.html)：Equity 用来保存首次
  使用或新会计期间的 opening balances。
- [德语创建/编辑账户手册 §5.5.2](https://wiki.gnucash.org/docs/de/gnucash-manual/acct-create-or-edit.html)：
  明确说该起始余额会作为普通交易写进 register，且在法律允许范围内可修正或补录。

### Firefly III

- [AccountFactory 源码 213–219、306–318 行](https://github.com/firefly-iii/firefly-iii/blob/main/app/Factory/AccountFactory.php#L213-L219)：
  创建账户后调用 `storeOpeningBalance`；该方法仅对允许的账户类型处理 opening-balance 数据。
- [交易/账户类型配置](https://github.com/firefly-iii/firefly-iii/blob/main/config/firefly.php)：
  `OPENING_BALANCE` 显式映射 `INITIAL_BALANCE`，`RECONCILIATION` 显式映射 `RECONCILIATION`；两者与
  withdrawal/deposit/transfer 分开。这是特殊会计意图的源码证据，而非 UI 推断。

### ezBookkeeping

- [Basic Usage](https://ezbookkeeping.mayswind.net/basic_usage/) 与
  [FAQ：How to modify an account balance](https://ezbookkeeping.mayswind.net/faq/)：initial balance
  只在创建账户时设置；后续必须记收入/支出，或在 Reconciliation Statement 的 Update Closing Balance
  由系统计算差额、预填一笔新交易。

## 归纳：适合 Feather Ledger 的最佳实践

这不是“要不要留下可追溯交易”的二选一。较好的最小产品模型是：**可见的专用业务目的，稳定的系统身份，
受约束的编辑入口，以及不会误导日常收支的报表语义**。

1. **将目的从 Category 中拿出来。** 给交易/事件增加稳定且非本地化的 `origin` 或
   `purpose`，至少有 `userEntry`、`openingBalance`、`reconciliationAdjustment`。UI 文案可以是
   “期初余额”/“余额已调整”，但判断逻辑绝不能比较“余额更正”这个显示名。Actual 的
   `starting_balance_flag`、Firefly 的 transaction type、GnuCash 的 equity 对方账户均属于这一类设计。

2. **期初余额不应是本月经营收入或支出。** 新建账户时的数额应改变余额并留审计记录，但在默认
   “本月收入 / 支出 / 分类占比”中排除；若今后引入完整复式模型，可将其对方落到不可手工过账的
   `Opening Balances` equity/system account。否则用户在 9 月开始使用应用时会得到虚假的“9 月收入”。

3. **让它在账本与详情中可见，但不要丢进普通分类选择器。** 账本行显示系统图标/徽章和
   “期初余额（创建账户）”或“对账调整”，详情解释“这笔记录用于使账户余额等于…”。点击后打开
   专用编辑器：期初余额可改日期、金额、说明；对账调整由“更新余额/对账”流程创建，可查看目标余额、
   差额与原因。这样既比隐藏分类清楚，也不会让用户把它误当作日常消费分类。

4. **后续差异走对账/调整流程，而不是“编辑账户余额”。** 输入目标结余，由系统显示 `目标 − 当前`
   的差额、日期和说明，确认后形成 `reconciliationAdjustment`。YNAB、Actual、ezBookkeeping 都将
   对账作为发现差异的入口；ezBookkeeping 的“预填一笔新交易”是可接受的简化版，但 Feather 应保留
   专用 purpose，避免污染报表。

5. **系统对象只按 immutable ID / systemCode 区分。** 现有 `CategoryConstants.reversal*Id` /
   `systemCode` 的方向正确；不要用名称去重，也不要让本地化文案承担唯一性。普通分类选择器可继续
   隐藏 system category；即便用户创建同名“余额更正”，它仍是 `userEntry`，系统行则按 purpose
   渲染为“期初余额/对账调整”。为降低困惑，可在创建相同显示名时温和提示“这是普通自定义分类”，
   不建议仅因名称而硬拦截（多语言、用户真实意图和已有数据都使硬保留名脆弱）。

6. **事件溯源中的改动仍走冲正 + 重记。** 不要直接改投影余额；编辑专用记录时以原交易的 purpose
   重建相同 purpose 的 replacement，并保留 `TransactionReversed(correction)` 审计链。这样与当前
   Feather 的不可变 event store 自然兼容。

## 对当前 Feather Ledger 的直接含义

按仓库 `AGENTS.md` 的现状说明，`AccountService.createAccount` 对非零期初余额和
`adjustAccountBalance` 都走同一个系统分类、普通 `TransactionRecorded` 路径；起始余额还会进入当月
收入/支出。因此目前的痛点不只是“编辑页选不到分类”，也是**交易意图丢失**与**报表口径失真**。

建议产品层优先把“期初余额”与“余额更正/对账调整”拆开呈现和统计；不要求立即把应用升级为完整复式
会计。若采用专用 `purpose`，应同步审查：事件 payload/upcaster、`transactions_view`、查询筛选、
monthly snapshots、reports DAO、交易详情/编辑表单与 ARB 文案。系统分类可以作为过渡期内部对方项，
但不应再是用户理解这两类操作的唯一标签。

## 未主张的事项

- 本次没有找到 Actual 自动生成“差额调整交易”的一手证据，因此没有把它列为其行为。
- Firefly III 的源码可证明特殊 transaction/account type，不能单凭源码断言其所有 UI 表单的
  可编辑性或可见性。
- ezBookkeeping 文档确认其余额调整会预填新交易，但没有确认初始余额在交易详情页的具体编辑限制。
