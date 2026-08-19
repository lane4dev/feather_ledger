import 'package:feather_ledger/features/ledger/presentation/view_model/transaction_form_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the next occurrence keeps the time selected for a recurring entry', () {
    final selected = DateTime(2026, 1, 15, 14, 35);
    for (final frequency in ['DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY']) {
      final next = TransactionFormViewModel.nextOccurrence(selected, frequency);
      expect((next.hour, next.minute), (14, 35), reason: frequency);
    }
  });
}
