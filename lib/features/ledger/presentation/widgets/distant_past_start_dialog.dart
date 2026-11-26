import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/design_system/app_text_field.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/features/ledger/domain/recurrence/distant_past_guard.dart';

/// Choice presented when a repeating rule's target start date is strictly
/// earlier than 2 calendar months before today.
///
/// Only two safe options are ever offered: skipping pre-today history or
/// backfilling a bounded number of recent days as manual-review pending bills.
enum DistantPastStartOption {
  fromToday,
  backfillRecentDays,
}

/// Confirmation dialog guarding repeating rules whose `startDate` lies more
/// than 2 calendar months in the past.
///
/// Pops the resolved `materializeFrom` [DateTime] when confirmed, or `null`
/// when cancelled.
class DistantPastStartDialog extends StatefulWidget {
  const DistantPastStartDialog({
    super.key,
    required this.startDate,
    required this.now,
  });

  final DateTime startDate;
  final DateTime now;

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime startDate,
    required DateTime now,
  }) =>
      showDialog<DateTime>(
        context: context,
        builder: (_) => DistantPastStartDialog(
          startDate: startDate,
          now: now,
        ),
      );

  @override
  State<DistantPastStartDialog> createState() => _DistantPastStartDialogState();
}

class _DistantPastStartDialogState extends State<DistantPastStartDialog> {
  DistantPastStartOption _option = DistantPastStartOption.fromToday;
  late final TextEditingController _daysController = TextEditingController(
    text: '${DistantPastStartGuard.defaultBackfillDays}',
  );

  @override
  void dispose() {
    _daysController.dispose();
    super.dispose();
  }

  int? get _parsedDays =>
      DistantPastStartGuard.parseBackfillDays(_daysController.text);

  bool get _canConfirm =>
      _option == DistantPastStartOption.fromToday || _parsedDays != null;

  void _confirm() {
    if (_option == DistantPastStartOption.fromToday) {
      Navigator.pop(
        context,
        DistantPastStartGuard.fromTodayMaterializeFrom(now: widget.now),
      );
      return;
    }
    final days = _parsedDays;
    if (days == null) return;
    Navigator.pop(
      context,
      DistantPastStartGuard.backfillDaysMaterializeFrom(
        startDate: widget.startDate,
        now: widget.now,
        days: days,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final parsedDays = _parsedDays;
    final displayDays = parsedDays ?? DistantPastStartGuard.defaultBackfillDays;
    final showDaysError =
        _option == DistantPastStartOption.backfillRecentDays &&
            parsedDays == null;

    return AlertDialog(
      title: Text(l10n.distantPastStartTitle),
      contentPadding: EdgeInsets.symmetric(
        horizontal: context.spacing.lg,
        vertical: context.spacing.md,
      ),
      content: SingleChildScrollView(
        child: RadioGroup<DistantPastStartOption>(
          groupValue: _option,
          onChanged: (value) {
            if (value != null) setState(() => _option = value);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.distantPastStartDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: context.spacing.md),
              _OptionRow(
                option: DistantPastStartOption.fromToday,
                label: l10n.distantPastOptionFromToday,
                hint: l10n.distantPastOptionFromTodayHint,
                onSelect: (value) => setState(() => _option = value),
              ),
              _OptionRow(
                option: DistantPastStartOption.backfillRecentDays,
                label: l10n.distantPastOptionBackfill(displayDays),
                hint: l10n.distantPastOptionBackfillHint,
                onSelect: (value) => setState(() => _option = value),
                extra: Padding(
                  padding: EdgeInsets.only(top: context.spacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 84,
                            child: Semantics(
                              label: l10n.distantPastBackfillDaysLabel,
                              child: Focus(
                                onFocusChange: (focused) {
                                  if (focused &&
                                      _option !=
                                          DistantPastStartOption
                                              .backfillRecentDays) {
                                    setState(
                                      () => _option = DistantPastStartOption
                                          .backfillRecentDays,
                                    );
                                  }
                                },
                                child: AppTextField(
                                  key: const ValueKey(
                                    'distant-past-backfill-days',
                                  ),
                                  controller: _daysController,
                                  variant: AppFieldVariant.compact,
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (_) => setState(
                                    () => _option = DistantPastStartOption
                                        .backfillRecentDays,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: context.spacing.sm),
                          Text(
                            l10n.distantPastBackfillDaysUnit,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      if (showDaysError) ...[
                        SizedBox(height: context.spacing.xs),
                        Text(
                          l10n.distantPastBackfillDaysError,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        AppButton.text(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        AppButton(
          onPressed: _canConfirm ? _confirm : null,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.label,
    required this.hint,
    required this.onSelect,
    this.extra,
  });

  final DistantPastStartOption option;
  final String label;
  final String hint;
  final ValueChanged<DistantPastStartOption> onSelect;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => onSelect(option),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.spacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<DistantPastStartOption>(
              value: option,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(vertical: -4),
            ),
            SizedBox(width: context.spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodyLarge),
                  Text(
                    hint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  if (extra != null) extra!,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
