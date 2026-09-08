/// Command result type (spec 003, Command Model).
///
/// Every ledger write command returns `Result` — failures carry a
/// user-presentable [LedgerErrorCode] and message, and no bare exception
/// escapes the service boundary into ViewModels.
library;

/// Machine-readable failure codes, mapped to localized strings at the
/// presentation edge. Keep the set closed: adding a code means adding its
/// `.arb` entries in all three locales.
enum LedgerErrorCode {
  accountNotFound,
  accountArchived,
  categoryNotFound,
  categoryArchived,
  categoryTypeMismatch,
  currencyMismatch,
  sameAccountTransfer,
  invalidAmount,
  invalidTransfer,
  transactionNotFound,
  transactionAlreadyReversed,
  systemCategoryProtected,
  unknownEvent,
}

/// Result of a command. `T` is the success payload — `void` commands use
/// `Result<void>` with `unit` as the value.
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(LedgerErrorCode code, String message) =
      Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  /// Value if success; throws [StateError] on failure. Pattern-match or
  /// [when] in calling code instead of blindly reading this.
  T get value => switch (this) {
        Success<T>(:final value) => value,
        Failure<T>() => throw StateError('Result has no value: $this'),
      };

  /// Folds both cases into one output.
  R when<R>({
    required R Function(T value) success,
    required R Function(LedgerErrorCode code, String message) failure,
  }) =>
      switch (this) {
        Success<T>(:final value) => success(value),
        Failure<T>(:final code, :final message) => failure(code, message),
      };
}

final class Success<T> extends Result<T> {
  @override
  final T value;

  const Success(this.value);
}

final class Failure<T> extends Result<T> {
  final LedgerErrorCode code;

  /// Developer-facing description (English). The presentation layer maps
  /// [code] to localized strings; this message is for logs/debugging.
  final String message;

  const Failure(this.code, this.message);
}

/// Convenience success value for `Result<void>`.
const Result<void> unitResult = Success<void>(null);

/// Thrown by commands when a domain rule rejects the write. [guard] maps it
/// to [Result.failure] with the specific [LedgerErrorCode] — the one way a
/// command communicates a presentable failure without crossing the service
/// boundary with a bare exception.
class CommandRejected implements Exception {
  final LedgerErrorCode code;
  final String message;

  const CommandRejected(this.code, this.message);

  @override
  String toString() => 'CommandRejected(${code.name}): $message';
}

/// Helper to run async work and convert thrown errors into
/// [Result.failure] — the single sanctioned place where an exception
/// becomes a `Result`, used by services wrapping infrastructure calls.
Future<Result<T>> guard<T>(Future<T> Function() body) async {
  try {
    return Result.success(await body());
  } on CommandRejected catch (e) {
    return Result.failure(e.code, e.message);
  } catch (e) {
    return Result.failure(LedgerErrorCode.unknownEvent, e.toString());
  }
}
