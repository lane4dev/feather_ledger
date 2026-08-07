import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppSheetHandle extends StatelessWidget {
  const AppSheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(
          child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.metrics.rowInset),
        child: Container(
          width: context.spacing.xl,
          height: context.spacing.xs,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant,
            borderRadius: context.metrics.chipBorderRadius,
          ),
        ),
      ));
}
