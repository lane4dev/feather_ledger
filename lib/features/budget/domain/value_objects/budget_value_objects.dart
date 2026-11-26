import 'package:flutter/foundation.dart';

/// Calendar month identifier `(year, month)` encoded as `year * 100 + month`.
@immutable
class YearMonth implements Comparable<YearMonth> {
  final int year;
  final int month;

  const YearMonth(this.year, this.month)
      : assert(month >= 1 && month <= 12, 'month must be in 1..12');

  factory YearMonth.fromYm(int ym) => YearMonth(ym ~/ 100, ym % 100);

  factory YearMonth.fromDate(DateTime date) => YearMonth(date.year, date.month);

  int get ym => year * 100 + month;

  YearMonth get previous => addMonths(-1);
  YearMonth get next => addMonths(1);

  YearMonth addMonths(int delta) {
    final total = (year * 12 + (month - 1)) + delta;
    final newYear = total >= 0 ? total ~/ 12 : ((total - 11) ~/ 12);
    final newMonth = (total - newYear * 12) + 1;
    return YearMonth(newYear, newMonth);
  }

  int monthsUntil(YearMonth other) =>
      (other.year - year) * 12 + (other.month - month);

  DateTime toDateTime() => DateTime(year, month, 1);

  @override
  int compareTo(YearMonth other) => ym.compareTo(other.ym);

  bool operator <(YearMonth other) => ym < other.ym;
  bool operator <=(YearMonth other) => ym <= other.ym;
  bool operator >(YearMonth other) => ym > other.ym;
  bool operator >=(YearMonth other) => ym >= other.ym;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is YearMonth && other.ym == ym);

  @override
  int get hashCode => ym.hashCode;

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}';
}

/// Scope for editing or clearing a category budget rule.
enum BudgetEditScope {
  thisMonthOnly,
  thisAndFollowing,
}

/// Adaptive cockpit mode determined by comparing target month against today.
enum BudgetMode {
  plan,
  track,
  review,
}

/// Compliance & risk status for a category that has an active budget.
enum BudgetRiskLevel {
  none,
  inBudget,
  atRisk,
  overBudget,
}

/// Signed budget variance defined as `budgetMinor - actualMinor`.
/// Positive means under budget / remaining; negative means overspent.
@immutable
class BudgetVariance {
  final int varianceMinor;

  const BudgetVariance(this.varianceMinor);

  bool get isOver => varianceMinor < 0;
  int get absMinor => varianceMinor.abs();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetVariance && other.varianceMinor == varianceMinor);

  @override
  int get hashCode => varianceMinor.hashCode;
}

/// One point in a 6-month `[M-5 .. M]` trend series.
@immutable
class BudgetTrendPoint {
  final YearMonth month;
  final int? budgetMinor;
  final int actualMinor;
  final int pendingMinor;
  final bool hasReviewNote;

  const BudgetTrendPoint({
    required this.month,
    required this.budgetMinor,
    required this.actualMinor,
    required this.pendingMinor,
    required this.hasReviewNote,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetTrendPoint &&
          other.month == month &&
          other.budgetMinor == budgetMinor &&
          other.actualMinor == actualMinor &&
          other.pendingMinor == pendingMinor &&
          other.hasReviewNote == hasReviewNote);

  @override
  int get hashCode => Object.hash(
        month,
        budgetMinor,
        actualMinor,
        pendingMinor,
        hasReviewNote,
      );
}

/// Top contributing posted transaction or pending bill shown in drill-down.
@immutable
class BudgetContributionTx {
  final String transactionId;
  final String? sourceScheduledBillId;
  final String? scheduledBillId;
  final String? seriesId;
  final String? occurrenceKey;
  final bool isVirtual;
  final String description;
  final DateTime occurredAt;
  final int amountMinor;
  final bool isPending;
  final String accountName;

  const BudgetContributionTx({
    required this.transactionId,
    required this.sourceScheduledBillId,
    required this.scheduledBillId,
    this.seriesId,
    this.occurrenceKey,
    this.isVirtual = false,
    required this.description,
    required this.occurredAt,
    required this.amountMinor,
    required this.isPending,
    this.accountName = '',
  });

  bool get isCommitted => isPending || sourceScheduledBillId != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetContributionTx &&
          other.transactionId == transactionId &&
          other.sourceScheduledBillId == sourceScheduledBillId &&
          other.scheduledBillId == scheduledBillId &&
          other.seriesId == seriesId &&
          other.occurrenceKey == occurrenceKey &&
          other.isVirtual == isVirtual &&
          other.description == description &&
          other.occurredAt == occurredAt &&
          other.amountMinor == amountMinor &&
          other.isPending == isPending &&
          other.accountName == accountName);

  @override
  int get hashCode => Object.hash(
        transactionId,
        sourceScheduledBillId,
        scheduledBillId,
        seriesId,
        occurrenceKey,
        isVirtual,
        description,
        occurredAt,
        amountMinor,
        isPending,
        accountName,
      );
}
