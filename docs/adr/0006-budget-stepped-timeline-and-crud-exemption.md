# Budget stepped timeline and CRUD exemption

**Status**: accepted

Category budgets are stored in CRUD-exempt tables (`budget_rules` and `budget_review_notes`)
using a stepped effective-month timeline (`effective_ym = year * 100 + month`, nullable
`amount_minor`) per `(currency_code, category_id)` rather than materialized monthly rows or
events in `ledger_events`. A rule takes effect from `effective_ym` forward until superseded by a
later breakpoint or an explicit `null` (`unset`) breakpoint; `thisMonthOnly` edits defensively
anchor `effective_ym + 1` to the prior state before updating `effective_ym`, while
`thisAndFollowing` deletes all breakpoints strictly after `effective_ym`. Category archival
continues to emit `CategoryArchived` alone, while `categories_view` projects `archived_at` from
the event envelope timestamp (evaluated via `.toLocal()` so archive cutoffs align with local
transaction months) so budget queries stop carrying rules forward after the archive month without
mutating `budget_rules`.

We chose this over event-sourcing budgets or generating one row per month because budgets are
planning targets rather than immutable money movements; keeping them out of `ledger_events`
ensures `LedgerRebuildService` never erases user budget plans, while stepped breakpoints avoid
unbounded row generation or background monthly roll jobs. Notice that writes prune redundant
breakpoints in ascending `effective_ym` order from `M` through its immediate successor `M_next`
(and any leading `null` sentinel) inside the same transaction. The trade-off is that `.flbackup`
restores rely on SQLite schema migration (`AppDatabase.onUpgrade`) and `thisMonthOnly` edits
require a read-anchor-write-prune pass inside a single transaction; we accept this to keep event
replay strictly scoped to financial history and budget reads O(1) across any future month.
