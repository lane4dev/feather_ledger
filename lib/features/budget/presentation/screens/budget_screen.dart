import 'package:flutter/material.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.budget)),
      );
}
