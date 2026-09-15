import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

const supportEmail = 'support@tangyu.me';

typedef ExternalLinkLauncher = Future<bool> Function(Uri uri);

final externalLinkLauncherProvider = Provider<ExternalLinkLauncher>(
  (ref) => (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

Uri informationPage(Locale locale, [String path = '']) {
  final prefix = locale.languageCode == 'zh' ? '/zh' : '';
  return Uri.https('apps.tangyu.me', '$prefix/accounted-for/$path');
}

Future<bool> _launch(WidgetRef ref, Uri uri) async {
  try {
    return await ref.read(externalLinkLauncherProvider)(uri);
  } catch (_) {
    return false;
  }
}

Future<void> openInformationPage(BuildContext context, WidgetRef ref,
    [String path = '']) async {
  final uri = informationPage(Localizations.localeOf(context), path);
  final opened = await _launch(ref, uri);
  if (!context.mounted || opened) return;
  final l10n = AppLocalizations.of(context)!;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.linkUnavailable),
      content: Text(l10n.linkUnavailableMessage),
      actions: [
        AppButton.text(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    ),
  );
}

Future<void> sendFeedback(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.feedback),
      content: Text(l10n.feedbackConfirmation(supportEmail)),
      actions: [
        AppButton.text(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        AppButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.openEmailApp),
        ),
      ],
    ),
  );
  if (accepted != true || !context.mounted) return;
  final uri = Uri.parse(
      'mailto:$supportEmail?subject=${Uri.encodeComponent(l10n.feedbackEmailSubject)}');
  final opened = await _launch(ref, uri);
  if (!context.mounted || opened) return;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.emailUnavailable),
      content: Text(l10n.emailUnavailableMessage(supportEmail)),
      actions: [
        AppButton.text(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.cancel),
        ),
        AppButton(
          onPressed: () async {
            await Clipboard.setData(const ClipboardData(text: supportEmail));
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
          child: Text(l10n.copyEmail),
        ),
      ],
    ),
  );
}
