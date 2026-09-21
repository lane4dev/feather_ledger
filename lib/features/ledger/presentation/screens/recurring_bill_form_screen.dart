import 'package:feather_ledger/app/design_system/app_bottom_action_bar.dart';
import 'package:feather_ledger/app/design_system/app_badge.dart';
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
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_dialog_option.dart';
import 'package:feather_ledger/features/ledger/data/notifications/recurring_reminders.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/entities/ledger_entities.dart';
import '../models/transaction_tile_ui_model.dart';
import '../models/transaction_date_label.dart';
import '../widgets/ledger_note_field.dart';
import '../theme/ledger_theme.dart';
import '../view_model/recurring_view_model.dart';
import '../widgets/ledger_amount_input.dart';
import '../widgets/ledger_form_row.dart';
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

  /// Whether the user changed something only the series can hold. If they
  /// did, "only this bill" stops being an answer this edit can have.
  bool get _changedSeriesFields =>
      _categoryId != widget.transaction.category!.id ||
      _accountId != widget.transaction.account.id ||
      _note.text.trim() != (widget.transaction.note ?? '').trim() ||
      _reminderMinutes != widget.transaction.series?.reminderMinutes;

  @override
  void initState() {
    super.initState();
    final bill = widget.transaction;
    _amount = TextEditingController(text: formatMinor(bill.amount));
    _date = bill.date;
    _categoryId = bill.category!.id;
    _accountId = bill.account.id;
    _note = TextEditingController(text: bill.note ?? '');
    _reminderMinutes = bill.series?.reminderMinutes;
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(l10n.editTransaction,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            SizedBox(width: context.spacing.sm),
            AppBadge(label: l10n.pendingBill),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: context.spacing.lg),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _inset(LedgerAmountInput(
                  controller: _amount,
                  type: widget.transaction.type,
                  currencySymbol: currency)),
              if (widget.transaction.series case final series?) ...[
                SizedBox(height: context.spacing.sm),
                _inset(RecurringModeLabel(mode: series.mode)),
              ],
              SizedBox(height: context.spacing.lg),
              _inset(const FeatherDivider()),
              SizedBox(height: context.spacing.sm),
              _dateRow(l10n, labelWidth),
              if (widget.transaction.series != null) ...[
                SizedBox(height: context.spacing.sm),
                LedgerFormRow(
                  icon: LucideIcons.bell,
                  onTap: _pickReminder,
                  child: LedgerSelectorField(
                    label: l10n.reminder,
                    labelWidth: labelWidth,
                    text: _reminderLabel(l10n, _reminderMinutes),
                  ),
                ),
              ],
              SizedBox(height: context.spacing.sm),
              _inset(const FeatherDivider()),
              SizedBox(height: context.spacing.sm),
              _accountRow(l10n, labelWidth),
              SizedBox(height: context.spacing.sm),
              _categoryRow(l10n, labelWidth),
              SizedBox(height: context.spacing.sm),
              _inset(const FeatherDivider()),
              SizedBox(height: context.spacing.sm),
              LedgerNoteField(controller: _note, labelWidth: labelWidth),
              SizedBox(height: context.spacing.xl),
            ]),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomActionBar(
          child: AppButton(
        onPressed: _submit,
        child: Text(l10n.save),
      )),
    );
  }

  /// The page's horizontal margin, for the column's children that are not
  /// [LedgerFormRow]s. A row insets itself so that its ripple can reach the
  /// edge; anything else has to be inset from out here.
  Widget _inset(Widget child) => Padding(
        padding: LedgerTheme.pageInset(context),
        child: child,
      );

  Widget _dateRow(AppLocalizations l10n, double labelWidth) => LedgerFormRow(
        icon: LucideIcons.calendar,
        onTap: _pickDate,
        child: LedgerSelectorField(
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
            label: l10n.category,
            labelWidth: labelWidth,
            text: selected?.name ?? l10n.category,
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
            label: l10n.account,
            labelWidth: labelWidth,
            text: selected?.account.name ?? l10n.account,
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

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // A one-shot plan has only one occurrence, so its whole series is the
    // entry being edited. Repeating series still ask how far the edit reaches.
    final scope = widget.transaction.series?.mode == RecurringSeriesMode.planned
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

    final result =
        await ref.read(recurringViewModelProvider.notifier).updateBill(
              widget.transaction.id,
              scope: scope,
              amountMinor: parseMinor(_amount.text),
              date: _date,
              categoryId: _categoryId ?? widget.transaction.category!.id,
              accountId: _accountId ?? widget.transaction.account.id,
              description: _note.text.trim().isEmpty
                  ? widget.transaction.category!.name
                  : _note.text.trim(),
              reminderMinutes: _reminderMinutes,
            );

    if (!mounted) return;

    if (result case Failure(:final code)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(code.message(l10n))));
      return;
    }
    context.pop();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.billUpdated)));
  }
}
