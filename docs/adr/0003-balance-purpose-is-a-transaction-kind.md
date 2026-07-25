# Opening balances and balance adjustments are transaction kinds

**Status**: accepted

Opening balances and later reconciliation differences are auditable money movements, but they are
not income, expense, or a user category. They are recorded as category-free `TransactionRecorded`
events whose `TransactionKind` is `openingBalance` or `balanceAdjustment`; commands express the
intent while the existing transaction projector remains the single balance writer. This deliberately
does not introduce parallel `AccountOpeningBalanceSet` / `AccountBalanceAdjusted` event streams:
that would duplicate the transaction projection and make correction, deletion, snapshots, and
rebuild semantics diverge.

## Consequences

- Both kinds affect account balances and remain editable through the normal reversal-plus-replacement
  audit chain, but are excluded from category, income/expense, and budget aggregates.
- Historical records filed under the two fixed legacy reversal-category IDs are interpreted by the
  projector only; their immutable events are not rewritten. A creation command's `-opening` suffix
  identifies the old opening-balance half, with other legacy reversal records treated as adjustments.
- A future full double-entry model may use an Opening Balances equity account, but the lightweight
  ledger does not add that user-facing account hierarchy merely to represent these two purposes.
