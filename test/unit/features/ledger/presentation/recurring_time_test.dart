import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:feather_ledger/features/ledger/domain/services/ledger_service.dart';
import 'package:feather_ledger/features/ledger/domain/services/recurring_service.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/transaction_form_view_model.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/transaction_form_view_state.dart';

import '../../../../support/fakes/recording_services.dart';
import '../../../../support/mocks/mock_shared_preferences.dart';

void main() {
  test('repeating series starts at the selected date and time without posting',
      () async {
    final selected = DateTime(2026, 1, 15, 14, 35);
    for (final frequency in ['DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY']) {
      final ledger = RecordingLedgerService();
      final recurring = RecordingRecurringService();
      final prefs = PreferencesRepositoryImpl(MockSharedPreferences());
      final container = ProviderContainer(
        overrides: [
          ledgerServiceProvider.overrideWithValue(ledger),
          recurringServiceProvider.overrideWithValue(recurring),
          preferencesRepositoryProvider.overrideWith((_) async => prefs),
          accountListProvider.overrideWithValue(const AsyncData([])),
          accountUiListProvider.overrideWithValue(const AsyncData([])),
          categoryListProvider.overrideWith(
            (_, type) => Stream.value(const <CategoryEntity>[]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final vm = container.read(transactionFormViewModelProvider(null).notifier);
      vm.setAmountText('100.00');
      vm.selectAccount('acc_1');
      vm.selectCategory('cat_1');
      vm.setMode(TransactionFormMode.repeating);
      vm.setRepeat(frequency);
      vm.setDate(selected);

      final outcome = await vm.submit();
      expect(outcome, isA<TransactionFormSaved>(), reason: frequency);
      expect(ledger.addedTransactions, isEmpty, reason: frequency);
      final start = recurring.created.single['startDate']! as DateTime;
      expect(start, selected, reason: frequency);
      expect((start.hour, start.minute), (14, 35), reason: frequency);
    }
  });
}
