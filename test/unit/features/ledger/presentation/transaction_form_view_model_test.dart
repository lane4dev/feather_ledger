import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:feather_ledger/features/ledger/data/transaction_attachment_store.dart';
import 'package:feather_ledger/features/ledger/domain/services/ledger_service.dart';
import 'package:feather_ledger/features/ledger/domain/services/recurring_service.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/transaction_form_view_model.dart';
import 'package:feather_ledger/shared/presentation/models/account_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/transaction_form_view_state.dart';

import '../../../../support/fakes/recording_services.dart';
import '../../../../support/mocks/mock_shared_preferences.dart';

/// The transaction form's rules, without a widget in sight.
///
/// This is what moving the logic out of the screen buys: the parts that were
/// only reachable by pumping a form — which write a save takes, what happens
/// to imported files when it is rejected, whether the sign survives an edit —
/// are now assertions in a plain test.
/// A fixed currency so the form's lock is deterministic in a plain test. It is
/// mutable so a test can simulate the setting changing while a form is open.
class _FixedCurrency extends CurrencyController {
  _FixedCurrency(this.code);

  String code;

  @override
  Future<String> build() async => code;

  @override
  Future<void> setCurrency(String currencyCode) async {
    code = currencyCode;
    state = AsyncData(currencyCode);
  }
}

void main() {
  const cash = AccountEntity(
    id: 'acc_cash',
    name: 'Cash',
    type: AccountType.cash,
    currencyCode: 'USD',
    balanceMinor: 100000,
    archived: false,
    lastUpdatedEventId: 0,
  );
  const card = AccountEntity(
    id: 'acc_card',
    name: 'Card',
    type: AccountType.credit,
    currencyCode: 'USD',
    balanceMinor: -50000,
    archived: false,
    lastUpdatedEventId: 0,
  );
  const yen = AccountEntity(
    id: 'acc_yen',
    name: 'Yen',
    type: AccountType.other,
    currencyCode: 'JPY',
    balanceMinor: 0,
    archived: false,
    lastUpdatedEventId: 0,
  );
  const archived = AccountEntity(
    id: 'acc_old',
    name: 'Old',
    type: AccountType.other,
    currencyCode: 'USD',
    balanceMinor: 0,
    archived: true,
    lastUpdatedEventId: 0,
  );
  const rent = CategoryEntity(
    id: 'cat_rent',
    name: 'Rent',
    iconKey: '1',
    colorInt: 0xFF000000,
    type: CategoryType.expense,
  );
  const salary = CategoryEntity(
    id: 'cat_salary',
    name: 'Salary',
    iconKey: '2',
    colorInt: 0xFF000000,
    type: CategoryType.income,
  );

  late RecordingLedgerService ledger;
  late RecordingRecurringService recurring;
  late RecordingAttachmentStore store;

  setUp(() {
    ledger = RecordingLedgerService();
    recurring = RecordingRecurringService();
    store = RecordingAttachmentStore();
  });

  ProviderContainer container({
    String currency = 'USD',
    PreferencesRepository? preferences,
  }) {
    final container = ProviderContainer(
      overrides: [
        ledgerServiceProvider.overrideWithValue(ledger),
        recurringServiceProvider.overrideWithValue(recurring),
        transactionAttachmentStoreProvider.overrideWithValue(store),
        accountListProvider.overrideWithValue(
          const AsyncData([cash, card, yen, archived]),
        ),
        categoryListProvider.overrideWith(
          (ref, type) => Stream.value(
            type == CategoryType.income ? const [salary] : const [rent],
          ),
        ),
        currencyControllerProvider.overrideWith(() => _FixedCurrency(currency)),
        if (preferences != null)
          preferencesRepositoryProvider
              .overrideWith((ref) async => preferences),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// A form for a new entry, or for the one in [original].
  TransactionFormViewModel form(ProviderContainer container,
          {TransactionTileUiModel? original}) =>
      container.read(transactionFormViewModelProvider(original).notifier);

  TransactionTileUiModel tile({
    required String id,
    required int amount,
    TransactionKind type = TransactionKind.expense,
    CategoryEntity? category,
    AccountEntity from = cash,
    AccountEntity? to,
    String sign = '-',
  }) =>
      TransactionTileUiModel(
        id: id,
        amount: amount,
        type: type,
        date: DateTime(2026, 1, 10, 14, 30),
        note: 'rent',
        category: category,
        account: from,
        toAccount: to,
        displayAmount: '1.00',
        displaySign: sign,
      );

  group('seeding', () {
    test('a new entry starts as an expense, today, empty', () {
      final vm = form(container());

      expect(vm.state.type, TransactionKind.expense);
      expect(vm.state.original, isNull);
      expect(vm.state.amountText, isEmpty);
      expect(vm.state.accountId, isNull);
      expect(vm.state.repeat, TransactionFormViewState.repeatNever);
      expect(vm.state.canRepeat, isTrue);
    });

    test('a new form locks its currency at open time', () async {
      final c = container(currency: 'JPY');
      // The ledger screen watches the currency before any form can open, so
      // the provider is already resolved when the form reads it once.
      await c.read(currencyControllerProvider.future);

      final vm = form(c);

      expect(vm.state.currencyCode, 'JPY');
    });

    test('an edit locks to the original account\'s currency', () {
      final vm = form(
        container(currency: 'JPY'),
        original: tile(
          id: 'tx_1',
          amount: 1234,
          category: rent,
          type: TransactionKind.income,
        ),
      );

      expect(vm.state.currencyCode, 'USD');
    });

    test('a setting change mid-form does not re-currency the form', () async {
      final c = container(); // locked to USD at open
      await c.read(currencyControllerProvider.future);
      final vm = form(c);

      expect(vm.state.currencyCode, 'USD');

      await c.read(currencyControllerProvider.notifier).setCurrency('JPY');

      expect(vm.state.currencyCode, 'USD',
          reason: 'the lock is a one-time read, not a watch');
    });

    test('a correction lands every field, amount included', () {
      final vm = form(
        container(),
        original: tile(
          id: 'tx_1',
          amount: 1234,
          category: rent,
          type: TransactionKind.income,
        ),
      );

      expect(vm.state.isEditing, isTrue);
      expect(vm.state.type, TransactionKind.income);
      expect(vm.state.amountText, '12.34');
      expect(vm.state.amountMinor, 1234);
      expect(vm.state.note, 'rent');
      expect(vm.state.categoryId, 'cat_rent');
      expect(vm.state.accountId, 'acc_cash');
      expect(vm.state.date, DateTime(2026, 1, 10, 14, 30));
      // Editing never touches a series.
      expect(vm.state.repeat, TransactionFormViewState.repeatNever);
      expect(vm.state.canRepeat, isFalse);
    });

    test('a transfer does not carry the mapper\'s empty category', () {
      final vm = form(
        container(),
        original: tile(
          id: 'tx_2',
          amount: 1000,
          type: TransactionKind.transfer,
          from: cash,
          to: card,
          // What the mapper hands a transfer: a placeholder with no id.
          category: const CategoryEntity(
            id: '',
            name: '',
            iconKey: '',
            colorInt: 0,
            type: CategoryType.expense,
          ),
        ),
      );

      expect(vm.state.categoryId, isNull);
      expect(vm.state.toAccountId, 'acc_card');
    });
  });

  group('transitions', () {
    test('the amount reads as minor units only when it is a number', () {
      final vm = form(container());

      for (final empty in ['', '.', '0', '0.00', 'abc', '1.234']) {
        vm.setAmountText(empty);
        expect(vm.state.amountMinor, isNull, reason: 'for "$empty"');
      }

      vm.setAmountText('12.5');
      expect(vm.state.amountMinor, 1250);
    });

    test('switching kind clears what the new kind cannot carry', () {
      final vm = form(container());
      vm.setAmountText('20.00');
      vm.setNote('lunch');
      vm.selectCategory('cat_rent');
      vm.selectAccount('acc_cash');

      vm.setType(TransactionKind.transfer);

      expect(vm.state.categoryId, isNull, reason: 'no category on a transfer');
      expect(vm.state.toAccountId, isNull);
      // Everything the new kind *can* carry stays.
      expect(vm.state.amountText, '20.00');
      expect(vm.state.note, 'lunch');
      expect(vm.state.accountId, 'acc_cash');
    });

    test('picking a new source drops a destination the filter may not offer',
        () {
      final vm = form(container());
      vm.setType(TransactionKind.transfer);
      vm.selectAccount('acc_cash');
      vm.selectToAccount('acc_card');

      vm.selectAccount('acc_yen');

      expect(vm.state.accountId, 'acc_yen');
      expect(vm.state.toAccountId, isNull);
    });
  });

  group('the rules that read the account list', () {
    test('pickers offer active accounts in the form\'s currency only', () {
      final vm = form(container()); // locked to USD

      final active = vm.state
          .activeAccounts([cash, card, yen, archived].map(AccountUiModel.of));

      expect(active.map((a) => a.account.id), ['acc_cash', 'acc_card'],
          reason: 'the yen account is a different currency, and the archived '
              'account is history');
    });

    test('a transfer cannot land on its own source or another currency', () {
      final vm = form(container());
      final active =
          vm.state.activeAccounts([cash, card, yen].map(AccountUiModel.of));
      vm.setType(TransactionKind.transfer);
      vm.selectAccount('acc_cash');

      final destinations =
          vm.state.transferDestinations(active).map((a) => a.account.id);

      expect(destinations, ['acc_card']);
      expect(destinations, isNot(contains('acc_yen')),
          reason: 'cross-currency transfers wait for exchange rates');
    });

    test('an expense that takes an account below zero would overdraw', () {
      final vm = form(container());
      vm.setType(TransactionKind.expense);

      vm.setAmountText('2000.00');
      vm.selectAccount('acc_cash'); // holds 1000.00
      expect(vm.wouldOverdraft(), isTrue);

      vm.selectAccount('acc_card');
      expect(vm.wouldOverdraft(), isFalse,
          reason: 'a credit account is meant to go negative');

      vm.setAmountText('10.00');
      vm.selectAccount('acc_cash');
      expect(vm.wouldOverdraft(), isFalse);
    });

    test('a transfer is never asked the overdraft question', () {
      final vm = form(container());
      vm.setAmountText('2000.00');
      vm.setType(TransactionKind.transfer);
      vm.selectAccount('acc_cash');

      expect(vm.wouldOverdraft(), isFalse);
    });
  });

  group('saving', () {
    test('a new expense records with the chosen fields', () async {
      final vm = form(container());
      vm.setAmountText('12.34');
      vm.selectAccount('acc_cash');
      vm.selectCategory('cat_rent');
      vm.setNote('lunch');

      final outcome = await vm.submit();

      expect(outcome, isA<TransactionFormSaved>());
      final call = ledger.addedTransactions.single;
      expect(call['amountMinor'], 1234);
      expect(call['type'], TransactionKind.expense);
      expect(call['categoryId'], 'cat_rent');
      expect(call['accountId'], 'acc_cash');
      expect(call['note'], 'lunch');
      expect(call['commandId'], isNotEmpty);
      expect(ledger.updatedTransactions, isEmpty);
    });

    test('a correction corrects instead of adding', () async {
      final vm = form(
        container(),
        original: tile(id: 'tx_1', amount: 1000, category: rent),
      );
      vm.setAmountText('30.00');

      await vm.submit();

      expect(ledger.addedTransactions, isEmpty);
      expect(ledger.updatedTransactions.single['id'], 'tx_1');
      expect(ledger.updatedTransactions.single['amountMinor'], 3000);
    });

    test('a transfer takes the two legs and no category', () async {
      final vm = form(container());
      vm.setType(TransactionKind.transfer);
      vm.setAmountText('250.00');
      vm.selectAccount('acc_cash');
      vm.selectToAccount('acc_card');

      await vm.submit();

      final call = ledger.addedTransfers.single;
      expect(call['fromAccountId'], 'acc_cash');
      expect(call['toAccountId'], 'acc_card');
      expect(ledger.addedTransactions, isEmpty,
          reason: 'a transfer must not go down the income/expense path');
    });

    test('a balance purpose is seeded with the sign the record has', () async {
      // The tile carries the amount and the direction apart, because a row
      // says the direction with its label. A field cannot, so the form puts
      // them back together — and the sign is then the user's to edit.
      final spending = form(
        container(),
        original: tile(
          id: 'opening-1',
          amount: 12000,
          type: TransactionKind.openingBalance,
          category: null,
          sign: '-',
        ),
      );
      expect(spending.state.amountText, '-120.00');
      expect(spending.state.amountMinor, -12000);

      final funding = form(
        container(),
        original: tile(
          id: 'opening-2',
          amount: 12000,
          type: TransactionKind.openingBalance,
          category: null,
          sign: '+',
        ),
      );
      expect(funding.state.amountText, '120.00');
      expect(funding.state.amountMinor, 12000);
    });

    test('the sign in the field is the direction that gets written', () async {
      final vm = form(
        container(),
        original: tile(
          id: 'opening-1',
          amount: 12000,
          type: TransactionKind.openingBalance,
          category: null,
          sign: '-',
        ),
      );

      // The record was negative; the user says it should have been positive.
      // Typing the minus away is the whole gesture.
      vm.setAmountText('50.00');
      await vm.submit();
      expect(ledger.updatedBalancePurposes.last['signedAmountMinor'], 5000);

      vm.setAmountText('-50.00');
      await vm.submit();
      expect(ledger.updatedBalancePurposes.last['signedAmountMinor'], -5000);
      expect(ledger.updatedBalancePurposes.last['id'], 'opening-1');
      expect(ledger.updatedBalancePurposes.last['accountId'], 'acc_cash');
    });

    test('a kind that carries its own direction refuses a sign', () async {
      final vm = form(container());
      vm.setAmountText('-5.00');
      vm.selectAccount('acc_cash');
      vm.selectCategory('cat_rent');

      // An income or an expense already says which way it points; a minus in
      // the number would be a second, contradictory answer.
      expect(vm.state.amountMinor, isNull);
      expect(await vm.submit(), isA<TransactionFormSaveFailed>());
      expect(ledger.addedTransactions, isEmpty);
    });

    test('an unparseable amount never reaches a command', () async {
      final vm = form(container());
      vm.setAmountText('.');
      vm.selectAccount('acc_cash');
      vm.selectCategory('cat_rent');

      final outcome = await vm.submit();

      expect(outcome, isA<TransactionFormSaveFailed>());
      expect((outcome as TransactionFormSaveFailed).code,
          LedgerErrorCode.invalidAmount);
      expect(ledger.addedTransactions, isEmpty);
    });

    test('a rejected write reports the code and discards the new files',
        () async {
      ledger.failure = LedgerErrorCode.categoryArchived;
      final vm = form(container());
      vm.setAmountText('10.00');
      vm.selectAccount('acc_cash');
      vm.selectCategory('cat_rent');
      vm.attachFiles([XFile('/tmp/receipt.pdf')]);

      final outcome = await vm.submit();

      expect(outcome, isA<TransactionFormSaveFailed>());
      expect((outcome as TransactionFormSaveFailed).code,
          LedgerErrorCode.categoryArchived);
      expect(store.discarded.single.single.fileName, 'receipt.pdf');
    });
  });

  group('the repeat rule', () {
    test('saving with a rule records the entry, then starts the series',
        () async {
      final vm = form(container());
      vm.setAmountText('500.00');
      vm.selectAccount('acc_cash');
      vm.selectCategory('cat_rent');
      vm.setMode(TransactionFormMode.repeating);

      final outcome = await vm.submit();

      expect(outcome, isA<TransactionFormSaved>());
      expect(ledger.addedTransactions, hasLength(1),
          reason: 'the money moved whether or not the schedule did');
      final series = recurring.created.single;
      expect(series['frequency'], 'MONTHLY');
      expect(series['interval'], 1);
      expect(series['autoPost'], isFalse,
          reason: '重复 confirms each bill with the user 记入');
      // The first occurrence *after* the one just recorded.
      expect(
        series['startDate'],
        TransactionFormViewModel.nextOccurrence(vm.state.date, 'MONTHLY'),
      );
    });

    test('the note names the series, falling back to the category', () async {
      final c = container();
      // The form is on screen, so the category list has arrived — the series'
      // fallback name is read from it. The listen is what keeps the
      // auto-disposed stream alive while the first value is awaited.
      c.listen(categoryListProvider(CategoryType.expense), (_, __) {});
      await c.read(categoryListProvider(CategoryType.expense).future);
      final vm = form(c);
      vm.setAmountText('500.00');
      vm.selectAccount('acc_cash');
      vm.selectCategory('cat_rent');
      vm.setMode(TransactionFormMode.repeating);

      await vm.submit();
      expect(recurring.created.single['description'], 'Rent');

      vm.setNote('Flat');
      await vm.submit();
      expect(recurring.created.last['description'], 'Flat');
    });

    test('a series that cannot start does not lose the entry', () async {
      recurring.failure = LedgerErrorCode.unknownEvent;
      final vm = form(container());
      vm.setAmountText('500.00');
      vm.selectAccount('acc_cash');
      vm.selectCategory('cat_rent');
      vm.setMode(TransactionFormMode.repeating);

      final outcome = await vm.submit();

      expect(outcome, isA<TransactionFormSavedSeriesFailed>());
      expect((outcome as TransactionFormSavedSeriesFailed).code,
          LedgerErrorCode.unknownEvent);
      expect(ledger.addedTransactions, hasLength(1),
          reason: 'the record is legitimate on its own');
    });

    test('the mode owns the frequency: a series mode seeds MONTHLY, leaving resets it',
        () {
      final vm = form(container());

      vm.setMode(TransactionFormMode.repeating);
      expect(vm.state.repeat, 'MONTHLY',
          reason: 'the row cannot show "does not repeat" — the mode said it does');

      vm.setMode(TransactionFormMode.planned);
      expect(vm.state.repeat, TransactionFormViewState.repeatNever,
          reason: 'a planned entry is one-shot and has no frequency to carry');

      vm.setMode(TransactionFormMode.repeating);
      expect(vm.state.repeat, 'MONTHLY');

      vm.setMode(TransactionFormMode.defaultMode);
      expect(vm.state.repeat, TransactionFormViewState.repeatNever,
          reason: 'a default entry has no frequency to carry');
    });

    test('a planned entry creates one bill and records nothing', () async {
      final vm = form(container());
      vm.setAmountText('500.00');
      vm.selectAccount('acc_cash');
      vm.selectCategory('cat_rent');
      vm.setMode(TransactionFormMode.planned);

      final outcome = await vm.submit();

      expect(outcome, isA<TransactionFormSaved>());
      expect(ledger.addedTransactions, isEmpty,
          reason: '计划 moves no money — the bill has not happened yet');
      final series = recurring.created.single;
      expect(series['startDate'], vm.state.date);
      expect(series['endDate'], vm.state.date,
          reason: 'a one-shot rule: exactly one instance, on the chosen day');
      expect(series['autoPost'], isFalse);
    });

    test('a planned entry that fails is a failed save', () async {
      recurring.failure = LedgerErrorCode.unknownEvent;
      final vm = form(container());
      vm.setAmountText('500.00');
      vm.selectAccount('acc_cash');
      vm.selectCategory('cat_rent');
      vm.setMode(TransactionFormMode.planned);

      final outcome = await vm.submit();

      expect(outcome, isA<TransactionFormSaveFailed>());
      expect(ledger.addedTransactions, isEmpty);
      expect(recurring.created, isEmpty,
          reason: 'the fake records nothing when it fails');
    });

    test('autoPost defaults to false, persists lastRecurringAutoPost, and applies only to repeating',
        () async {
      final prefs = PreferencesRepositoryImpl(MockSharedPreferences());
      final c1 = container(preferences: prefs);
      await c1.read(preferencesRepositoryProvider.future);

      final vm1 = form(c1);
      expect(vm1.state.autoPost, isFalse);
      expect(vm1.state.showsAutoPostRow, isFalse);

      vm1.setMode(TransactionFormMode.repeating);
      expect(vm1.state.showsAutoPostRow, isTrue);
      vm1.setAutoPost(true);
      expect(vm1.state.autoPost, isTrue);
      expect(prefs.getLastRecurringAutoPost(), isTrue);

      vm1.setAmountText('250.00');
      vm1.selectAccount('acc_cash');
      vm1.selectCategory('cat_rent');
      await vm1.submit();
      expect(recurring.created.last['autoPost'], isTrue);

      // Reopening remembers true, yet Planned still writes autoPost = false.
      final c2 = container(preferences: prefs);
      await c2.read(preferencesRepositoryProvider.future);
      final vm2 = form(c2);
      expect(vm2.state.autoPost, isTrue);
      vm2.setMode(TransactionFormMode.planned);
      expect(vm2.state.showsAutoPostRow, isFalse);
      vm2.setAmountText('120.00');
      vm2.selectAccount('acc_cash');
      vm2.selectCategory('cat_rent');
      await vm2.submit();
      expect(recurring.created.last['autoPost'], isFalse);
    });
  });

  group('attachments', () {
    test('picked files are imported with the entry, not before it', () async {
      final vm = form(container());
      vm.setAmountText('10.00');
      vm.selectAccount('acc_cash');
      vm.selectCategory('cat_rent');
      vm.attachFiles([XFile('/tmp/a.pdf'), XFile('/tmp/b.pdf')]);

      expect(store.imported, isEmpty, reason: 'nothing until Save');

      await vm.submit();

      expect(store.imported.single.map((f) => f.name), ['a.pdf', 'b.pdf']);
      expect(store.discarded, isEmpty);
      expect(
        (ledger.addedTransactions.single['attachments'] as List).length,
        2,
        reason: 'the entry refers to what was imported',
      );
    });
  });
}
