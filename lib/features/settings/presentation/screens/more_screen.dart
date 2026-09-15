import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/features/settings/presentation/widgets/external_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.more)),
      body: ListView(
        padding:
            context.pagePadding.add(EdgeInsets.symmetric(vertical: spacing.md)),
        children: [
          // Configuration & Management
          AppCard.group(
              child: Column(children: [
            ListTile(
              leading: const Icon(LucideIcons.settings),
              title: Text(l10n.settings),
              subtitle: Text(l10n.settingsHint),
              trailing: const Icon(LucideIcons.chevronRight),
              // Pushed, not gone to: each of these is a page of its own, opened
              // over the shell so the bottom bar does not follow it in — the
              // route carries the parent navigator key that makes that happen.
              onTap: () => context.push('/more/settings'),
            ),
            const FeatherDivider(),
            ListTile(
              leading: const Icon(LucideIcons.wallet),
              title: Text(l10n.accounts),
              subtitle: Text(l10n.accountsHint),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => context.push('/accounts_management'),
            ),
            const FeatherDivider(),
            ListTile(
              leading: const Icon(LucideIcons.shapes),
              title: Text(l10n.categories),
              subtitle: Text(l10n.categoriesHint),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => context.push('/categories_management'),
            ),
          ])),
          SizedBox(height: spacing.lg),

          // Support & Info
          AppCard.group(
              child: Column(children: [
            ListTile(
              leading: const Icon(LucideIcons.circleHelp),
              title: Text(l10n.supportCenter),
              subtitle: Text(l10n.supportCenterHint),
              trailing: const Icon(LucideIcons.externalLink),
              onTap: () => openInformationPage(context, ref, 'support/'),
            ),
            const FeatherDivider(),
            ListTile(
              leading: const Icon(LucideIcons.messageSquare),
              title: Text(l10n.feedback),
              subtitle: Text(l10n.feedbackHint),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => sendFeedback(context, ref),
            ),
          ])),
          SizedBox(height: spacing.lg),
          AppCard.group(
              child: Column(children: [
            ListTile(
              leading: const Icon(LucideIcons.info),
              title: Text(l10n.about),
              subtitle: Text(l10n.aboutHint),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => context.push('/more/about'),
            ),
          ])),
        ],
      ),
    );
  }
}
