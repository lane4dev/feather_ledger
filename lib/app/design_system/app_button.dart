import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum _ButtonVariant { primary, secondary, outlined, quiet, destructive }

/// The single feature-facing button entry point. It intentionally delegates
/// to Material 3 rather than owning colours or typography.
class AppButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final _ButtonVariant _variant;

  const AppButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    bool destructive = false,
    bool outlined = false,
  }) : _variant = outlined
            ? _ButtonVariant.outlined
            : destructive
                ? _ButtonVariant.destructive
                : _ButtonVariant.primary;

  const AppButton.secondary(
      {super.key, required this.onPressed, required this.child, this.icon})
      : _variant = _ButtonVariant.secondary;
  const AppButton.outlined(
      {super.key, required this.onPressed, required this.child, this.icon})
      : _variant = _ButtonVariant.outlined;
  const AppButton.text(
      {super.key, required this.onPressed, required this.child, this.icon})
      : _variant = _ButtonVariant.quiet;
  const AppButton.destructive(
      {super.key, required this.onPressed, required this.child, this.icon})
      : _variant = _ButtonVariant.destructive;

  @override
  Widget build(BuildContext context) {
    final content = icon == null
        ? child
        : Row(mainAxisSize: MainAxisSize.min, children: [
            icon!,
            SizedBox(width: context.spacing.sm),
            Flexible(child: child)
          ]);
    return switch (_variant) {
      _ButtonVariant.primary =>
        FilledButton(onPressed: onPressed, child: content),
      _ButtonVariant.secondary =>
        FilledButton.tonal(onPressed: onPressed, child: content),
      _ButtonVariant.outlined =>
        OutlinedButton(onPressed: onPressed, child: content),
      _ButtonVariant.quiet => TextButton(onPressed: onPressed, child: content),
      _ButtonVariant.destructive => FilledButton.tonal(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
          child: content,
        ),
    };
  }
}
