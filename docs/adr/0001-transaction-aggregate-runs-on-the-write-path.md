# The Transaction aggregate runs on the write path, not only at projection time

**Status**: accepted

`Transaction` owns the rules that make a transaction's shape legal, but it was constructed and validated
only inside the projector, at apply time — after the event had been built and was about to be persisted.
Commands assembled postings by hand and re-typed the same rules, and a third writer
(`convert_scheduled_to_posted`) silently enforced fewer of them than the other two. Every command now
builds and validates the aggregate before constructing the event, so a shape error is rejected by the
writer rather than by a rollback, and the shape rules exist in one place.

## Considered Options

- **Keep re-typing checks in each command.** Rejected: three writers had already drifted apart, and
  nothing structural prevented the next divergence.
- **Validate inside the event store's append path.** Rejected: it would make the event store depend on
  account and category lookups, turning a deep persistence module into an orchestration point.
- **A single domain service that commands delegate to.** Rejected: it demotes commands to pass-throughs,
  the exact failure mode this work set out to remove.

## Consequences

- Replay and write share the same validation code but serve different purposes: the writer uses it to
  reject intent, the projector uses it to detect a corrupted stored stream. The projector's checks stay.
- `Transaction` exposes two doors — intent-shaped constructors for writers, `rehydrate` for replay. The
  distinct name is what makes a bypass visible in review; a future writer that reaches for `rehydrate`
  is announcing that it is going around validation.
- Context rules cannot live in the aggregate, because they need repository lookups. See ADR-0002.
