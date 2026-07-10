import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';

import '../../domain/entities/reports_entities.dart';
import '../models/report_breakdown_ui_model.dart';

class ReportBreakdownView extends ConsumerStatefulWidget {
  final AsyncValue<List<ReportCategoryTotal>> dataAsync;
  final String emptyMessage;

  const ReportBreakdownView({
    super.key,
    required this.dataAsync,
    required this.emptyMessage,
  });

  @override
  ConsumerState<ReportBreakdownView> createState() =>
      _ReportBreakdownViewState();
}

class _ReportBreakdownViewState extends ConsumerState<ReportBreakdownView> {
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
    final l10n = AppLocalizations.of(context)!;
    // This widget draws. The sorting, the others bucket and every amount's
    // written form were done above it — see [ReportBreakdownMapper].
    final currencyKey = ref.watch(currencyControllerProvider).value ??
        AppCurrencies.supportedCurrencyCodes.first;
    final currencySymbol = AppCurrencies.getSymbol(currencyKey);
    return widget.dataAsync.when(
      data: (data) {
        if (data.isEmpty) {
          return Center(child: Text(widget.emptyMessage));
        }

        final processedData = const ReportBreakdownMapper().toItems(
          data,
          currencySymbol: currencySymbol,
          othersLabel: l10n.others,
          othersColorInt: Colors.grey.toARGB32(),
        );

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
                    final color = _getTonalColor(Color(item.colorInt));

                    return PieChartSectionData(
                      color: isTouched ? Color(item.colorInt) : color,
                      value: item.chartValue,
                      title: item.displayShare,
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
                                  ? Color(item.colorInt)
                                  : _getTonalColor(Color(item.colorInt)),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.label,
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
                            item.displayTotal,
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
      error: (e, s) => Center(child: Text(l10n.errorPrefix(e.toString()))),
    );
  }
}
