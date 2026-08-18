import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/design_system/app_text_field.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomReminderDialog extends StatefulWidget {
  const CustomReminderDialog({super.key});
  @override
  State<CustomReminderDialog> createState() => _CustomReminderDialogState();
}

class _CustomReminderDialogState extends State<CustomReminderDialog> {
  final amount = TextEditingController(text: '1');
  int multiplier = 1;
  @override
  void initState() {
    super.initState();
    amount.addListener(_changed);
  }

  void _changed() => setState(() {});
  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final value = int.tryParse(amount.text);
    final valid = value != null && value > 0 && value * multiplier <= 5256000;
    return AlertDialog(
      title: Text(l10n.reminderCustomTitle),
      content: Row(mainAxisSize: MainAxisSize.min, children: [
        Expanded(
            child: AppTextField(
                controller: amount,
                labelText: l10n.reminderAmount,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
        SizedBox(width: context.spacing.md),
        DropdownButton<int>(
            value: multiplier,
            items: [
              DropdownMenuItem(value: 1, child: Text(l10n.reminderUnitMinutes)),
              DropdownMenuItem(value: 60, child: Text(l10n.reminderUnitHours)),
              DropdownMenuItem(value: 1440, child: Text(l10n.reminderUnitDays)),
            ],
            onChanged: (value) => setState(() => multiplier = value!)),
      ]),
      actions: [
        AppButton.text(
            onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        AppButton.text(
            onPressed:
                valid ? () => Navigator.pop(context, value * multiplier) : null,
            child: Text(l10n.save)),
      ],
    );
  }
}
