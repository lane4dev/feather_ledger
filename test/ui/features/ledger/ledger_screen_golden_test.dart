import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feather_ledger/features/ledger/presentation/screens/ledger_screen.dart';

void main() {
  testWidgets('LedgerScreen renders correctly', (tester) async {
    // Basic smoke test since Golden Toolkit setup might be missing
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LedgerScreen(),
        ),
      ),
    );

    expect(find.byType(LedgerScreen), findsOneWidget);
    // Add more expectations here
  });
}
