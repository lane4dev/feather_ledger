# Scheduled bill identity by UUID and two-scope editing

**Status**: accepted

Each row in `scheduled_transactions_view` uses an independent UUID primary key paired
with `UNIQUE(series_id, occurrence_key)`. For `repeating` series, `occurrence_key` is
the rule-derived **local civil date `YYYY-MM-DD`** (never UTC, so local midnight and
timezone changes never shift an occurrence across calendar months); for a one-off
`planned` entry, `occurrence_key` is `'single'`. Both physical materialization and
budget virtual projection share a single local civil-date `RecurrenceExpander` so
logical occurrence keys and dates never drift.

Single-occurrence edits (`thisOnly`) write nullable overrides (`amount_override_minor`,
`date_override`, `memo_override`) on that row without altering its UUID or
`occurrence_key`, and notifications carry that UUID directly. This replaces
date-encoded primary keys (`${seriesId}_${ms}`) and removes the need for a redirect
table or deletion-stub table.

Two series-level columns govern bounded materialization and lifetime count integrity:
- `materialize_from` defines the inclusive local lower bound for physical
  materialization and budget virtual projection, while `start_date` remains the
  immutable schedule and `count_limit` anchor (e.g., generating a distant-past
  installment rule from today onward without losing its billing day or remaining count).
- `completed_count_offset` records how many `posted` occurrences were completed before
  the latest `updateRule` base-schedule reset. `count_limit` always represents total
  lifetime occurrences in storage and UI, and expansion uses
  `count_limit - completed_count_offset` for the remaining schedule.

Editing a recurring rule (`updateRule`) applies only to pending future bills—never
splitting a series or shifting already-posted transactions—and when frequency or
start date changes, `completed_count_offset` is recalculated from existing `posted`
rows, pending unposted and skipped rows are cleared (leaving only posted rows), and
occurrences are re-materialized under the new rule. The trade-off is that unposted
future bills receive new UUIDs when a rule's schedule changes, invalidating their
pending notification payloads until reminders re-sync; we accept this to keep
personal-ledger scheduling free of calendar-style series splitting, redirect chains,
and multi-batch eligibility state machines.

**Materialize-on-Write for far-future virtual bills**: Budget planning (Plan mode)
projects active expense series beyond the physical lookahead horizon as virtual
pending occurrences keyed by `(series_id, occurrence_key)`. When the user acts on a
virtual occurrence (single-occurrence edit, rule edit, or skip), the write path first
idempotently materializes a standard `scheduled` UUID row for `(series_id,
occurrence_key)` inside one transaction (`INSERT OR IGNORE`), then enters the standard
`thisOnly` / `updateRule` edit or skip flow with no separate state machine.
