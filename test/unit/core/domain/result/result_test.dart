import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/result/result.dart';

void main() {
  group('Result', () {
    test('success carries value and folds', () {
      const result = Result<int>.success(42);
      expect(result.isSuccess, isTrue);
      expect(result.value, 42);
      expect(
        result.when(
          success: (v) => 'ok $v',
          failure: (code, message) => 'fail',
        ),
        'ok 42',
      );
    });

    test('failure carries error code and message', () {
      const result = Result<void>.failure(
        LedgerErrorCode.accountNotFound,
        'no such account',
      );
      expect(result.isFailure, isTrue);
      expect(result, isA<Failure<void>>());
      const failure = result as Failure<void>;
      expect(failure.code, LedgerErrorCode.accountNotFound);
      expect(failure.message, 'no such account');
      expect(
        result.when(
          success: (_) => 'ok',
          failure: (code, message) => '$code:$message',
        ),
        'LedgerErrorCode.accountNotFound:no such account',
      );
    });

    test('value getter throws on failure', () {
      const result = Result<int>.failure(
        LedgerErrorCode.invalidAmount,
        'zero',
      );
      expect(() => result.value, throwsStateError);
    });

    test('no bare exception escapes guard', () async {
      final result = await guard<int>(
        () async => throw StateError('boom'),
      );
      expect(result.isFailure, isTrue);
      expect(
        (result as Failure<int>).message,
        contains('boom'),
      );
    });

    test('guard passes success through', () async {
      final result = await guard<int>(() async => 7);
      expect(result.value, 7);
    });
  });

  group('Clock', () {
    test('FixedClock returns injected time deterministically', () {
      final clock = FixedClock(DateTime(2026, 9, 6, 14, 30));
      expect(clock.now(), DateTime(2026, 9, 6, 14, 30));
      expect(clock.today(), DateTime(2026, 9, 6));
    });

    test('SystemClock now does not go backwards', () {
      const clock = SystemClock();
      final first = clock.now();
      final second = clock.now();
      expect(second.isBefore(first), isFalse);
    });
  });
}
