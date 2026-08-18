import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/design_system/app_text_field.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/features/ledger/presentation/models/custom_recurrence.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CustomRecurrenceDialog extends StatefulWidget {
  const CustomRecurrenceDialog({super.key, required this.initial});
  final CustomRecurrence initial;
  @override
  State<CustomRecurrenceDialog> createState() => _CustomRecurrenceDialogState();
}

class _CustomRecurrenceDialogState extends State<CustomRecurrenceDialog> {
  late String frequency;
  late DateTime start;
  late DateTime end;
  late Set<int> weekdays;
  late TextEditingController interval;
  late TextEditingController count;
  late int ending;

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    frequency = r.frequency;
    start = r.startDate;
    end = r.endDate ?? start.add(const Duration(days: 90));
    weekdays = r.weekdays.isEmpty ? {start.weekday} : r.weekdays.toSet();
    interval = TextEditingController(text: '${r.interval}');
    count = TextEditingController(text: '${r.countLimit ?? 12}');
    ending = r.endDate != null
        ? 1
        : r.countLimit != null
            ? 2
            : 0;
    interval.addListener(_changed);
    count.addListener(_changed);
  }

  void _changed() => setState(() {});
  @override
  void dispose() {
    interval.dispose();
    count.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final chosen = await showDatePicker(
        context: context,
        initialDate: isStart ? start : end,
        firstDate: DateTime(1900),
        lastDate: DateTime(2100));
    if (chosen == null || !mounted) return;
    setState(() {
      if (isStart) {
        start = DateTime(
            chosen.year, chosen.month, chosen.day, start.hour, start.minute);
        if (end.isBefore(start)) end = start;
      } else {
        end = DateTime(chosen.year, chosen.month, chosen.day, 23, 59, 59);
        ending = 1;
      }
    });
  }

  Future<void> _pickTime() async {
    final chosen = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(start));
    if (chosen == null || !mounted) return;
    setState(() => start = DateTime(
        start.year, start.month, start.day, chosen.hour, chosen.minute));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat.yMMMd(l10n.localeName);
    final intValue = int.tryParse(interval.text);
    final countValue = int.tryParse(count.text);
    final valid = intValue != null &&
        intValue > 0 &&
        intValue <= 999 &&
        (frequency != 'WEEKLY' || weekdays.isNotEmpty) &&
        (ending != 2 ||
            (countValue != null && countValue > 0 && countValue <= 999)) &&
        (ending != 1 || !end.isBefore(start));
    return AlertDialog(
      title: Text(l10n.customRepeat),
      content: SingleChildScrollView(
          child: SizedBox(
              width: 360,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(l10n.repeatEvery),
                      SizedBox(width: context.spacing.sm),
                      SizedBox(
                        width: 64,
                        child: Semantics(
                          label: l10n.repeatInterval,
                          child: AppTextField(
                            key: const ValueKey('repeat-interval'),
                            controller: interval,
                            variant: AppFieldVariant.compact,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: context.spacing.sm),
                      Expanded(
                          child: DropdownButton<String>(
                        isExpanded: true,
                        value: frequency,
                        items: [
                          DropdownMenuItem(
                              value: 'DAILY', child: Text(l10n.frequencyDaily)),
                          DropdownMenuItem(
                              value: 'WEEKLY',
                              child: Text(l10n.frequencyWeekly)),
                          DropdownMenuItem(
                              value: 'MONTHLY',
                              child: Text(l10n.frequencyMonthly)),
                          DropdownMenuItem(
                              value: 'YEARLY',
                              child: Text(l10n.frequencyYearly)),
                        ],
                        onChanged: (value) =>
                            setState(() => frequency = value!),
                      )),
                    ]),
                    if (frequency == 'WEEKLY') ...[
                      SizedBox(height: context.spacing.sm),
                      Row(children: [
                        ExcludeSemantics(
                            child: Icon(LucideIcons.chevronLeft,
                                size: context.metrics.iconSize,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                        Expanded(
                          child: SingleChildScrollView(
                            key: const ValueKey('weekdays-scroll'),
                            scrollDirection: Axis.horizontal,
                            child: Row(children: [
                              for (var day = 1; day <= 7; day++) ...[
                                if (day > 1)
                                  SizedBox(width: context.spacing.xs),
                                FilterChip(
                                  key: ValueKey('weekday-$day'),
                                  label: Text(Localizations.localeOf(context)
                                              .languageCode ==
                                          'zh'
                                      ? const [
                                          '一',
                                          '二',
                                          '三',
                                          '四',
                                          '五',
                                          '六',
                                          '日'
                                        ][day - 1]
                                      : DateFormat.E(l10n.localeName)
                                          .format(DateTime(2024, 1, day))),
                                  selected: weekdays.contains(day),
                                  onSelected: (on) => setState(() {
                                    if (on) {
                                      weekdays.add(day);
                                    } else {
                                      weekdays.remove(day);
                                    }
                                  }),
                                ),
                              ],
                            ]),
                          ),
                        ),
                        ExcludeSemantics(
                            child: Icon(LucideIcons.chevronRight,
                                size: context.metrics.iconSize,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      ]),
                    ],
                    SizedBox(height: context.spacing.lg),
                    Text(l10n.repeatStart,
                        style: Theme.of(context).textTheme.titleSmall),
                    SizedBox(height: context.spacing.sm),
                    Row(children: [
                      Expanded(
                          flex: 3,
                          child: AppButton.outlined(
                            onPressed: () => _pickDate(true),
                            child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(date.format(start))),
                          )),
                      SizedBox(width: context.spacing.xs),
                      Expanded(
                          flex: 2,
                          child: AppButton.outlined(
                            onPressed: _pickTime,
                            child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(MaterialLocalizations.of(context)
                                    .formatTimeOfDay(
                                        TimeOfDay.fromDateTime(start)))),
                          )),
                    ]),
                    SizedBox(height: context.spacing.lg),
                    Text(l10n.repeatEnds,
                        style: Theme.of(context).textTheme.titleSmall),
                    RadioGroup<int>(
                      groupValue: ending,
                      onChanged: (value) => setState(() => ending = value!),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          RadioListTile<int>(
                            value: 0,
                            title: Text(l10n.repeatNeverEnds),
                            contentPadding: EdgeInsets.zero,
                          ),
                          RadioListTile<int>(
                            value: 1,
                            title: Text(l10n.repeatUntil),
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (ending == 1)
                            SizedBox(
                              width: double.infinity,
                              child: AppButton.outlined(
                                onPressed: () => _pickDate(false),
                                child: Text(date.format(end)),
                              ),
                            ),
                          Row(children: [
                            const Radio<int>(value: 2),
                            Flexible(
                                child: Text(l10n.repeatCountPrefix,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)),
                            SizedBox(width: context.spacing.xs),
                            SizedBox(
                                width: 64,
                                child: Semantics(
                                  label: l10n.repeatCount,
                                  child: AppTextField(
                                    key: const ValueKey('repeat-count'),
                                    controller: count,
                                    variant: AppFieldVariant.compact,
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    onChanged: (_) =>
                                        setState(() => ending = 2),
                                  ),
                                )),
                            SizedBox(width: context.spacing.xs),
                            Flexible(
                                child: Text(l10n.repeatCountSuffix,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)),
                          ]),
                        ],
                      ),
                    ),
                  ]))),
      actions: [
        AppButton.text(
            onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        AppButton.text(
            onPressed: valid
                ? () => Navigator.pop(
                    context,
                    CustomRecurrence(
                      frequency: frequency,
                      interval: intValue,
                      startDate: start,
                      weekdays: frequency == 'WEEKLY'
                          ? (weekdays.toList()..sort())
                          : const [],
                      endDate: ending == 1 ? end : null,
                      countLimit: ending == 2 ? countValue : null,
                    ))
                : null,
            child: Text(l10n.save)),
      ],
    );
  }
}
