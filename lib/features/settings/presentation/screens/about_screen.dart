import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feather_ledger/app/config/app_info.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    final packageInfoAsync = ref.watch(packageInfoProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.about)),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: spacing.xl),
            // App Logo
            Icon(
              Icons.book, // Placeholder for App Icon
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: spacing.md),
            // App Name
            Text(
              l10n.appTitle,
              style: textTheme.headlineMedium,
            ),
            SizedBox(height: spacing.xs),
            // Version
            packageInfoAsync.when(
              data: (info) => Text(
                '${l10n.version} ${info.version}',
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            SizedBox(height: spacing.xl),

            // Menu Items
            const FeatherDivider(),
            ListTile(
              title: Text(l10n.openSourceLicenses),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final version = packageInfoAsync.valueOrNull?.version;
                showLicensePage(
                  context: context,
                  applicationName: l10n.appTitle,
                  applicationVersion: version,
                  applicationIcon: const Icon(Icons.book),
                );
              },
            ),
            const FeatherDivider(),
          ],
        ),
      ),
    );
  }
}