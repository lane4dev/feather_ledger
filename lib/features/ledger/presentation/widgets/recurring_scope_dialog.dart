import 'package:flutter/material.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';

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
      content: RadioGroup<RecurringScope>(
        groupValue: _scope,
        onChanged: (value) => setState(() => _scope = value!),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final scope in RecurringScope.values)
              RadioListTile<RecurringScope>(
                value: scope,
                enabled: !widget.unavailable.contains(scope),
                contentPadding: EdgeInsets.zero,
                title: Text(_label(l10n, scope)),
                subtitle: _subtitle(l10n, scope),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _scope),
          // A destructive confirm wears the error colour a recorded
          // transaction's delete does; "next" is not destructive and does not.
          style: widget.destructive
              ? TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                )
              : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }

  Widget? _subtitle(AppLocalizations l10n, RecurringScope scope) {
    if (widget.unavailable.contains(scope)) {
      return widget.unavailableHint == null
          ? null
          : Text(widget.unavailableHint!);
    }
    // Only the widest scope needs reassuring: it is the one that reads as
    // "throw the whole series away".
    if (scope == RecurringScope.all) return Text(l10n.scopeAllHint);
    return null;
  }

  static String _label(AppLocalizations l10n, RecurringScope scope) =>
      switch (scope) {
        RecurringScope.thisOnly => l10n.scopeThisOnly,
        RecurringScope.thisAndFollowing => l10n.scopeThisAndFollowing,
        RecurringScope.all => l10n.scopeAll,
      };
}
