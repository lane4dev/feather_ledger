import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/bootstrap/register_ledger_events.dart';
import 'package:feather_ledger/app/theme/category_tokens.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';

/// `CategoryCreated` v1 → v2: the app's icons moved from Material to Lucide.
///
/// A category stores its icon as a **code point**, so this is persisted data,
/// not a styling choice — and the projection is rebuilt from events, so
/// rewriting the view alone would be undone. The upcaster is what makes a
/// rebuilt ledger land on the same icons a fresh one gets.
void main() {
  setUp(registerLedgerEvents);

  Map<String, dynamic> v1(String iconKey) => {
        'schemaVersion': 1,
        'categoryId': 'cat_1',
        'name': 'Food',
        'iconKey': iconKey,
        'colorInt': 0xFF000000,
        'type': 'expense',
      };

  test('a v1 Material code point becomes its Lucide replacement', () {
    // The palette's own first entry, written the way v1 wrote it.
    final legacy = CategoryTokens.legacyIconCodePoints.keys.first;

    final upcast = ledgerEventRegistry.upcast(
      'CategoryCreated',
      v1('$legacy'),
    );

    expect(upcast['schemaVersion'], 2);
    expect(upcast['iconKey'], '${CategoryTokens.legacyIconCodePoints[legacy]}');
    expect(upcast['name'], 'Food', reason: 'only the icon field moved');
    expect(upcast['colorInt'], 0xFF000000);
  });

  test('every icon the palette used to offer maps to a current one', () {
    // The table is what stands between an old ledger and a screen full of
    // the wrong glyphs; an entry that maps nowhere is a category that changes
    // its face on upgrade.
    final current = CategoryTokens.defaultIcons.toSet();

    for (final entry in CategoryTokens.legacyIconCodePoints.entries) {
      expect(current, contains(entry.value),
          reason: 'legacy ${entry.key} maps to an icon no longer offered');
    }
    expect(CategoryTokens.legacyIconCodePoints, hasLength(35),
        reason: 'the palette has not changed size, only vocabulary');
  });

  test('a code point nobody recognises lands on a neutral glyph', () {
    // Better a tag than whatever happens to live at that number in a font
    // that has never heard of it.
    final upcast = ledgerEventRegistry.upcast('CategoryCreated', v1('999999'));

    expect(upcast['iconKey'], '${LucideIcons.tag.codePoint}');
  });

  test('an unparseable key lands there too, rather than throwing', () {
    final upcast = ledgerEventRegistry.upcast('CategoryCreated', v1('nonsense'));

    expect(upcast['iconKey'], '${LucideIcons.tag.codePoint}');
  });

  test('a v2 payload is left alone', () {
    final payload = CategoryCreated(
      categoryId: 'cat_1',
      name: 'Food',
      iconKey: '${LucideIcons.utensils.codePoint}',
      colorInt: 0xFF000000,
      type: CategoryType.expense,
    ).toJson();

    final upcast = ledgerEventRegistry.upcast('CategoryCreated', payload);

    expect(upcast['schemaVersion'], 2);
    expect(upcast['iconKey'], payload['iconKey']);
  });
}
