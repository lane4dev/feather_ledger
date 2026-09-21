import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:flutter/material.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';

import '../../domain/entities/ledger_entities.dart';

/// Picks how far an edit or a delete reaches. Pops the chosen
/// [RecurringScope], or null when cancelled.
///
/// Both actions ask the same question with the same three answers — they name
/// how much of the series is affected, which is the one thing the user knows
/// and the row does not.
class RecurringScopeDialog extends StatefulWidget {
  const RecurringScopeDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    this.destructive = false,
    this.unavailable = const {},
    this.unavailableHint,
  });

  final String title;
  final String confirmLabel;
  final bool destructive;

  /// Scopes this edit cannot be applied at, because the change would have
  /// nowhere to live. They are shown greyed rather than hidden: an option
  /// that is missing reads as a bug, one that is refused reads as a rule.
  final Set<RecurringScope> unavailable;
  final String? unavailableHint;

  @override
  State<RecurringScopeDialog> createState() => RecurringScopeDialogState();
}

class RecurringScopeDialogState extends State<RecurringScopeDialog> {
  late RecurringScope _scope = _firstAvailable;

  /// The narrowest scope that can hold this edit: it is the only one that
  /// cannot take a bill the user did not mean to touch.
  RecurringScope get _firstAvailable =>
      RecurringScope.values.firstWhere((s) => !widget.unavailable.contains(s));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(widget.title),
      contentPadding: EdgeInsets.symmetric(
        horizontal: context.spacing.lg,
        vertical: context.spacing.md,
      ),
      content: RadioGroup<RecurringScope>(
        groupValue: _scope,
        onChanged: (value) => setState(() => _scope = value!),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final scope in RecurringScope.values)
              _ScopeOption(
                scope: scope,
                label: _label(l10n, scope),
                hint: _hint(l10n, scope),
                enabled: !widget.unavailable.contains(scope),
                onSelect: (value) => setState(() => _scope = value),
              ),
          ],
        ),
      ),
      actions: [
        AppButton.text(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        AppButton(
          onPressed: () => Navigator.pop(context, _scope),
          destructive: widget.destructive,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }

  String? _hint(AppLocalizations l10n, RecurringScope scope) {
    if (widget.unavailable.contains(scope)) return widget.unavailableHint;
    if (scope == RecurringScope.updateRule) return l10n.scopeUpdateRuleHint;
    return null;
  }

  static String _label(AppLocalizations l10n, RecurringScope scope) =>
      switch (scope) {
        RecurringScope.thisOnly => l10n.scopeThisOnly,
        RecurringScope.updateRule => l10n.scopeUpdateRule,
      };
}

/// One choice: its radio sits on the same line as its label, with any hint
/// tucked underneath.
///
/// Hand-built rather than a `RadioListTile`, for two reasons that are both
/// visible: a tile centres its leading against the whole title-plus-subtitle
/// block, so the radio floats between the lines instead of sitting on the
/// first one; and a tile's height is sized for a two-line row whether or not
/// there is a second line, which is most of the gap between these options.
class _ScopeOption extends StatelessWidget {
  const _ScopeOption({
    required this.scope,
    required this.label,
    required this.hint,
    required this.enabled,
    required this.onSelect,
  });

  final RecurringScope scope;
  final String label;
  final String? hint;
  final bool enabled;
  final ValueChanged<RecurringScope> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      // The whole row is the target, which is why the radio below can shrink
      // its own tap target away: the 48dp is the row, not the glyph.
      onTap: enabled ? () => onSelect(scope) : null,
      child: Padding(
        // Two of these end up between consecutive options, since each row
        // carries its own half: sm + sm = the 16 they sit apart by.
        padding: EdgeInsets.symmetric(vertical: context.spacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<RecurringScope>(
              value: scope,
              enabled: enabled,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              // The glyph's box is 40 against a 24 label line, and the 16 it
              // has spare is empty row under the label rather than space the
              // eye reads as a gap. Compacting it to the line is what closes
              // the distance between options.
              visualDensity: const VisualDensity(vertical: -4),
            ),
            SizedBox(width: context.spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: enabled ? null : theme.disabledColor,
                    ),
                  ),
                  if (hint != null)
                    Text(
                      hint!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
