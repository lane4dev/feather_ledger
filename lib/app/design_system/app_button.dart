import 'package:flutter/material.dart';

/// The single feature-facing button entry point. It intentionally delegates
/// to Material 3 rather than owning colours or typography.
class AppButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool destructive;
  final bool outlined;

  const AppButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.destructive = false,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton(onPressed: onPressed, child: child);
    }
    if (destructive) {
      return FilledButton.tonal(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
        child: child,
      );
    }
    return FilledButton(onPressed: onPressed, child: child);
  }
}
