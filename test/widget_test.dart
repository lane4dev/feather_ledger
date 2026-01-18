import 'package:feather_ledger/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We need to wrap with ProviderScope for testing
    await tester.pumpWidget(const ProviderScope(child: FeatherLedgerApp()));

    // Verify that our title is not present (since it's in AppBar and we need to navigate)
    // Actually, just verify it builds without crashing.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}