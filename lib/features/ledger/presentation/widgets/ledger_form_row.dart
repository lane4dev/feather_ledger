import 'package:flutter/material.dart';

class LedgerFormRow extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const LedgerFormRow({super.key, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12.0, right: 24.0),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 24,
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
