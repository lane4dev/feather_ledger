import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/shared/presentation/ledger_error_localizer.dart';
import 'package:feather_ledger/shared/presentation/money_format.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';

import '../../domain/entities/ledger_entities.dart';
import '../view_model/recurring_view_model.dart';
import '../widgets/recurring_series_form_sheet.dart';

/// Recurring bills: what is due, and the rules behind them (spec 004, US2).
///
/// The two halves are deliberately separate. Due instances are a to-do list
/// the user acts on; series are a rule set the user maintains. Posting is the
/// only action here that touches the ledger, and it always asks first.
class RecurringListScreen extends ConsumerWidget {
  const RecurringListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final viewModel = ref.watch(recurringViewModelProvider.notifier);
    final state = ref.watch(recurringViewModelProvider);
    final due = viewModel.dueNow();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recurringTitle)),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: context.spacing.sm),
        children: [
          _SectionHeader(title: l10n.dueSection),
          if (due.isEmpty)
            _EmptyLine(text: l10n.noDueInstances)
          else
            ...due.map((instance) => _DueTile(
                  instance: instance,
                  onPost: () => _confirmPost(context, ref, l10n, instance),
                  onSkip: () => _skip(context, ref, l10n, instance),
                )),

          const FeatherDivider(),
          _SectionHeader(title: l10n.seriesSection),
          state.series.when(
            data: (series) => series.isEmpty
                ? _EmptyLine(text: l10n.noRecurringSeries)
                : Column(
                    children: series
                        .map((s) => _SeriesTile(
                              series: s,
                              onDeactivate: () =>
                                  _confirmDeactivate(context, ref, l10n, s),
                            ))
                        .toList(),
                  ),
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
            error: (e, _) =>
                _EmptyLine(text: l10n.errorPrefix(e.toString())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          useRootNavigator: true,
          builder: (context) => const RecurringSeriesFormSheet(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmPost(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ScheduledTransactionEntity instance,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.postInstanceTitle),
        content: Text(l10n.postInstanceConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.postInstance),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await _run(
      context,
      l10n,
      () => ref
          .read(recurringViewModelProvider.notifier)
          .postInstance(instance.id),
      success: l10n.instancePosted,
    );
  }

  Future<void> _skip(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ScheduledTransactionEntity instance,
  ) async {
    // No confirmation: skipping writes no event and moves no money, so there
    // is nothing to warn about.
    await _run(
      context,
      l10n,
      () => ref
          .read(recurringViewModelProvider.notifier)
          .skipInstance(instance.id),
      success: l10n.instanceSkipped,
    );
  }

  Future<void> _confirmDeactivate(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    RecurringTransactionSeriesEntity series,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deactivateSeries),
        content: Text(l10n.deactivateSeriesConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deactivateSeries),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await _run(
      context,
      l10n,
      () => ref
          .read(recurringViewModelProvider.notifier)
          .deactivateSeries(series.id, endDate: DateTime.now()),
      success: l10n.seriesDeactivated,
    );
  }

  /// Runs a write and reports it. Failures render through the localizer, the
  /// presentation layer's single failure-rendering point.
  Future<void> _run(
    BuildContext context,
    AppLocalizations l10n,
    Future<Result<void>> Function() action, {
    required String success,
  }) async {
    final result = await action();
    if (!context.mounted) return;

    final message = result.when(
      success: (_) => success,
      failure: (code, _) => code.message(l10n),
    );
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
          context.spacing.lg,
          context.spacing.md,
          context.spacing.lg,
          context.spacing.sm,
        ),
        child: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
      );
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.lg,
          vertical: context.spacing.md,
        ),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).hintColor),
        ),
      );
}

class _DueTile extends StatelessWidget {
  const _DueTile({
    required this.instance,
    required this.onPost,
    required this.onSkip,
  });

  final ScheduledTransactionEntity instance;
  final VoidCallback onPost;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final series = instance.recurringTransactionSeries;

    return ListTile(
      title: Text(series?.description ?? ''),
      subtitle: Text(_formatDate(instance.date)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatMinor(instance.amountMinor),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(width: 8),
          TextButton(onPressed: onPost, child: Text(l10n.postInstance)),
          TextButton(onPressed: onSkip, child: Text(l10n.skipInstance)),
        ],
      ),
    );
  }
}

class _SeriesTile extends StatelessWidget {
  const _SeriesTile({required this.series, required this.onDeactivate});

  final RecurringTransactionSeriesEntity series;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final account = AppCurrencies.getSymbol('USD');

    return ListTile(
      title: Text(series.description),
      subtitle: Text(_describeRule(series, l10n)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$account${formatMinor(series.amountMinor)}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'deactivate') onDeactivate();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'deactivate',
                child: Text(l10n.deactivateSeries),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) => '${date.year}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// "Every month", "Every 2 weeks", plus the end date when there is one.
String _describeRule(
    RecurringTransactionSeriesEntity series, AppLocalizations l10n) {
  final unit = switch (series.frequency.toUpperCase()) {
    'DAILY' => l10n.frequencyDaily,
    'WEEKLY' => l10n.frequencyWeekly,
    'YEARLY' => l10n.frequencyYearly,
    _ => l10n.frequencyMonthly,
  };
  final interval = series.interval ?? 1;
  final cadence = interval <= 1
      ? l10n.everyFrequency(unit)
      : l10n.everyNthFrequency(interval, unit);

  final endDate = series.endDate;
  return endDate == null
      ? cadence
      : '$cadence · ${l10n.seriesEndsOn(_formatDate(endDate))}';
}
