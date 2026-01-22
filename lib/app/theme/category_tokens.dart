import 'package:flutter/material.dart';

class CategoryTokens {
  // Prevent instantiation
  const CategoryTokens._();

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

  /// Predefined Material Icon code points for user categories
  static List<int> defaultIcons = [
    Icons.restaurant.codePoint, // restaurant (Food)
    Icons.shopping_cart.codePoint, // shopping_cart (Shopping)
    Icons.commute.codePoint, // commute (Transport)
    Icons.home.codePoint, // home (Housing)
    Icons.movie.codePoint, // movie (Entertainment)
    Icons.local_hospital.codePoint, // local_hospital (Medical)
    Icons.school.codePoint, // school (Education)
    Icons.payments.codePoint, // payments (Salary/Income)
    Icons.savings.codePoint, // savings (Piggy bank/Savings)
    Icons.local_gas_station.codePoint, // local_gas_station (Fuel)
    Icons.shopping_bag.codePoint, // shopping_bag (Groceries/Clothing)
    Icons.electric_bolt.codePoint, // electric_bolt (Bills/Utilities)
    Icons.checkroom.codePoint, // checkroom (Clothing)
    Icons.computer.codePoint, // computer (Digital/Electronics)
    Icons.sports_esports.codePoint, // sports_esports (Gaming)
    Icons.local_cafe.codePoint, // local_cafe (Coffee)
    Icons.redeem.codePoint, // redeem (Gifts)
    Icons.trending_up.codePoint, // trending_up (Investment)
    Icons.pets.codePoint, // pets (Pets)
    Icons.receipt_long.codePoint, // receipt_long (General Bills)
    Icons.account_balance_wallet.codePoint, // account_balance_wallet (Ledger)
    Icons.flight.codePoint, // flight (Travel)
    Icons.fitness_center.codePoint, // fitness_center (Fitness)
    Icons.phone_iphone.codePoint, // phone_iphone (Mobile/Communication)
    Icons.work.codePoint, // work (Freelance/Business)
    Icons.card_membership.codePoint, // card_membership (Subscriptions)
    Icons.volunteer_activism.codePoint, // volunteer_activism (Charity)
    Icons.build.codePoint, // build (Maintenance)
    Icons.card_giftcard.codePoint, // card_giftcard (Gifts)
    Icons.attach_money.codePoint, // attach_money (Money)
    Icons.chair.codePoint, // chair (Furniture)
    Icons.class_.codePoint, // class_ (Education)
    Icons.coffee.codePoint, // coffee (Coffee)
    Icons.construction.codePoint, // construction (Construction)
    Icons.duo.codePoint, // duo (Communication)
  ];
}
