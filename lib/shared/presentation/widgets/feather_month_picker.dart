import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/app/design_system/app_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A premium, minimalist month picker displayed as a modal dialog.
///
/// Follows the "Google Tasks" aesthetic with clean typography and
/// simple interactions.
class FeatherMonthPicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onMonthSelected;

  const FeatherMonthPicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onMonthSelected,
  });

  /// Shows the month picker as a modal dialog.
  static Future<void> show(
    BuildContext context, {
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required ValueChanged<DateTime> onMonthSelected,
  }) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        child: FeatherMonthPicker(
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
          onMonthSelected: onMonthSelected,
        ),
      ),
    );
  }

  @override
  State<FeatherMonthPicker> createState() => _FeatherMonthPickerState();
}

class _FeatherMonthPickerState extends State<FeatherMonthPicker> {
  late PageController _pageController;
  late int _displayedYear;

  @override
  void initState() {
    super.initState();
    _displayedYear = widget.initialDate.year;
    final initialPage = _displayedYear - widget.firstDate.year;
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handlePageChanged(int page) {
    setState(() {
      _displayedYear = widget.firstDate.year + page;
    });
  }

  bool get _canGoBack => _displayedYear > widget.firstDate.year;
  bool get _canGoForward => _displayedYear < widget.lastDate.year;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat.MMM(locale);
    final yearCount = widget.lastDate.year - widget.firstDate.year + 1;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Year Selector Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppIconButton(
                onPressed: _canGoBack
                    ? () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        )
                    : null,
                icon: const Icon(LucideIcons.chevronLeft),
                tooltip: l10n.previousYear,
              ),
              Text(
                '$_displayedYear',
                style: AppTypography.balance(context),
              ),
              AppIconButton(
                onPressed: _canGoForward
                    ? () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        )
                    : null,
                icon: const Icon(LucideIcons.chevronRight),
                tooltip: l10n.nextYear,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Months PageView
          LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth;
            const crossAxisCount = 3;
            const crossAxisSpacing = 12.0;
            const mainAxisSpacing = 12.0;
            const childAspectRatio = 2.0;

            final itemWidth =
                (width - (crossAxisSpacing * (crossAxisCount - 1))) /
                    crossAxisCount;
            final itemHeight = itemWidth / childAspectRatio;
            // 4 rows of items + 3 spaces
            final gridHeight = (itemHeight * 4) + (mainAxisSpacing * 3);

            return SizedBox(
              height: gridHeight,
              child: PageView.builder(
                controller: _pageController,
                itemCount: yearCount,
                onPageChanged: _handlePageChanged,
                itemBuilder: (context, pageIndex) {
                  final year = widget.firstDate.year + pageIndex;

                  // Grid of 12 months for this specific year
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: mainAxisSpacing,
                    crossAxisSpacing: crossAxisSpacing,
                    childAspectRatio: childAspectRatio,
                    children: List.generate(12, (index) {
                      final monthDate = DateTime(year, index + 1);
                      final isSelected = year == widget.initialDate.year &&
                          index + 1 == widget.initialDate.month;
                      final isCurrentMonth = year == DateTime.now().year &&
                          index + 1 == DateTime.now().month;

                      return _MonthTile(
                        label: dateFormat.format(monthDate),
                        isSelected: isSelected,
                        isCurrentMonth: isCurrentMonth,
                        onTap: () {
                          widget.onMonthSelected(monthDate);
                          Navigator.pop(context);
                        },
                      );
                    }),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MonthTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isCurrentMonth;
  final VoidCallback onTap;

  const _MonthTile({
    required this.label,
    required this.isSelected,
    required this.isCurrentMonth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor = isSelected
        ? colorScheme.primary
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
    final foregroundColor =
        isSelected ? colorScheme.onPrimary : colorScheme.onSurface;
    final borderColor = isCurrentMonth && !isSelected
        ? colorScheme.primary
        : Colors.transparent;

    return InkWell(
      onTap: onTap,
      borderRadius: context.metrics.iconBorderRadius,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: context.metrics.iconBorderRadius,
          border: Border.all(color: borderColor, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.sectionTitle(context).copyWith(
            color: foregroundColor,
          ),
        ),
      ),
    );
  }
}
