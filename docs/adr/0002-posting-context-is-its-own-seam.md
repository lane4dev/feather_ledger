# Posting context lives in its own seam, not in the aggregate

**Status**: accepted

A transaction's legality rests on two different kinds of fact: its own shape — how many postings, which
directions, whether the legs agree — and facts about what it references — that the account exists and is
not archived, that the category does too, and that the category's kind matches the transaction's. Only
the first belongs to the aggregate: the second needs a repository lookup, and pulling that into
`Transaction` would make the aggregate depend on data access. The second set now lives behind a single
`PostingContext` seam that every writer runs before building the aggregate.

## Considered Options

- **Leave the checks in each command.** Rejected: the three writers of `TransactionRecorded` had already
  drifted — one of them never checked the category kind at all, and two verify account existence against
  the event stream while the rest read the projection.
- **Move the checks onto the append path.** Rejected for the same reason as ADR-0001's second option.

## Consequences

- The seam returns the entities it fetched rather than only a verdict, so a writer does not query twice
  for facts the posting needs anyway — account currency, category id.
- Writers keep the rules that describe their own interface rather than the transaction. The non-transfer
  entry point still rejects `kind == transfer`, because that describes the command, not the ledger.
- A recurring series cannot be a transfer, and cannot be *typed* as one. A series carries a single
  account, so a transfer series has no second leg to express. The series' kind is narrowed to income or
  expense, making the state unrepresentable rather than written and then rejected — the same principle
  as ADR-0001's intent-shaped constructors, applied where the schema can carry it.
