import 'package:flutter/material.dart';
import 'package:feather_ledger/app/design_system/app_form_row.dart';

/// Ledger rows share chrome while the feature retains its fields and actions.
class LedgerFormRow extends StatelessWidget {
  const LedgerFormRow(
      {super.key,
      required this.icon,
      required this.child,
      this.onTap,
      this.showChevron = true});
  final IconData icon;
  final Widget child;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) => AppFormRow.page(
      icon: icon, onTap: onTap, showChevron: showChevron, child: child);
}
