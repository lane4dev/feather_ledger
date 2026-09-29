# Scheduled bill identity by UUID and two-scope editing

**Status**: accepted

Each row in `scheduled_transactions_view` uses an independent UUID primary key paired
with `UNIQUE(series_id, occurrence_key)` (the rule-derived logical date `YYYY-MM-DD`,
or `'single'` for a one-off `planned` entry). Single-occurrence edits (`thisOnly`)
write nullable overrides (`amount_override_minor`, `date_override`, `memo_override`)
on that row without altering its UUID or `occurrence_key`, and notifications carry
that UUID directly. This replaces date-encoded primary keys (`${seriesId}_${ms}`)
and removes the need for a redirect table or deletion-stub table.

Editing a recurring rule (`updateRule`) applies only to pending future bills—never
splitting a series or shifting already-posted transactions—and when frequency or
start date changes, pending unposted and skipped rows are cleared (leaving only posted
rows) and re-materialized under the new rule. The trade-off is that unposted future bills receive new UUIDs when a rule's
schedule changes, invalidating their pending notification payloads until reminders
re-sync; we accept this to keep personal-ledger scheduling free of calendar-style
series splitting, redirect chains, and multi-batch eligibility state machines.
