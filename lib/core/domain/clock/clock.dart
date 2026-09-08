/// Injectable domain clock (spec 003, P1).
///
/// Commands must never call `DateTime.now()` directly — recordedAt values
/// come from the injected clock so tests (and later seed/replay logic) are
/// deterministic. The production binding is the real wall clock; tests
/// bind a fixed or scripted one.
library;

abstract class DomainClock {
  DateTime now();
  DateTime today();
}

class SystemClock implements DomainClock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();

  @override
  DateTime today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }
}

/// Fixed clock for tests and seeding.
class FixedClock implements DomainClock {
  final DateTime _now;

  FixedClock(this._now);

  @override
  DateTime now() => _now;

  @override
  DateTime today() => DateTime(_now.year, _now.month, _now.day);
}
