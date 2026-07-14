import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feather_ledger/app/config/app_info.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    final packageInfoAsync = ref.watch(packageInfoProvider);

    return Scaffold(
      appBar: AppBar(
        // Spelled out, like every other icon in the app: left to itself the
        // bar draws the framework's Material arrow, which is the one glyph the
        // icon set would not cover.
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        title: Text(l10n.about),
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: spacing.xl),
            // App Logo
            Image.asset(
              'assets/images/app_logo.png',
              width: 80,
              height: 80,
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
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () {
                final version = packageInfoAsync.value?.version;
                showLicensePage(
                  context: context,
                  applicationName: l10n.appTitle,
                  applicationVersion: version,
                  applicationIcon: const Icon(LucideIcons.book),
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
