import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/reports/domain/entities/reports_entities.dart';
import 'package:feather_ledger/features/reports/presentation/models/report_breakdown_ui_model.dart';

/// The breakdown chart's slices (spec 003, US9).
///
/// Sorting, the top-five cut, the "others" bucket and every printed form used
/// to happen inside the chart widget. The bucket is a sum, so the widget was
/// doing money arithmetic to draw itself a label.
void main() {
  const mapper = ReportBreakdownMapper();

  ReportCategoryTotal total(String name, int minor) => ReportCategoryTotal(
        category: CategoryEntity(
          id: 'cat_$name',
          name: name,
          iconKey: '1',
          colorInt: 0xFF112233,
          type: CategoryType.expense,
        ),
        totalMinor: minor,
      );

  List<ReportBreakdownItem> items(List<ReportCategoryTotal> totals) =>
      mapper.toItems(
        totals,
        currencySymbol: r'$',
        othersLabel: 'Others',
        othersColorInt: 0xFF888888,
      );

  test('the biggest category leads', () {
    // Categories arrive as magnitudes, so "descending" is biggest first. Fed
    // signed expense totals this sorted the other way round, which put the
    // smallest slice at the head of the pie and cut the wrong end of the list.
    final result = items([total('Small', 1000), total('Big', 900000)]);

    expect(result.map((i) => i.label), ['Big', 'Small']);
    expect(result.first.displayTotal, r'$9000.00');
  });

  test('a slice is never negative, because a pie cannot draw one', () {
    final result = items([total('Food', 5000), total('Rent', 90000)]);

    expect(result.every((i) => i.chartValue > 0), isTrue);
    expect(result.every((i) => !i.displayTotal.contains('-')), isTrue);
  });

  test('the five kept are the five biggest', () {
    final result = items([
      total('A', 700),
      total('B', 600),
      total('C', 500),
      total('D', 400),
      total('E', 300),
      total('F', 200),
      total('G', 100),
    ]);

    expect(result.take(5).map((i) => i.label), ['A', 'B', 'C', 'D', 'E']);
    expect(result.last.label, 'Others',
        reason: 'the two smallest were folded, not the two biggest');
  });

  test('folds everything past the fifth into one bucket', () {
    final result = items([
      for (var i = 7; i >= 1; i--) total('C$i', i * 100),
    ]);

    expect(result, hasLength(6), reason: 'five plus the bucket');
    expect(result.last.label, 'Others');
    // 200 + 100 = the two smallest, summed here rather than in the widget.
    expect(result.last.displayTotal, r'$3.00');
    // 300 of the 2800 total, so the bucket's share is of everything.
    expect(result.last.displayShare, '11%');
  });

  test('no bucket when there is nothing to fold', () {
    final result = items([for (var i = 3; i >= 1; i--) total('C$i', i * 100)]);

    expect(result.map((i) => i.label), ['C3', 'C2', 'C1']);
  });

  test('the share is of the whole, including the bucket', () {
    final result = items([total('Half', 500), total('Quarter', 250)]);

    expect(result.first.displayShare, '67%');
    expect(result.last.displayShare, '33%');
  });

  test('an all-zero report says nothing rather than dividing by zero', () {
    final result = items([total('Nothing', 0)]);

    expect(result.single.displayShare, '');
    expect(result.single.chartValue, 0);
  });
}
