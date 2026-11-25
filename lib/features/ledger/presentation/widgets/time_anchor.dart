import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/ledger_theme.dart';

class TimeAnchor extends StatelessWidget {
  final DateTime date;
  final DateTime? today;

  const TimeAnchor({
    super.key,
    required this.date,
    this.today,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final dayStr = DateFormat('d', locale).format(date);
    final wdayStr = DateFormat('E', locale).format(date);
    final scheme = Theme.of(context).colorScheme;
    final now = today ?? DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    return SizedBox(
      width: LedgerTheme.colAnchorWidth,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isToday)
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  dayStr,
                  style: LedgerTheme.anchorDayText(context).copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              )
            else
              SizedBox(
                height: 32,
                child: Center(
                  child: Text(
                    dayStr,
                    style: LedgerTheme.anchorDayText(context).copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 2),
            Text(
              wdayStr,
              style: LedgerTheme.anchorWeekdayText(context),
            ),
          ],
        ),
      ),
    );
  }
}
