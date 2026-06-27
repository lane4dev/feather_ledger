import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/presentation/screens/recurring_list_screen.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/recurring_view_model.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/recurring_view_state.dart';

/// The recurring screen (spec 004, US2 / T042).
///
/// The view model is stubbed so the screen can be driven without a database
/// — the write path itself is covered against real services in
/// `recurring_series_test.dart`. What is left for this layer is the to-do
/// list and the confirmations around it.
void main() {
  late _FakeRecurringViewModel viewModel;

  setUp(() => viewModel = _FakeRecurringViewModel());

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recurringViewModelProvider.overrideWith(() => viewModel),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: const RecurringListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows an empty state when nothing is due or configured',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('Recurring bills'), findsOneWidget);
    expect(find.text('Nothing due right now'), findsOneWidget);
    expect(find.text('No recurring bills yet'), findsOneWidget);
  });

  testWidgets('lists due instances and posts one after confirming',
      (tester) async {
    viewModel.due = [
      _instance(id: 'due_1', description: 'Rent'),
    ];
    await pumpScreen(tester);

    expect(find.text('Rent'), findsOneWidget);
    expect(find.text('Post'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();

    // Posting moves money, so it asks first.
    expect(find.text('Record this bill'), findsOneWidget);
    // Scoped to the dialog: the row behind it has a "Post" button too.
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(TextButton, 'Post'),
    ));
    await tester.pumpAndSettle();

    expect(viewModel.posted, ['due_1']);
    expect(find.text('Bill recorded'), findsOneWidget);
  });

  testWidgets('cancelling the post confirmation posts nothing', (tester) async {
    viewModel.due = [_instance(id: 'due_1', description: 'Rent')];
    await pumpScreen(tester);

    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(TextButton, 'Cancel'),
    ));
    await tester.pumpAndSettle();

    expect(viewModel.posted, isEmpty);
  });

  testWidgets('skipping asks nothing and reports back', (tester) async {
    viewModel.due = [_instance(id: 'due_1', description: 'Rent')];
    await pumpScreen(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // No dialog: skipping writes no event and moves no money.
    expect(find.text('Record this bill'), findsNothing);
    expect(viewModel.skipped, ['due_1']);
    expect(find.text('Bill skipped'), findsOneWidget);
  });

  testWidgets('lists series and deactivates one after confirming',
      (tester) async {
    viewModel.series = [_series(id: 'series_1', description: 'Rent')];
    await pumpScreen(tester);

    expect(find.text('Rent'), findsOneWidget);
    expect(find.text('Every month'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deactivate').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('already created are kept'), findsOneWidget);
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(TextButton, 'Deactivate'),
    ));
    await tester.pumpAndSettle();

    expect(viewModel.deactivated, ['series_1']);
  });

  testWidgets('reports a rejected write with its localized message',
      (tester) async {
    viewModel.due = [_instance(id: 'due_1', description: 'Rent')];
    viewModel.writeFailure = LedgerErrorCode.scheduledAlreadyPosted;
    await pumpScreen(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('This scheduled transaction was already posted'),
        findsOneWidget);
  });
}

ScheduledTransactionEntity _instance({
  required String id,
  required String description,
}) =>
    ScheduledTransactionEntity(
      id: id,
      seriesId: 'series_1',
      date: DateTime(2026, 1, 1),
      amountMinor: 50000,
      recurringTransactionSeries: _series(
        id: 'series_1',
        description: description,
      ),
    );

RecurringTransactionSeriesEntity _series({
  required String id,
  required String description,
}) =>
    RecurringTransactionSeriesEntity(
      id: id,
      description: description,
      amountMinor: 50000,
      type: RecurringSeriesKind.expense,
      categoryId: 'cat_1',
      accountId: 'acc_1',
      frequency: 'MONTHLY',
      interval: 1,
      startDate: DateTime(2026, 1, 1),
    );

class _FakeRecurringViewModel extends RecurringViewModel {
  List<ScheduledTransactionEntity> due = [];
  List<RecurringTransactionSeriesEntity> series = [];

  /// When set, every write fails with this code — the screen must render it
  /// through the localizer rather than showing the raw enum name.
  LedgerErrorCode? writeFailure;

  final List<String> posted = [];
  final List<String> skipped = [];
  final List<String> deactivated = [];

  /// Overridden so the real one's stream subscriptions never start. Reads
  /// the fields the test set before pumping, and resolves them rather than
  /// leaving `AsyncLoading` — a permanently-loading section would spin an
  /// indeterminate indicator and `pumpAndSettle` would never settle.
  @override
  RecurringViewState build() => RecurringViewState(
        scheduled: AsyncData(due),
        series: AsyncData(series),
      );

  @override
  List<ScheduledTransactionEntity> dueNow() => due;

  @override
  Future<Result<void>> postInstance(String scheduledId) async {
    final failure = writeFailure;
    if (failure != null) return Failure(failure, 'rejected');
    posted.add(scheduledId);
    return unitResult;
  }

  @override
  Future<Result<void>> skipInstance(String scheduledId) async {
    final failure = writeFailure;
    if (failure != null) return Failure(failure, 'rejected');
    skipped.add(scheduledId);
    return unitResult;
  }

  @override
  Future<Result<void>> deactivateSeries(String seriesId,
      {required DateTime endDate}) async {
    deactivated.add(seriesId);
    return unitResult;
  }
}
