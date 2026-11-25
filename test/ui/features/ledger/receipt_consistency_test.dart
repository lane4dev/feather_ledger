import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/design_system/app_bottom_action_bar.dart';
import 'package:feather_ledger/app/design_system/app_receipt_sheet.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/domain/queries/get_transaction_history_query.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/pending_bill_sheet.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/transaction_detail_sheet.dart';

void main() {
  for (final dark in [false, true]) {
    for (final locale in [
      const Locale('en'),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
    ]) {
      testWidgets(
          'receipts share presentation and keep distinct actions ($dark, $locale)',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 740);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final historyReads = <String>[];
        TextStyle? recordedAmountStyle;
        Offset? recordedEditPosition;
        double? recordedWidth;

        for (final pending in [false, true]) {
          historyReads.clear();
          final model = TransactionTileUiModel(
            id: pending ? 'scheduled' : 'recorded',
            amount: 123456,
            type: TransactionKind.expense,
            date: DateTime(2026, 11, 1, 9),
            note: List.filled(80, 'A long note that must scroll.').join(' '),
            category: const CategoryEntity(
                id: 'food',
                name: 'Food',
                iconKey: '1',
                colorInt: 0xFF5C7A93,
                type: CategoryType.expense),
            account: const AccountEntity(
                id: 'eur',
                name: 'Everyday',
                type: AccountType.cash,
                currencyCode: 'EUR',
                balanceMinor: 0,
                archived: false,
                lastUpdatedEventId: 0),
            displayAmount: '1234.56',
            displaySign: '-',
            isPending: pending,
          );
          await tester.pumpWidget(ProviderScope(
            key: ValueKey(pending),
            overrides: [
              displayCurrencySymbolProvider.overrideWithValue('¥'),
              getTransactionHistoryProvider.overrideWith((ref, id) async {
                historyReads.add(id);
                return const [];
              }),
            ],
            child: MaterialApp(
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(1.6)),
                  child: child!),
              home: Builder(
                  builder: (context) => Scaffold(
                          body: TextButton(
                        onPressed: () => showAppReceiptSheet<void>(
                            context: context,
                            builder: (context) => pending
                                ? PendingBillSheet(transaction: model)
                                : TransactionDetailSheet(
                                    transaction: model, currencySymbol: '€')),
                        child: const Text('Open'),
                      ))),
            ),
          ));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();

          final surface = find
              .descendant(
                  of: find.byType(AppReceiptSheet),
                  matching: find.byType(PhysicalShape))
              .first;
          final rect = tester.getRect(surface);
          final amountStyle =
              tester.widget<Text>(find.text('-€1234.56')).style;
          final editPosition =
              tester.getCenter(find.byIcon(LucideIcons.squarePen)) -
                  rect.topLeft;
          final l10n = AppLocalizations.of(
              tester.element(find.byType(AppReceiptSheet)))!;
          expect(rect.height, lessThanOrEqualTo(740 * 0.9));
          final expectedDate = locale.languageCode == 'en'
              ? 'November 1, 2026 09:00'
              : '2026年11月1日 09:00';
          expect(find.text(expectedDate), findsOneWidget);
          expect(find.byIcon(LucideIcons.x).hitTestable(), findsOneWidget);
          if (pending) {
            expect(amountStyle, recordedAmountStyle);
            expect(rect.width, recordedWidth);
            expect(editPosition, recordedEditPosition);
            expect(find.text(l10n.pendingBill), findsOneWidget);
            expect(find.text(l10n.postInstance).hitTestable(), findsOneWidget);
            expect(find.byType(AppBottomActionBar), findsOneWidget);
            expect(find.byKey(const ValueKey('transaction-barcode')),
                findsNothing);
            expect(historyReads, isEmpty,
                reason: 'pending bills have no recorded transaction history');
          } else {
            recordedAmountStyle = amountStyle;
            recordedEditPosition = editPosition;
            recordedWidth = rect.width;
            expect(historyReads, contains(model.id));
            expect(find.byKey(const ValueKey('transaction-barcode')),
                findsOneWidget);
          }
          expect(tester.takeException(), isNull);
          Navigator.of(tester.element(find.byType(AppReceiptSheet))).pop();
          await tester.pumpAndSettle();
        }
      });
    }
  }
}
