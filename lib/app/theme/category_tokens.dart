import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CategoryTokens {
  // Prevent instantiation
  const CategoryTokens._();

  /// Colour a new category starts on. Must appear in [defaultColors] so the
  /// swatch grid shows it as the current selection.
  static const Color defaultColor = Colors.blue;

  /// Predefined colors for user categories
  static const List<Color> defaultColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
  ];

  /// The category-icon palette: **(what v1 stored, what v2 stores)**.
  ///
  /// One list rather than two, because the icon a user picks and the icon an
  /// older event is translated into are the same choice — two lists would be
  /// two chances to disagree. Order is load-bearing: `seeder.dart` seeds the
  /// built-ins by index.
  // `final`, not `const`: reading `.codePoint` is not a constant expression.
  static final List<({int legacy, int current})> _palette = [
    (legacy: Icons.restaurant.codePoint, current: LucideIcons.utensils.codePoint),
    (legacy: Icons.shopping_cart.codePoint, current: LucideIcons.shoppingCart.codePoint),
    (legacy: Icons.commute.codePoint, current: LucideIcons.trainFront.codePoint),
    (legacy: Icons.home.codePoint, current: LucideIcons.house.codePoint),
    (legacy: Icons.movie.codePoint, current: LucideIcons.film.codePoint),
    (legacy: Icons.local_hospital.codePoint, current: LucideIcons.hospital.codePoint),
    (legacy: Icons.school.codePoint, current: LucideIcons.graduationCap.codePoint),
    (legacy: Icons.payments.codePoint, current: LucideIcons.handCoins.codePoint),
    (legacy: Icons.savings.codePoint, current: LucideIcons.piggyBank.codePoint),
    (legacy: Icons.local_gas_station.codePoint, current: LucideIcons.fuel.codePoint),
    (legacy: Icons.shopping_bag.codePoint, current: LucideIcons.shoppingBag.codePoint),
    (legacy: Icons.electric_bolt.codePoint, current: LucideIcons.zap.codePoint),
    (legacy: Icons.checkroom.codePoint, current: LucideIcons.shirt.codePoint),
    (legacy: Icons.computer.codePoint, current: LucideIcons.monitor.codePoint),
    (legacy: Icons.sports_esports.codePoint, current: LucideIcons.gamepad2.codePoint),
    (legacy: Icons.local_cafe.codePoint, current: LucideIcons.cupSoda.codePoint),
    (legacy: Icons.redeem.codePoint, current: LucideIcons.gift.codePoint),
    (legacy: Icons.trending_up.codePoint, current: LucideIcons.trendingUp.codePoint),
    (legacy: Icons.pets.codePoint, current: LucideIcons.pawPrint.codePoint),
    (legacy: Icons.receipt_long.codePoint, current: LucideIcons.receiptText.codePoint),
    (legacy: Icons.account_balance_wallet.codePoint, current: LucideIcons.wallet.codePoint),
    (legacy: Icons.flight.codePoint, current: LucideIcons.plane.codePoint),
    (legacy: Icons.fitness_center.codePoint, current: LucideIcons.dumbbell.codePoint),
    (legacy: Icons.phone_iphone.codePoint, current: LucideIcons.smartphone.codePoint),
    (legacy: Icons.work.codePoint, current: LucideIcons.briefcase.codePoint),
    (legacy: Icons.card_membership.codePoint, current: LucideIcons.ticket.codePoint),
    (legacy: Icons.volunteer_activism.codePoint, current: LucideIcons.heartHandshake.codePoint),
    (legacy: Icons.build.codePoint, current: LucideIcons.wrench.codePoint),
    (legacy: Icons.card_giftcard.codePoint, current: LucideIcons.ticketPercent.codePoint),
    (legacy: Icons.attach_money.codePoint, current: LucideIcons.circleDollarSign.codePoint),
    (legacy: Icons.chair.codePoint, current: LucideIcons.armchair.codePoint),
    (legacy: Icons.class_.codePoint, current: LucideIcons.bookOpen.codePoint),
    (legacy: Icons.coffee.codePoint, current: LucideIcons.coffee.codePoint),
    (legacy: Icons.construction.codePoint, current: LucideIcons.hardHat.codePoint),
    (legacy: Icons.duo.codePoint, current: LucideIcons.copy.codePoint),
  ];

  /// Icon code points a new category may choose from — the current vocabulary.
  static final List<int> defaultIcons =
      _palette.map((e) => e.current).toList(growable: false);

  /// v1 code point → the v2 icon that replaced it.
  ///
  /// `CategoryCreated` v1 stored a Material code point; v2 stores a Lucide
  /// one. The upcaster registered in `register_ledger_events.dart` reads this
  /// table, so a ledger whose events predate the change rebuilds to the same
  /// icons a fresh one gets. Keys are the icons the palette *used to* offer,
  /// named rather than numbered so the table can be checked by eye.
  static final Map<int, int> legacyIconCodePoints = {
    for (final entry in _palette) entry.legacy: entry.current,
  };

  /// The glyph for a stored `iconKey`.
  ///
  /// The one place that knows which icon font the code points belong to, so
  /// the four screens that draw a category do not each name a font. The
  /// family is borrowed from the package's own constant rather than typed out.
  ///
  /// A key that does not parse — or a pre-migration code point that reached
  /// here unmapped — falls back to a neutral tag rather than to whatever
  /// glyph happens to live at that number.
  static IconData iconFor(String iconKey) {
    final codePoint = int.tryParse(iconKey);
    if (codePoint == null) return LucideIcons.tag;
    return IconData(
      codePoint,
      fontFamily: LucideIcons.tag.fontFamily,
      fontPackage: LucideIcons.tag.fontPackage,
    );
  }
}
