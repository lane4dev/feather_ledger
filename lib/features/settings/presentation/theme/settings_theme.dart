import 'package:flutter/material.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';

class SettingsTheme {
  static TextStyle accountName(BuildContext context) =>
      AppTypography.sectionTitle(context);
  static TextStyle accountBalance(BuildContext context) =>
      AppTypography.balance(context);
}
