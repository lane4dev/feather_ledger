import 'package:feather_ledger/app/design_system/app_badge.dart';
import 'package:feather_ledger/app/design_system/app_bottom_action_bar.dart';
import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/design_system/app_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/shared/presentation/models/account_ui_model.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:feather_ledger/shared/presentation/ledger_error_localizer.dart';
import 'package:feather_ledger/shared/presentation/money_format.dart';
import 'package:feather_ledger/shared/presentation/extensions/account_type_extension.dart';
import 'package:feather_ledger/shared/presentation/widgets/category_icon.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_dialog_option.dart';
import 'package:feather_ledger/features/ledger/data/notifications/recurring_reminders.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/commands/create_recurring_series_command.dart';
import '../../domain/entities/ledger_entities.dart';
import '../../domain/services/recurring_service.dart';
import '../models/custom_recurrence.dart';
import '../models/transaction_tile_ui_model.dart';
import '../models/transaction_date_label.dart';
import '../widgets/custom_recurrence_dialog.dart';
import '../widgets/distant_past_start_dialog.dart';
import '../widgets/ledger_note_field.dart';
import '../theme/ledger_theme.dart';
import '../view_model/recurring_view_model.dart';
import '../view_model/transaction_form_view_state.dart';
import '../widgets/ledger_amount_input.dart';
import '../widgets/ledger_form_row.dart';
import '../widgets/ledger_form_sections.dart';
import '../widgets/ledger_value_icons.dart';
import '../widgets/ledger_selection_sheet.dart';
import '../widgets/ledger_selector_field.dart';
import '../widgets/recurring_scope_dialog.dart';
import '../widgets/recurring_mode_label.dart';
import '../widgets/custom_reminder_dialog.dart';

/// Edits one upcoming recurring bill (spec 004, US2).
///
/// The form shows every field and asks how far the change reaches *when it is
/// saved*. One field does not survive every answer: a bill's date and amount
/// live on the instance row, while its category, account and description live
/// on the series. So a change to those three cannot be applied to a single
/// occurrence — and the dialog says so by refusing that scope, rather than
/// accepting the edit and quietly dropping half of it.
class RecurringBillFormScreen extends ConsumerStatefulWidget {
  const RecurringBillFormScreen({
    super.key,
    required this.transaction,
  });

  final TransactionTileUiModel transaction;

  @override
  ConsumerState<RecurringBillFormScreen> createState() =>
      _RecurringBillFormScreenState();
}

class _RecurringBillFormScreenState
    extends ConsumerState<RecurringBillFormScreen> {
  final _formKey = GlobalKey<FormState>();

  /// The bill's amount, as the text the field shows. Read back through
  /// [parseMinor] when it is saved — the field holds no value of its own.
  late final TextEditingController _amount;
  late DateTime _date;
  String? _categoryId;
  String? _accountId;
  late final TextEditingController _note;
  int? _reminderMinutes;
  late bool _autoPost;
  late String _frequency;
  late int _interval;
  late List<int> _weekdays;
  DateTime? _endDate;
  int? _countLimit;
  late final List<int> _initialWeekdays;

  /// Whether the user changed something only the series can hold. If they
  /// did, "only this bill" stops being an answer this edit can have.
  bool get _changedSeriesFields {
    final series = widget.transaction.series;
    return _categoryId != widget.transaction.category!.id ||
        _accountId != widget.transaction.account.id ||
        _reminderMinutes != series?.reminderMinutes ||
        (series != null &&
            (_autoPost != series.autoPost ||
                _frequency != series.frequency ||
                _interval != (series.interval ?? 1) ||
                !_sameMoment(_endDate, series.endDate) ||
                _countLimit != series.limit ||
                !_sameWeekdays(_weekdays, _initialWeekdays)));
  }

  @override
  void initState() {
    super.initState();
    final bill = widget.transaction;
    final series = bill.series;
    _amount = TextEditingController(text: formatMinor(bill.amount));
    _date = bill.date;
    _categoryId = bill.category!.id;
    _accountId = bill.account.id;
    _note = TextEditingController(text: bill.note ?? '');
    _reminderMinutes = series?.reminderMinutes;
    _autoPost = series?.autoPost ?? false;
    _frequency = series?.frequency ?? 'MONTHLY';
    _interval = series?.interval ?? 1;
    _initialWeekdays =
        CreateRecurringSeriesCommand.weekdaysFromRrule(series?.rrule);
    _weekdays = List<int>.of(_initialWeekdays);
    _endDate = series?.endDate;
    _countLimit = series?.limit;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accounts =
        ref.watch(accountUiListProvider).value ?? const <AccountUiModel>[];
    final selected =
        accounts.where((item) => item.account.id == _accountId).firstOrNull;
    final currency = AppCurrencies.getSymbol(selected?.account.currencyCode ??
        widget.transaction.account.currencyCode);
    final labelWidth = LedgerTheme.transactionFormLabelWidth(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: AppIconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: () => context.pop(),
            tooltip: l10n.cancel),
        title: Text(l10n.editTransaction),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: context.spacing.lg),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _inset(_typeRow(l10n)),
              SizedBox(height: context.spacing.md),
              _inset(LedgerAmountCard(
                amount: LedgerAmountInput(
                    controller: _amount,
                    type: widget.transaction.type,
                    currencySymbol: currency),
                footer: widget.transaction.series == null
                    ? null
                    : RecurringModeLabel(mode: widget.transaction.series!.mode),
              )),
              SizedBox(height: context.spacing.md),
              _inset(LedgerFormCard(children: [
                _categoryRow(l10n, labelWidth),
                _accountRow(l10n, labelWidth),
                _dateRow(l10n, labelWidth),
              ])),
              if (widget.transaction.series case final series?) ...[
                SizedBox(height: context.spacing.md),
                _inset(LedgerFormCard(children: [
                  if (series.mode == RecurringSeriesMode.repeating)
                    _repeatRow(l10n, labelWidth),
                  _autoPostRow(l10n),
                  LedgerFormRow(
                    card: true,
                    icon: LucideIcons.bell,
                    onTap: _pickReminder,
                    child: LedgerSelectorField(
                      alignEnd: true,
                      label: l10n.reminder,
                      labelWidth: labelWidth,
                      text: _reminderLabel(l10n, _reminderMinutes),
                    ),
                  ),
                ])),
              ],
              SizedBox(height: context.spacing.md),
              _inset(LedgerFormCard(children: [
                LedgerNoteField(
                    controller: _note, labelWidth: labelWidth, card: true),
              ])),
              SizedBox(height: context.spacing.xl),
            ]),
          ),
        ),
      ),
      bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
          ? null
          : AppBottomActionBar(
              child: AppButton(onPressed: _submit, child: Text(l10n.save))),
    );
  }

  Widget _typeRow(AppLocalizations l10n) {
    final label = switch (widget.transaction.type) {
      TransactionKind.income => l10n.income,
      TransactionKind.expense => l10n.expense,
      TransactionKind.transfer => l10n.transfer,
      _ => '',
    };
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SizedBox(width: context.spacing.sm),
        AppBadge(label: l10n.pendingBill),
      ],
    );
  }

  /// The page's horizontal margin, for the column's children that are not
  /// [LedgerFormRow]s. A row insets itself so that its ripple can reach the
  /// edge; anything else has to be inset from out here.
  Widget _inset(Widget child) => Padding(
        padding: EdgeInsets.symmetric(horizontal: context.spacing.md),
        child: child,
      );

  Widget _dateRow(AppLocalizations l10n, double labelWidth) => LedgerFormRow(
        card: true,
        icon: LucideIcons.clock,
        onTap: _pickDate,
        child: LedgerSelectorField(
          alignEnd: true,
          label: l10n.date,
          labelWidth: labelWidth,
          text: transactionDateLabel(
            date: _date,
            today: DateTime.now(),
            locale: Localizations.localeOf(context).toString(),
            l10n: l10n,
          ),
        ),
      );

  Widget _categoryRow(AppLocalizations l10n, double labelWidth) {
    final theme = Theme.of(context);
    final categoryType = widget.transaction.type == TransactionKind.income
        ? CategoryType.income
        : CategoryType.expense;

    final categories = ref.watch(categoryListProvider(categoryType));

    return LedgerFormRow(
      card: true,
      icon: LucideIcons.layoutGrid,
      onTap: categories.value == null
          ? null
          : () async {
              final result = await showModalBottomSheet<String>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => LedgerSelectionSheet<CategoryEntity>(
                  title: l10n.category,
                  options: categories.value!,
                  getLabel: (c) => c.name,
                  getLeading: (context, c) => AppIconBadge(
                      color: Color(c.colorInt),
                      child: CategoryIcon(
                          iconKey: c.iconKey,
                          size: context.metrics.iconSize,
                          color: Color(c.colorInt))),
                  getColor: (c) => Color(c.colorInt),
                  isSelected: (c) => c.id == _categoryId,
                  onSelected: (c) => Navigator.pop(context, c.id),
                  onManageTap: () => context.push('/categories_management'),
                  manageButtonText: l10n.manageCategories,
                ),
              );
              if (result != null) setState(() => _categoryId = result);
            },
      child: categories.when(
        data: (categories) {
          final selected =
              categories.where((c) => c.id == _categoryId).firstOrNull;
          return LedgerSelectorField(
            alignEnd: true,
            leading: selected == null
                ? null
                : LedgerCategoryValueIcon(
                    iconKey: selected.iconKey,
                    color: Color(selected.colorInt),
                  ),
            label: l10n.category,
            labelWidth: labelWidth,
            text: selected?.name ?? l10n.select,
            textStyle: selected == null
                ? theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor)
                : null,
          );
        },
        loading: () => SizedBox(height: context.metrics.controlHeight),
        error: (_, __) => SizedBox(height: context.metrics.controlHeight),
      ),
    );
  }

  Widget _accountRow(AppLocalizations l10n, double labelWidth) {
    final theme = Theme.of(context);

    final accounts = ref.watch(accountUiListProvider);

    return LedgerFormRow(
      card: true,
      icon: LucideIcons.wallet,
      onTap: accounts.value == null
          ? null
          : () async {
              final result = await showModalBottomSheet<String>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => LedgerSelectionSheet<AccountUiModel>(
                  title: l10n.account,
                  options: accounts.value!,
                  getLabel: (a) => a.account.name,
                  getTrailing: (context, a) => Text(
                    a.displayBalance,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  getLeading: (context, a) => CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onSecondaryContainer,
                    child: Icon(a.account.type.icon),
                  ),
                  isSelected: (a) => a.account.id == _accountId,
                  onSelected: (a) => Navigator.pop(context, a.account.id),
                  onManageTap: () => context.push('/accounts_management'),
                  manageButtonText: l10n.manageAccounts,
                ),
              );
              if (result != null) setState(() => _accountId = result);
            },
      child: accounts.when(
        data: (accounts) {
          final selected =
              accounts.where((a) => a.account.id == _accountId).firstOrNull;
          return LedgerSelectorField(
            alignEnd: true,
            leading: selected == null
                ? null
                : LedgerAccountValueIcon(type: selected.account.type),
            label: l10n.account,
            labelWidth: labelWidth,
            text: selected?.account.name ?? l10n.select,
            textStyle: selected == null
                ? theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor)
                : null,
          );
        },
        loading: () => SizedBox(height: context.metrics.controlHeight),
        error: (_, __) => SizedBox(height: context.metrics.controlHeight),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (!mounted) return;
    setState(() {
      _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time?.hour ?? _date.hour,
          time?.minute ?? _date.minute,
          _date.second,
          _date.millisecond,
          _date.microsecond);
    });
  }

  String _reminderLabel(AppLocalizations l10n, int? minutes) =>
      switch (minutes) {
        null => l10n.reminderNone,
        5 => l10n.reminder5,
        10 => l10n.reminder10,
        15 => l10n.reminder15,
        30 => l10n.reminder30,
        60 => l10n.reminderHour,
        1440 => l10n.reminderDay,
        _ => l10n.reminderMinutesValue(minutes),
      };

  Future<void> _pickReminder() async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(title: Text(l10n.reminder), children: [
        for (final minutes in [0, 5, 10, 15, 30, 60, 1440])
          FeatherDialogOption<int>(
            label: _reminderLabel(l10n, minutes == 0 ? null : minutes),
            value: minutes,
            groupValue: _reminderMinutes ?? 0,
            onChanged: (value) => Navigator.pop(context, value),
          ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, -1),
          child: Text(l10n.reminderCustom),
        ),
      ]),
    );
    if (!mounted || choice == null) return;
    final minutes = choice == -1
        ? await showDialog<int>(
            context: context, builder: (_) => const CustomReminderDialog())
        : choice;
    if (!mounted || minutes == null) return;
    if (minutes > 0) {
      var granted = false;
      try {
        final reminders = ref.read(recurringRemindersProvider);
        granted = await reminders.requestPermission(
            postLabel: l10n.postInstance, skipLabel: l10n.notificationSkip);
        if (granted) {
          await reminders.start(
              title: l10n.reminderNotificationTitle,
              channelName: l10n.reminderChannel,
              postLabel: l10n.postInstance,
              skipLabel: l10n.notificationSkip);
        }
      } catch (_) {
        granted = false;
      }
      if (!mounted) return;
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.reminderPermissionRequired)));
        return;
      }
    }
    setState(() => _reminderMinutes = minutes == 0 ? null : minutes);
  }

  bool get _isCustomRecurrence =>
      _interval > 1 ||
      _weekdays.isNotEmpty ||
      _endDate != null ||
      _countLimit != null;

  Widget _repeatRow(AppLocalizations l10n, double labelWidth) => LedgerFormRow(
        card: true,
        icon: LucideIcons.repeat,
        onTap: _pickRepeat,
        child: LedgerSelectorField(
          alignEnd: true,
          label: l10n.repeat,
          labelWidth: labelWidth,
          text: _isCustomRecurrence
              ? l10n.customRepeat
              : _frequencyLabel(l10n, _frequency),
        ),
      );

  Widget _autoPostRow(AppLocalizations l10n) => LedgerFormRow(
        card: true,
        icon: LucideIcons.zap,
        onTap: () => setState(() => _autoPost = !_autoPost),
        showChevron: false,
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.autoPostWhenDue,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Switch.adaptive(
              value: _autoPost,
              onChanged: (value) => setState(() => _autoPost = value),
            ),
          ],
        ),
      );

  Future<void> _pickRepeat() async {
    final l10n = AppLocalizations.of(context)!;
    final current = _isCustomRecurrence ? 'CUSTOM' : _frequency;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.repeat),
        children: [
          for (final option in [
            ...TransactionFormViewState.repeatFrequencies,
            'CUSTOM',
          ])
            FeatherDialogOption<String>(
              label: option == 'CUSTOM'
                  ? l10n.customRepeat
                  : _frequencyLabel(l10n, option),
              value: option,
              groupValue: current,
              onChanged: (value) => Navigator.pop(context, value),
            ),
        ],
      ),
    );
    if (!mounted || result == null) return;
    if (result != 'CUSTOM') {
      setState(() {
        _frequency = result;
        _interval = 1;
        _weekdays = const [];
        _endDate = null;
        _countLimit = null;
      });
      return;
    }
    final selected = await showDialog<CustomRecurrence>(
      context: context,
      builder: (_) => CustomRecurrenceDialog(
        initial: CustomRecurrence(
          frequency: _frequency,
          interval: _interval,
          startDate: _date,
          weekdays: _weekdays.isEmpty ? [_date.weekday] : _weekdays,
          endDate: _endDate,
          countLimit: _countLimit,
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _frequency = selected.frequency;
      _interval = selected.interval;
      _weekdays = List<int>.of(selected.weekdays);
      _endDate = selected.endDate;
      _countLimit = selected.countLimit;
      _date = selected.startDate;
    });
  }

  static String _frequencyLabel(AppLocalizations l10n, String frequency) =>
      switch (frequency) {
        'DAILY' => l10n.frequencyDaily,
        'WEEKLY' => l10n.frequencyWeekly,
        'YEARLY' => l10n.frequencyYearly,
        _ => l10n.frequencyMonthly,
      };

  static bool _sameMoment(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.isAtSameMomentAs(b);
  }

  static bool _sameWeekdays(List<int> a, List<int> b) {
    final sa = a.toSet();
    final sb = b.toSet();
    return sa.length == sb.length && sa.containsAll(sb);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final series = widget.transaction.series;
    // A one-shot plan has only one occurrence, so its whole series is the
    // entry being edited. Repeating series ask how far the edit reaches.
    final scope = series?.mode == RecurringSeriesMode.planned
        ? RecurringScope.updateRule
        : await showDialog<RecurringScope>(
            context: context,
            builder: (context) => RecurringScopeDialog(
              title: l10n.saveRecurringTitle,
              confirmLabel: l10n.save,
              unavailable: _changedSeriesFields
                  ? const {RecurringScope.thisOnly}
                  : const {},
              unavailableHint: l10n.scopeThisOnlyUnavailable,
            ),
          );
    if (scope == null || !mounted) return;

    final isPlannedUpdate = series?.mode == RecurringSeriesMode.planned;
    final isRepeatingUpdate = scope == RecurringScope.updateRule &&
        series?.mode == RecurringSeriesMode.repeating;

    DateTime? materializeFrom;
    final now = ref.read(ledgerClockProvider).now();
    if (RecurringViewModel.needsDistantPastConfirmation(
      scope: scope,
      series: series,
      currentDate: widget.transaction.date,
      nextDate: _date,
      nextFrequency: _frequency,
      nextInterval: _interval,
      initialWeekdays: _initialWeekdays,
      nextWeekdays: _weekdays,
      now: now,
    )) {
      materializeFrom = await DistantPastStartDialog.show(
        context,
        startDate: _date,
        now: now,
      );
      if (materializeFrom == null || !mounted) return;
    }

    final notifier = ref.read(recurringViewModelProvider.notifier);
    final result = await notifier.updateBill(
      widget.transaction.id,
      scope: scope,
      amountMinor: parseMinor(_amount.text),
      date: _date,
      categoryId: _categoryId ?? widget.transaction.category!.id,
      accountId: _accountId ?? widget.transaction.account.id,
      description: _note.text.trim(),
      frequency: isRepeatingUpdate ? _frequency : null,
      interval: isRepeatingUpdate ? _interval : null,
      materializeFrom: materializeFrom,
      weekdays: isRepeatingUpdate ? _weekdays : null,
      endDate: isRepeatingUpdate ? _endDate : null,
      countLimit: isRepeatingUpdate ? _countLimit : null,
      clearEndDate:
          isRepeatingUpdate && _endDate == null && series?.endDate != null,
      clearCountLimit:
          isRepeatingUpdate && _countLimit == null && series?.limit != null,
      autoPost: (isRepeatingUpdate || isPlannedUpdate) ? _autoPost : null,
      reminderMinutes:
          scope == RecurringScope.updateRule ? _reminderMinutes : null,
      clearReminder: scope == RecurringScope.updateRule &&
          _reminderMinutes == null &&
          series?.reminderMinutes != null,
    );

    if (!mounted) return;

    if (result case Failure(:final code)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(code.message(l10n))));
      return;
    }
    final autoPosted = notifier.takeLastAutoPostedCount();
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(autoPosted > 0
            ? l10n.autoPostedCountMessage(autoPosted)
            : l10n.billUpdated)));
  }
}
