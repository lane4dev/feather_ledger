import 'package:flutter/foundation.dart';

enum BudgetHintStatus {
  excludedAccount,
  pastPlanned,
  unset,
  withinBudget,
  atRisk,
  overBudget,
}

@immutable
class BudgetHintUiModel {
  final BudgetHintStatus status;
  final String primaryAmountDisplay;
  final String? secondaryAmountDisplay;

  const BudgetHintUiModel({
    required this.status,
    required this.primaryAmountDisplay,
    this.secondaryAmountDisplay,
  });
}
