import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';

import '../models/report_heatmap_ui_model.dart';
import '../providers/reports_providers.dart';

import 'heatmap_mode_dropdown.dart';
import 'report_heatmap.dart';

class ReportHeatmapView extends StatelessWidget {
  const ReportHeatmapView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                child: Text(l10n.activityHeatmap,
                    style: AppTypography.sectionTitle(context))),
            const HeatmapModeDropdown(),
          ],
        ),
        SizedBox(height: spacing.sm),
        const _HeatmapBody(),
      ],
    );
  }
}

/// Provider changes rebuild only this chart, independently of its heading,
/// mode dropdown, and the rest of the reports page.
class _HeatmapBody extends ConsumerWidget {
  const _HeatmapBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final mode = ref.watch(heatmapModeStateProvider);
    final heatmapAsync = ref.watch(heatmapDataProvider);
    final currencyCode = ref.watch(currencyControllerProvider).value ??
        AppCurrencies.defaultCurrency.code;
    final locale = Localizations.localeOf(context).toString();
    final l10n = AppLocalizations.of(context)!;
    final loading = heatmapAsync.isLoading;
    final failed = !loading && heatmapAsync.hasError;
    // A reloading provider can retain values from the previous mode. Never
    // interpret its net amounts as counts (or counts as minor units).
    final data = loading || failed
        ? const <DateTime, int>{}
        : heatmapAsync.asData?.value ?? const <DateTime, int>{};
    final model = mode == HeatmapMode.frequency
        ? const ReportHeatmapMapper().mapFrequency(
            selectedMonth: selectedDate,
            dailyCounts: data,
            locale: locale,
          )
        : const ReportHeatmapMapper().map(
            selectedMonth: selectedDate,
            dailyNetMinor: data,
            locale: locale,
            currencySymbol: AppCurrencies.getSymbol(currencyCode),
            netFlowLabel: l10n.heatmapNetFlow,
            zeroNetFlowLabel: l10n.heatmapZeroNetFlow,
          );

    return _HeatmapFrame(
      model: model,
      loading: loading,
      errorMessage:
          failed ? l10n.errorPrefix(heatmapAsync.error.toString()) : null,
    );
  }
}

/// Retains only the last calendar layout, not report data ownership. Keeping
/// it mounted reserves its exact height during delayed mode changes, including
/// narrow screens where the two legends wrap to different numbers of lines.
class _HeatmapFrame extends StatefulWidget {
  const _HeatmapFrame({
    required this.model,
    required this.loading,
    this.errorMessage,
  });

  final ReportHeatmapUiModel model;
  final bool loading;
  final String? errorMessage;

  @override
  State<_HeatmapFrame> createState() => _HeatmapFrameState();
}

class _HeatmapFrameState extends State<_HeatmapFrame> {
  late ReportHeatmapUiModel _layoutModel;

  @override
  void initState() {
    super.initState();
    _layoutModel = widget.model;
  }

  @override
  void didUpdateWidget(covariant _HeatmapFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.loading && widget.errorMessage == null) {
      _layoutModel = widget.model;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const ValueKey('report-heatmap-body'),
      alignment: Alignment.center,
      children: [
        // Keep the actual calendar layout mounted even before the first
        // result. Its height adapts to text scale and wrapped legend labels,
        // and its horizontal scroll position survives a loading transition.
        Visibility(
          visible: !widget.loading && widget.errorMessage == null,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          child: ReportHeatmap(model: _layoutModel),
        ),
        if (widget.loading)
          const Positioned.fill(
            child: Center(child: CircularProgressIndicator()),
          ),
        if (widget.errorMessage != null)
          Positioned.fill(
            child: Center(
              child: Text(widget.errorMessage!),
            ),
          ),
      ],
    );
  }
}
