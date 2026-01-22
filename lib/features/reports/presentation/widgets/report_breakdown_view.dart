import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';

import '../../domain/reports_entities.dart';

class ReportBreakdownView extends StatefulWidget {
  final AsyncValue<List<ReportCategoryTotal>> dataAsync;
  final String emptyMessage;

  const ReportBreakdownView({
    super.key,
    required this.dataAsync,
    required this.emptyMessage,
  });

  @override
  State<ReportBreakdownView> createState() => _ReportBreakdownViewState();
}

class _ReportBreakdownViewState extends State<ReportBreakdownView> {
  int touchedIndex = -1;

  Color _getTonalColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation((hsl.saturation * 0.4).clamp(0.0, 1.0))
        .withLightness((hsl.lightness * 1.1).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    return widget.dataAsync.when(
      data: (data) {
        if (data.isEmpty) {
          return Center(child: Text(widget.emptyMessage));
        }

        final sorted = List<ReportCategoryTotal>.from(data)
          ..sort((a, b) => b.total.compareTo(a.total));

        final processedData = <ReportCategoryTotal>[];
        if (sorted.length <= 5) {
          processedData.addAll(sorted);
        } else {
          processedData.addAll(sorted.take(5));
          final otherTotal =
              sorted.skip(5).fold(0.0, (sum, item) => sum + item.total);
          processedData.add(ReportCategoryTotal(
            category: CategoryEntity(
              id: -1,
              name: 'Others',
              iconKey: '57564',
              colorInt: Colors.grey.toARGB32(),
              type: sorted.first.category.type,
              isDefault: false,
            ),
            total: otherTotal,
          ));
        }

        final totalSum = data.fold(0.0, (sum, item) => sum + item.total);

        return Column(
          children: [
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        return;
                      }
                      if (event is FlTapUpEvent) {
                        setState(() {
                          final index = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                          if (touchedIndex == index) {
                            touchedIndex = -1;
                          } else {
                            touchedIndex = index;
                          }
                        });
                      }
                    },
                  ),
                  sections: processedData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isTouched = index == touchedIndex;
                    final percentage =
                        totalSum > 0 ? (item.total / totalSum * 100) : 0.0;
                    final color = _getTonalColor(Color(item.category.colorInt));

                    return PieChartSectionData(
                      color: isTouched ? Color(item.category.colorInt) : color,
                      value: item.total,
                      title: '${percentage.toStringAsFixed(0)}%',
                      radius: isTouched ? 55 : 45,
                      titleStyle:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: isTouched ? 14 : 10,
                              ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 35,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: processedData.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = processedData[index];
                  final isTouched = index == touchedIndex;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (touchedIndex == index) {
                          touchedIndex = -1;
                        } else {
                          touchedIndex = index;
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isTouched
                            ? Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.3)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: isTouched
                                  ? Color(item.category.colorInt)
                                  : _getTonalColor(
                                      Color(item.category.colorInt)),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.category.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: isTouched
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '\$${item.total.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: isTouched
                                      ? FontWeight.bold
                                      : FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}
