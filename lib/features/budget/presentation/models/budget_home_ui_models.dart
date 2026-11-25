import 'package:flutter/foundation.dart';

import 'budget_ui_models.dart';

/// What the home's single review entry has to say about the month.
///
/// The words in front of the amount are a localizable resource, so the model
/// names the meaning and the widget resolves it — the same split as
/// [BudgetCategoryAmountLabel]. The amounts and names arrive ready to print.
enum BudgetReviewEntryKind {
  /// A category ended over its limit. The strongest reason to read L2, so it
  /// outranks any surplus.
  overrun,

  /// Nothing is over, so the largest unspent category.
  surplus,

  /// Neither: the month is level, or nothing is budgeted yet. The entry still
  /// opens L2.
  quiet,
}

/// The one-line summary behind the review entry, and the note preview beside
/// it.
///
/// Track and review months share this model: one entry each, and the entry is
/// the only way into L2 besides the category rows.
@immutable
class BudgetReviewEntryUiModel {
  final BudgetReviewEntryKind kind;

  /// The category the summary names; null when [kind] is
  /// [BudgetReviewEntryKind.quiet].
  final String? categoryName;

  /// The overrun or surplus amount, already formatted with its currency
  /// symbol.
  final String? amountDisplay;

  /// A one-line month-note preview, collapsed and shortened; null when the
  /// month has no note.
  final String? notePreview;

  const BudgetReviewEntryUiModel({
    required this.kind,
    this.categoryName,
    this.amountDisplay,
    this.notePreview,
  });

  /// Reads the entry off the month's already-sorted attribution lists.
  ///
  /// Both top-3 lists are computed for every mode by the domain calculator, so
  /// the same rule holds for a tracked month that already overspent one
  /// category and for a closed month.
  factory BudgetReviewEntryUiModel.from(
    BudgetScreenUiModel screen, {
    int notePreviewLength = 40,
  }) {
    final notePreview = _preview(screen.monthReviewNote, notePreviewLength);
    final overrun = screen.overBudgetTop3.isEmpty
        ? null
        : screen.overBudgetTop3.first;
    if (overrun != null) {
      return BudgetReviewEntryUiModel(
        kind: BudgetReviewEntryKind.overrun,
        categoryName: overrun.name,
        amountDisplay: overrun.deltaDisplay,
        notePreview: notePreview,
      );
    }
    final surplus = screen.underBudgetTop3.isEmpty
        ? null
        : screen.underBudgetTop3.first;
    if (surplus != null) {
      return BudgetReviewEntryUiModel(
        kind: BudgetReviewEntryKind.surplus,
        categoryName: surplus.name,
        amountDisplay: surplus.deltaDisplay,
        notePreview: notePreview,
      );
    }
    return BudgetReviewEntryUiModel(
      kind: BudgetReviewEntryKind.quiet,
      notePreview: notePreview,
    );
  }

  /// Notes are free text with line breaks; the entry shows one line of it, so
  /// the preview is collapsed first and cut on a word boundary.
  static String? _preview(String? note, int maxChars) {
    final collapsed = note?.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed == null || collapsed.isEmpty) return null;
    if (collapsed.length <= maxChars) return collapsed;
    final cut = collapsed.substring(0, maxChars);
    final lastSpace = cut.lastIndexOf(' ');
    final kept = lastSpace > maxChars ~/ 2 ? cut.substring(0, lastSpace) : cut;
    return '${kept.trimRight()}…';
  }
}

/// One clause of the plan month's single-line planning hint.
enum BudgetPlanHintPart {
  /// Last month's rules are still in force for this month.
  carryForward,

  /// The fixed bills already materialised into the month.
  fixedBills,

  /// Nothing is scheduled yet, so the month holds no commitments.
  noBillsYet,
}

/// The plan month's replacement for the review entry.
///
/// A future month has nothing to review, so the last slot of the page says
/// what is already committed instead. "Carry forward" is only claimed when it
/// can be read off the data — see [_carriesLastMonthRules].
@immutable
class BudgetPlanHintUiModel {
  final List<BudgetPlanHintPart> parts;

  /// The fixed bills of the month, already formatted with its symbol.
  final String fixedBillsDisplay;

  /// Whether the month's pending money is only materialised bills, which is
  /// worth naming under the hint.
  final bool showMaterializedHint;

  const BudgetPlanHintUiModel({
    required this.parts,
    required this.fixedBillsDisplay,
    required this.showMaterializedHint,
  });

  factory BudgetPlanHintUiModel.from(BudgetScreenUiModel screen) {
    final carriesLastMonthRules = _carriesLastMonthRules(screen);
    final hasFixedBills = screen.overview.hasFixedBaseline;
    return BudgetPlanHintUiModel(
      parts: [
        if (carriesLastMonthRules) BudgetPlanHintPart.carryForward,
        if (hasFixedBills)
          BudgetPlanHintPart.fixedBills
        else if (!carriesLastMonthRules)
          BudgetPlanHintPart.noBillsYet,
      ],
      fixedBillsDisplay: screen.overview.committedBaselineDisplay,
      showMaterializedHint:
          screen.overview.hasHighFrequencyMaterializationHint,
    );
  }

  /// Whether this month's limits are simply last month's.
  ///
  /// Budget rules carry forward silently, so the only honest evidence is the
  /// data: every category's last-month budget point has to equal the limit the
  /// row shows for this month. A re-planned category breaks the equality; an
  /// unknown last month (a brand new currency, say) breaks it too, and the
  /// hint then says nothing about carrying forward.
  static bool _carriesLastMonthRules(BudgetScreenUiModel screen) {
    if (screen.budgetedRows.isEmpty) return false;
    final lastMonth = screen.overview.targetYm.previous;
    final rows = [
      ...screen.budgetedRows,
      ...screen.unbudgetedActiveRows,
      ...screen.remainingActiveRows,
    ];
    for (final row in rows) {
      int? lastMonthBudget;
      var found = false;
      for (final point in row.trend6Months) {
        if (point.ym == lastMonth) {
          lastMonthBudget = point.budgetMinor;
          found = true;
          break;
        }
      }
      if (!found || lastMonthBudget != row.budgetMinor) return false;
    }
    return true;
  }
}
