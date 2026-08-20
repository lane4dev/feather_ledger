# Feather Ledger

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
Recurring rules and already-due bills remain while an account is archived; future pending bills are
marked skipped, and generation, posting and reminders pause. Restoring resumes the rules without
reviving the skipped bills.
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
has two accounts to move between, and a series has one. An auto-posting series has its due instances
confirmed by the app at launch; the UI label for that is 订阅 (subscription), which stays a label —
the domain term is recurring series. A one-shot series (start equals end) is the 计划 (planned) entry:
one pending bill, no recorded transaction.
_Avoid_: recurring transaction, schedule, subscription

### Money

**Minor unit**:
The smallest indivisible unit of a currency. Every amount — UI model, event payload, database row — is
a signed integer count of these; fractions do not exist.
_Avoid_: cents, decimals, floating point

**Display currency**:
A formatting preference. It changes how amounts are rendered and never participates in a calculation.
_Avoid_: currency, exchange rate

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
