# Accounted For

A personal bookkeeping ledger (记账). Every money movement is recorded once as an event, and every
balance, total and report is derived from that record.

## Language

### The ledger

**Transaction**:
The aggregate root — one complete money movement, owning its postings and the rules that make its shape
legal.
_Avoid_: entry, record, journal entry, item

**Posting**:
One money movement against one account. The amount is always positive; direction carries the sign.
_Avoid_: line, leg, entry, split

**Transfer**:
A transaction with exactly two postings of equal amount and opposite direction, on two different
accounts of the same currency. A credit-card repayment is a transfer, not an expense.
_Avoid_: internal transaction, movement

**Reversal**:
Recording that a transaction no longer stands, without deleting it. Its reason distinguishes a user
deletion from a correction — a reversal paired with a replacement transaction.
_Avoid_: deletion, cancellation, void, undo

**Archive**:
Withdrawing an account or category from active use while preserving every historical reference to it.
An archived account can be restored and still participates in totals according to its inclusion setting.
When an account is archived, already-due pending bills are preserved as one-off planned bills, and
its recurring rules and future pending bills are removed; restoring the account does not revive those
removed rules.
Not a delete.
_Avoid_: delete, deactivate, soft delete

**Account deletion**:
Removing an unused account from ordinary lists and selectors. The account and its deletion remain in
the event stream and projection for replay. Active transactions and recurring series can be moved to
another account, or deleted together with an archived account. Balance-purpose transactions are
reversed when their account is deleted. Reversed transactions do not prevent deletion.
_Avoid_: archive, physical erasure

**Opening balance**:
The non-zero amount an account already has when it is first brought into the ledger. It is a
category-free transaction purpose, never income or expense.
_Avoid_: initial balance transaction, balance correction

**Balance adjustment**:
A category-free transaction that records the signed difference discovered while reconciling an
account to an external balance. It is distinct from an opening balance and from ordinary income or
expense.
_Avoid_: correction category, edited account balance

**Recurring series**:
A rule that produces the same transaction on a schedule. Its kind is income or expense only — a transfer
has two accounts to move between, and a series has one. Both one-shot (`planned`) and repeating
(`repeating`) series can enable automatic posting; a repeating series with automatic posting enabled
keeps the UI label 订阅 (subscription) and a one-shot series keeps the UI label 计划 (planned),
which stay UI labels — the domain term is recurring series. Stopping a recurring series halts future
generation and removes pending and skipped instances while leaving already-posted transactions and
history intact.
_Avoid_: recurring transaction, schedule, subscription

**Automatic posting**:
Recording a due auto-posting scheduled bill in the ledger without a separate manual confirmation, when
its currency is the current currency and it is not marked manual-only (at launch, on currency
switch-back, or immediately after saving an auto-posting rule for the current currency). It records
a money movement and does not itself transfer money or pay a bill.
_Avoid_: automatic payment, automatic debit

**Source bill**:
The scheduled occurrence from which a transaction was recorded. Its association remains meaningful
when the transaction is corrected or its series is stopped or deleted; an ordinary transaction need
not have one.
_Avoid_: transaction mode, payment source

**Manual-only bill**:
A pending bill that must be handled by the user rather than posted automatically (for example, a bill
due before a backup restore, kept manual on currency switch-back, or restored from a skipped state
while already due under an auto-posting rule). Rescheduling a manual-only bill to a future date
clears this mark.
_Avoid_: failed bill, skipped bill

**Entry mode**:
The intent selected when creating an entry: default (immediate transaction), planned (one-off future
bill), or repeating (recurring series). Automatic posting is an option on a planned or repeating
series rather than a separate entry mode. Once posted, the resulting transaction is presented as an
ordinary transaction.
_Avoid_: payment method, recurrence frequency

### Money

**Ledger amount unit**:
One hundredth of a currency unit in this ledger, including for currencies normally displayed without
two decimal places. Recorded amounts are integers in these units; this is not necessarily the
currency's standard minor unit.
_Avoid_: currency minor unit, cents

**Current currency**:
The currency selected in settings for the current ledger view. It limits which transactions and accounts
are shown by default; changing it does not convert an account's currency or amount.
_Avoid_: display currency, account currency, exchange rate

**Account currency**:
The single currency in which an account's money movements and balance are recorded. It is chosen when
the account is created and does not change when the current currency changes.
_Avoid_: current currency, display currency

**Balance**:
An account's current total, defined as including future-dated transactions and computed in exactly one
place.
_Avoid_: total, amount, sum

**Ledger totals**:
The figures that sum **across** accounts — the running balance the header shows, a month's income and
expense, each day's subtotals, and everything on the reports page. Distinct from a *balance*, which is a
fact about one account: an account left out of the ledger totals still has one, and it is still shown
everywhere that account is shown. Archiving an account does not take it out of the totals; excluding it
does — the two off-switches are independent and point in opposite directions.
_Avoid_: stats, statistics, aggregate, summary

### Derived data

**Projection**:
A read model built from the event stream and rebuildable from it alone.
_Avoid_: view, materialized view, cache

**Monthly balance snapshot**:
The per-account, per-currency, per-month projection of income, expense, transfers and closing balance.
A time series, not a cache of aggregate state.
_Avoid_: snapshot, balance snapshot, monthly summary

**Category snapshot**:
The category name, icon and colour copied onto a transaction as it is recorded, so archiving a category
never rewrites history.
_Avoid_: category copy, denormalized category, frozen category

> "Snapshot" alone is ambiguous here. Say *monthly balance snapshot* for the time series, *category
> snapshot* for the write-time copy. Note that in event sourcing "snapshot" more often means a cached
> aggregate state — this ledger has no such thing.

### Rules and failure

**Transaction violation**:
A domain judgement that a transaction's shape is illegal — wrong number of postings, transfer legs that
disagree, a non-positive amount.
_Avoid_: validation error, constraint error, exception

**Ledger error code**:
The closed set of failures a person can be shown. Distinct from a violation: several violations may
share one code, and some codes — unknown account, archived category — have no violation behind them at
all.
_Avoid_: error, violation, failure code

**Posting context**:
The facts about other things a posting needs before it can exist: that its account exists and is not
archived, that its category does too, and that the category's kind matches the transaction's. These
live outside the transaction and must be gathered before it is built.
_Avoid_: dependencies, preconditions, lookup

### Construction

**Rehydrate**:
Rebuilding a transaction from what was already recorded, for replay. Distinct from recording a new one:
rehydration re-checks a stored shape, it does not express intent.
_Avoid_: deserialize, restore, fromJson, load

### Budget & Review

**Category budget**:
A strictly positive monthly spending cap set for one expense category under the current currency.
Clearing a category budget removes the cap rather than storing zero; budgets do not roll unused
amounts into later months or cross currencies.
_Avoid_: planned amount, category cap, monthly target

**Budget timeline**:
The stepped effective-month sequence of a category's budget rules. Unless explicitly changed or
cleared, a rule carries forward indefinitely into subsequent months; a single-month edit anchors the
following month to preserve prior expectations, while a forward edit replaces all later breakpoints.
Archiving a category keeps its active budget for the archive month and halts carry-forward from the
next month onward.
_Avoid_: budget copy, monthly clone, budget schedule

**Committed spend**:
Expenses committed through scheduled or one-off planned bills — combining posted transactions that
carry a source bill in the month with not-yet-posted pending bills in tracking or planning mode. Its
monthly sum also serves as that category's committed baseline.
_Avoid_: fixed cost, recurring expense, subscription spend

**Discretionary spend**:
Ordinary expense transactions without a source bill, representing flexible spending that can be
curtailed within the month.
_Avoid_: variable spend, unscheduled spend

**Pending bill exposure**:
Scheduled or failed expense bills falling due in a current or future month. Included in projected
remaining budget and overrun risk alerts during tracking and planning, and excluded from actuals in
historical review.
_Avoid_: projected actual, unpaid expense

**Budget variance**:
The signed difference `budget - actual` for a category or month (positive when under budget, negative
when overspent). Tracked alongside pending exposure for overrun risk, while month-over-month anomaly
alerts compare discretionary and total category spend against the prior three-month average.
_Avoid_: diff, balance remaining, overrun

**Review note**:
A plain-text retrospective reflection attached to a currency and month (and optionally a category),
explaining variance and recording next-month adjustments. Preserved as read-only history once a
category is archived.
_Avoid_: comment, memo, journal
