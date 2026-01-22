import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/ledger_theme.dart';

class TimeAnchor extends StatelessWidget {
  final DateTime date;

  const TimeAnchor({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    // Format: "20" (Day) and "Mon" (Weekday)
    // We can use DateFormat from intl package
    final dayStr = DateFormat('d').format(date);
    final wdayStr =
        DateFormat('E').format(date); // 'E' is short weekday (Mon, Tue)

    return SizedBox(
      width: LedgerTheme.colAnchorWidth,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayStr,
              style: LedgerTheme.anchorDayText(context),
            ),
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
