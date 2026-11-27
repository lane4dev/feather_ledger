import 'package:feather_ledger/features/budget/domain/value_objects/budget_value_objects.dart';
import 'package:feather_ledger/features/budget/presentation/widgets/transaction_budget_hint_banner.dart';
import 'package:feather_ledger/features/ledger/data/notifications/recurring_reminders.dart';
import '../widgets/custom_reminder_dialog.dart';
import 'package:feather_ledger/shared/presentation/widgets/category_icon.dart';
import 'package:feather_ledger/app/design_system/app_bottom_action_bar.dart';
import '../widgets/ledger_note_field.dart';
import 'package:feather_ledger/app/design_system/app_choice_chips.dart';
import 'package:feather_ledger/app/design_system/app_icon_button.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feather_ledger/app/design_system/app_badge.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/features/ledger/presentation/theme/ledger_theme.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/shared/presentation/models/account_ui_model.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_dialog_option.dart';
import 'package:feather_ledger/shared/presentation/extensions/account_type_extension.dart';
import 'package:feather_ledger/shared/presentation/ledger_error_localizer.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/features/ledger/domain/services/recurring_service.dart';
import '../models/transaction_date_label.dart';
import '../models/transaction_tile_ui_model.dart';
import '../models/custom_recurrence.dart';
import '../widgets/custom_recurrence_dialog.dart';
import '../widgets/distant_past_start_dialog.dart';

import '../view_model/transaction_form_view_model.dart';
import '../view_model/transaction_form_view_state.dart';
import '../widgets/ledger_amount_input.dart';
import '../widgets/ledger_form_row.dart';
import '../widgets/ledger_form_sections.dart';
import '../widgets/ledger_value_icons.dart';
import '../widgets/ledger_selection_sheet.dart';
import '../widgets/ledger_selector_field.dart';
import '../widgets/ledger_type_selector.dart';

/// Records or corrects any money movement: income, expense or transfer.
///
/// One form for all three because the user is describing one thing — an
/// amount, a date, and where it went. The kind only changes which fields
/// apply: a transfer has two accounts and no category. The fields that do not
/// apply to the selected kind are not rendered, so an illegal shape (a
/// transfer with a category, a transfer with one account) is not a state this
/// form can be in.
///
/// `null` means create, non-null means correct.
class TransactionFormScreen extends ConsumerStatefulWidget {
  final TransactionTileUiModel? transaction;

  const TransactionFormScreen({super.key, this.transaction});

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  /// The fields' view of the two text values. The values themselves live in
  /// the view model; these only carry them into the widgets, and are seeded
  /// once, before there is a caret to disturb.
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  TransactionFormViewModel get _vm =>
      ref.read(transactionFormViewModelProvider(widget.transaction).notifier);

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();

    // The controllers show the state, they do not hold it; they are seeded
    // from what the view model already is. `read` is enough — the first
    // `build` watches the provider, so the element this creates is the one it
    // keeps.
    final seeded =
        ref.read(transactionFormViewModelProvider(widget.transaction));
    _amountController.text = seeded.amountText;
    _noteController.text = seeded.note;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(transactionFormViewModelProvider(widget.transaction));
    final vm =
        ref.read(transactionFormViewModelProvider(widget.transaction).notifier);

    // The one write that can come *from* the state: anything that sets the
    // amount without typing (seeding a correction). It is a no-op on an
    // ordinary keystroke — the state echoes exactly what was typed — which is
    // what keeps the caret where the user left it.
    ref.listen(
      transactionFormViewModelProvider(widget.transaction)
          .select((s) => s.amountText),
      (_, text) {
        if (_amountController.text != text) _amountController.text = text;
      },
    );

    final categoriesAsync = ref.watch(categoryListProvider(state.categoryType));
    final accountsAsync = ref.watch(accountUiListProvider);
    final currencyKey =
        state.currencyCode ?? AppCurrencies.supportedCurrencyCodes.first;

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final colorScheme = theme.colorScheme;

    // Pickers only offer non-archived accounts (spec 003, US3); history and
    // balances retain archived rows.
    final activeAccounts =
        state.activeAccounts(accountsAsync.value ?? const <AccountUiModel>[]);
    final fromAccount = state.selectedAccount(activeAccounts)?.account;

    // A transfer's legs are in the from-account's currency, so once that leg
    // is chosen the amount is labelled with its currency rather than the
    // global display preference. Before it is chosen there is no such
    // currency yet, and the honest stand-in is the one the rest of the screen
    // would use — not a hardcoded dollar, which is what a new transfer used
    // to open with.
    final currencySymbol = AppCurrencies.getSymbol(
      (state.isTransfer ? fromAccount?.currencyCode : null) ?? currencyKey,
    );

    // Every name this form can put in a row, measured once so each row's
    // value starts at the same x — including the rows this kind does not
    // render, because switching kinds must not move the column under the
    // values that were already on screen.
    final labelWidth = LedgerTheme.transactionFormLabelWidth(context);

    // Same currency is an aggregate invariant, so the eligible destinations
    // are narrowed rather than letting the pair be chosen and refused. The
    // list is empty until a source is picked, which is also the honest answer.
    final toAccountOptions = state.transferDestinations(activeAccounts);
    final canSave = state.amountMinor != null &&
        (!state.type.requiresCategory || state.categoryId != null);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: AppIconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => context.pop(),
          tooltip: l10n.cancel,
        ),
        title: Text(_title(state, l10n)),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: context.spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!state.isBalancePurpose)
                  _inset(_typeControl(state, vm, l10n)),
                SizedBox(height: context.spacing.md),
                _inset(
                  LedgerAmountCard(
                    amount: LedgerAmountInput(
                      controller: _amountController,
                      onChanged: vm.setAmountText,
                      type: state.type,
                      currencySymbol: currencySymbol,
                      autofocus: !state.isEditing,
                    ),
                    footer: state.canRepeat
                        ? _TransactionFormModeSelector(
                            selected: state.mode,
                            onSelected: vm.setMode,
                            l10n: l10n,
                          )
                        : null,
                  ),
                ),
                SizedBox(height: context.spacing.md),

                // Core entry: what it was for, where it moved, when it
                // happened. Category leads because it is the field that names
                // the entry and unlocks the budget hint underneath.
                _inset(
                  LedgerFormCard(
                    children: [
                      if (!state.isTransfer && !state.isBalancePurpose)
                        _categoryRow(
                          l10n: l10n,
                          labelWidth: labelWidth,
                          categoriesAsync: categoriesAsync,
                          state: state,
                        ),
                      if (state.isBalancePurpose) ...[
                        LedgerFormRow(
                          card: true,
                          icon: LucideIcons.wallet,
                          child: LedgerSelectorField(
                            alignEnd: true,
                            label: l10n.account,
                            labelWidth: labelWidth,
                            text: state.original!.account.name,
                          ),
                        ),
                        LedgerFormRow(
                          card: true,
                          icon: LucideIcons.badgeInfo,
                          child: LedgerSelectorField(
                            alignEnd: true,
                            label: l10n.transactionType,
                            labelWidth: labelWidth,
                            text: state.type == TransactionKind.openingBalance
                                ? l10n.initialBalance
                                : l10n.accountBalanceAdjustmentDescription,
                          ),
                        ),
                      ] else ...[
                        _accountRow(
                          fieldKey: ValueKey('account-${state.type}'),
                          icon: state.isTransfer
                              ? LucideIcons.arrowUp
                              : LucideIcons.wallet,
                          label: state.isTransfer
                              ? l10n.transferFrom
                              : l10n.account,
                          labelWidth: labelWidth,
                          options: activeAccounts,
                          selectedId: state.accountId,
                          onSelected: vm.selectAccount,
                        ),
                        if (state.isTransfer)
                          _accountRow(
                            fieldKey: ValueKey('to-account-${state.accountId}'),
                            icon: LucideIcons.arrowDown,
                            label: l10n.transferTo,
                            labelWidth: labelWidth,
                            options: toAccountOptions,
                            selectedId: state.toAccountId,
                            onSelected: vm.selectToAccount,
                            extraValidator: (value) =>
                                value != null && value == state.accountId
                                    ? l10n.errorSameAccountTransfer
                                    : null,
                          ),
                      ],
                      LedgerFormRow(
                        card: true,
                        icon: LucideIcons.clock,
                        onTap: _pickDateTime,
                        child: LedgerSelectorField(
                          alignEnd: true,
                          label: l10n.date,
                          labelWidth: labelWidth,
                          text: transactionDateLabel(
                            date: state.date,
                            today: DateTime.now(),
                            locale: locale,
                            l10n: l10n,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (state.type == TransactionKind.expense &&
                    state.categoryId != null) ...[
                  SizedBox(height: context.spacing.sm),
                  _inset(
                    TransactionBudgetHintBanner(
                      currencyCode: currencyKey,
                      currencySymbol: currencySymbol,
                      month: YearMonth.fromDate(state.date),
                      categoryId: state.categoryId!,
                      mode: state.mode,
                      inputAmountMinor: state.amountMinor ?? 0,
                      selectedAccountIncludeInTotals: (state
                              .selectedAccount(accountsAsync.value ??
                                  const <AccountUiModel>[])
                              ?.account
                              .includeInTotals) ??
                          true,
                      original: state.original,
                    ),
                  ),
                ],

                // The schedule is a second card, and it grows out of the
                // core rather than appearing beside it: the switch between
                // modes is a change of shape, so the page eases into it.
                AnimatedSize(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.topCenter,
                  child: state.showsRepeatRow ||
                          state.showsAutoPostRow ||
                          (state.canRepeat &&
                              state.mode != TransactionFormMode.defaultMode)
                      ? Padding(
                          padding: EdgeInsets.only(top: context.spacing.md),
                          child: _inset(
                            LedgerFormCard(
                              children: [
                                if (state.showsRepeatRow)
                                  _repeatRow(l10n, labelWidth, state),
                                if (state.showsAutoPostRow)
                                  LedgerFormRow(
                                    card: true,
                                    icon: LucideIcons.zap,
                                    onTap: () =>
                                        vm.setAutoPost(!state.autoPost),
                                    showChevron: false,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            l10n.autoPostWhenDue,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                          ),
                                        ),
                                        Switch.adaptive(
                                          value: state.autoPost,
                                          onChanged: vm.setAutoPost,
                                        ),
                                      ],
                                    ),
                                  ),
                                if (state.canRepeat &&
                                    state.mode !=
                                        TransactionFormMode.defaultMode)
                                  LedgerFormRow(
                                    card: true,
                                    icon: LucideIcons.bell,
                                    onTap: () =>
                                        _pickReminder(state.reminderMinutes),
                                    child: LedgerSelectorField(
                                      alignEnd: true,
                                      label: l10n.reminder,
                                      labelWidth: labelWidth,
                                      text: _reminderLabel(
                                          l10n, state.reminderMinutes),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                SizedBox(height: context.spacing.md),

                // Everything that is context rather than the movement itself.
                _inset(
                  LedgerFormCard(
                    children: [
                      LedgerNoteField(
                        card: true,
                        controller: _noteController,
                        labelWidth: labelWidth,
                        onChanged: vm.setNote,
                      ),
                      if (state.showsAttachments)
                        _attachmentRow(l10n, labelWidth, state),
                    ],
                  ),
                ),

                SizedBox(height: context.spacing.xl),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
          ? null
          : AppBottomActionBar(
              padding: EdgeInsets.fromLTRB(
                context.spacing.md,
                context.spacing.sm,
                context.spacing.md,
                MediaQuery.viewInsetsOf(context).bottom + context.spacing.sm,
              ),
              child: AppButton(
                  onPressed: canSave ? _submit : null, child: Text(l10n.save))),
    );
  }

  /// The kind control at the top of the form.
  ///
  /// A new entry chooses among all three kinds. An ordinary recorded
  /// income/expense may switch sides, but only between those two: a transfer
  /// has two accounts and a balance purpose has no category, so neither is a
  /// legal replacement through this form. A posted scheduled bill shows the
  /// same component disabled — its kind is fixed by the series it came from.
  Widget _typeControl(
    TransactionFormViewState state,
    TransactionFormViewModel vm,
    AppLocalizations l10n,
  ) {
    if (!state.isEditing) {
      return LedgerTypeSelector(
        selectedType: state.type,
        onSelectionChanged: vm.setType,
        widthFactor: 1,
        flat: true,
      );
    }
    if (state.isTransfer) {
      return Text(
        l10n.transfer,
        style: Theme.of(context).textTheme.titleMedium,
      );
    }
    return LedgerTypeSelector(
      selectedType: state.type,
      kinds: const [TransactionKind.income, TransactionKind.expense],
      onSelectionChanged: vm.setType,
      enabled: state.canChangeType,
      widthFactor: 1,
      flat: true,
    );
  }

  String _title(TransactionFormViewState state, AppLocalizations l10n) {
    if (!state.isEditing) {
      return state.isTransfer ? l10n.addTransfer : l10n.addTransaction;
    }
    if (state.isTransfer) return l10n.editTransfer;
    return state.isBalancePurpose
        ? (state.type == TransactionKind.openingBalance
            ? l10n.initialBalance
            : l10n.accountBalanceAdjustmentDescription)
        : l10n.editTransaction;
  }

  /// The page's horizontal margin, for the column's children that are not
  /// [LedgerFormRow]s. A row insets itself so that its ripple can reach the
  /// edge; anything else has to be inset from out here.
  Widget _inset(Widget child) => Padding(
      padding: EdgeInsets.symmetric(horizontal: context.spacing.md),
      child: child);

  /// The category field, with its value's own icon on the right.
  Widget _categoryRow({
    required AppLocalizations l10n,
    required double labelWidth,
    required AsyncValue<List<CategoryEntity>> categoriesAsync,
    required TransactionFormViewState state,
  }) {
    final theme = Theme.of(context);
    return FormField<String>(
      key: ValueKey('category-${state.type}'),
      validator: (_) => state.categoryId == null ? l10n.required : null,
      builder: (field) => LedgerFormRow(
        card: true,
        icon: LucideIcons.layoutGrid,
        onTap: categoriesAsync.value == null
            ? null
            : () => _pickCategory(
                  categoriesAsync.value!
                      .where((c) => c.type == state.categoryType)
                      .toList(),
                ),
        child: categoriesAsync.when(
          data: (categories) {
            final selected =
                categories.where((c) => c.id == state.categoryId).firstOrNull;
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
              text: selected?.name ??
                  (field.hasError && state.categoryId == null
                      ? l10n.required
                      : l10n.select),
              textStyle: selected == null
                  ? theme.textTheme.bodyLarge?.copyWith(
                      color: field.hasError && state.categoryId == null
                          ? theme.colorScheme.error
                          : theme.hintColor)
                  : null,
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox(),
        ),
      ),
    );
  }

  Widget _attachmentRow(
    AppLocalizations l10n,
    double labelWidth,
    TransactionFormViewState state,
  ) {
    final theme = Theme.of(context);
    final existing = state.attachments.indexed;
    final pending = state.pendingAttachments.indexed;
    final count = state.attachmentCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Only the header opens the picker. The files below it are a list of
        // their own — a tap on a name is not a request for another file — and
        // their remove buttons must not sit inside the picker's tap target.
        LedgerFormRow(
          card: true,
          icon: LucideIcons.paperclip,
          onTap: _pickAttachments,
          child: LedgerSelectorField(
            label: l10n.attachments,
            labelWidth: labelWidth,
            text: count == 0 ? l10n.addAttachment : l10n.attachmentCount(count),
            textStyle: count == 0
                ? theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor)
                : null,
          ),
        ),
        // Align under the field's name: card inset + icon + icon gap.
        Padding(
          padding: EdgeInsets.only(
              left: context.metrics.iconSize + context.spacing.md * 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...existing.map(
                (entry) => _attachmentItem(
                  entry.$2.fileName,
                  onRemove: () => _vm.removeAttachmentAt(entry.$1),
                  removeTooltip: l10n.removeAttachment,
                ),
              ),
              ...pending.map(
                (entry) => _attachmentItem(
                  entry.$2.name,
                  onRemove: () => _vm.removePendingAt(entry.$1),
                  removeTooltip: l10n.removeAttachment,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _attachmentItem(
    String fileName, {
    required VoidCallback onRemove,
    required String removeTooltip,
  }) =>
      Row(
        children: [
          Expanded(
            child:
                Text(fileName, style: Theme.of(context).textTheme.bodyMedium),
          ),
          AppIconButton(
            onPressed: onRemove,
            icon: const Icon(LucideIcons.x),
            tooltip: removeTooltip,
          ),
        ],
      );

  Future<void> _pickAttachments() async {
    final selected = await openFiles();
    if (!mounted || selected.isEmpty) return;
    _vm.attachFiles(selected);
  }

  /// Opens the category picker and hands the choice to the view model.
  ///
  /// It lives here rather than in the row's builder because the tap belongs to
  /// the row, which is outside the stream branch the field is built in.
  Future<void> _pickCategory(List<CategoryEntity> options) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => LedgerSelectionSheet<CategoryEntity>(
        title: l10n.category,
        options: options,
        getLabel: (c) => c.name,
        getLeading: (context, c) => AppIconBadge(
            color: Color(c.colorInt),
            child: CategoryIcon(
                iconKey: c.iconKey,
                size: context.metrics.iconSize,
                color: Color(c.colorInt))),
        getColor: (c) => Color(c.colorInt),
        isSelected: (c) =>
            c.id ==
            ref
                .read(transactionFormViewModelProvider(widget.transaction))
                .categoryId,
        onSelected: (c) => Navigator.pop(context, c.id),
        onManageTap: () => context.push('/categories_management'),
        manageButtonText: l10n.manageCategories,
      ),
    );
    if (result == null || !mounted) return;
    _vm.selectCategory(result);
  }

  static String _reminderLabel(AppLocalizations l10n, int? minutes) =>
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

  Future<void> _pickReminder(int? current) async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showDialog<int>(
        context: context,
        builder: (context) => SimpleDialog(
              title: Text(l10n.reminder),
              children: [
                for (final minutes in [0, 5, 10, 15, 30, 60, 1440])
                  FeatherDialogOption<int>(
                      label:
                          _reminderLabel(l10n, minutes == 0 ? null : minutes),
                      value: minutes,
                      groupValue: current ?? 0,
                      onChanged: (value) => Navigator.pop(context, value)),
                SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, -1),
                    child: Text(l10n.reminderCustom)),
              ],
            ));
    if (!mounted || choice == null) return;
    final minutes = choice == -1
        ? await showDialog<int>(
            context: context, builder: (_) => const CustomReminderDialog())
        : choice;
    if (!mounted || minutes == null) return;
    if (minutes == 0) {
      _vm.setReminderMinutes(null);
      return;
    }
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
    _vm.setReminderMinutes(minutes);
  }

  /// The repeat picker. Shaped like [_accountRow] because it is the same
  /// gesture, but over plain frequency strings rather than entities.
  Widget _repeatRow(
    AppLocalizations l10n,
    double labelWidth,
    TransactionFormViewState state,
  ) =>
      LedgerFormRow(
        card: true,
        icon: LucideIcons.repeat,
        onTap: () => _pickRepeat(state.repeat),
        child: LedgerSelectorField(
          alignEnd: true,
          label: l10n.repeat,
          labelWidth: labelWidth,
          text: _repeatOptionLabel(l10n, state.repeat),
        ),
      );

  /// Four plain options, and picking one is the whole answer — a menu, not a
  /// question, so it carries no confirm button. "Does not repeat" is not among
  /// them: the row only exists in a series mode, and the mode already said
  /// "repeats".
  ///
  /// The account and category rows open sheets instead because their lists are
  /// long and each row carries an icon, a balance and a way through to
  /// managing them. This one has nothing to manage and fits in a dialog.
  Future<void> _pickRepeat(String current) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.repeat),
        children: [
          for (final option in [
            ...TransactionFormViewState.repeatFrequencies,
            'CUSTOM'
          ])
            FeatherDialogOption<String>(
              label: _repeatOptionLabel(l10n, option),
              value: option,
              groupValue: current,
              onChanged: (value) => Navigator.pop(context, value),
            ),
        ],
      ),
    );
    if (!mounted || result == null) return;
    if (result != 'CUSTOM') {
      _vm.setRepeat(result);
      return;
    }
    final state =
        ref.read(transactionFormViewModelProvider(widget.transaction));
    final existing = state.customRecurrence;
    final start = state.date;
    final selected = await showDialog<CustomRecurrence>(
        context: context,
        builder: (_) => CustomRecurrenceDialog(
            initial: existing ??
                CustomRecurrence(
                    frequency:
                        state.repeat == 'CUSTOM' ? 'MONTHLY' : state.repeat,
                    interval: 1,
                    startDate: start,
                    weekdays: [start.weekday])));
    if (selected != null && mounted) _vm.setCustomRecurrence(selected);
  }

  /// What the row shows for a rule, and what its option says — one source, so
  /// the dialog cannot name a choice differently from the field that chose it.
  static String _repeatOptionLabel(AppLocalizations l10n, String value) =>
      value == TransactionFormViewState.repeatNever
          ? l10n.repeatNever
          : _frequencyLabel(l10n, value);

  static String _frequencyLabel(AppLocalizations l10n, String frequency) =>
      switch (frequency) {
        'CUSTOM' => l10n.customRepeat,
        'DAILY' => l10n.frequencyDaily,
        'WEEKLY' => l10n.frequencyWeekly,
        'YEARLY' => l10n.frequencyYearly,
        _ => l10n.frequencyMonthly,
      };

  /// One account field, used for all three kinds: the single account of an
  /// income/expense, and each leg of a transfer.
  Widget _accountRow({
    required Key fieldKey,
    required IconData icon,
    required String label,
    required double labelWidth,
    required List<AccountUiModel> options,
    required String? selectedId,
    required ValueChanged<String> onSelected,
    FormFieldValidator<String>? extraValidator,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // The FormField is an error slot, not a value holder: which account is
    // chosen lives in the view model, so "what is selected" has one answer
    // instead of two that have to be kept in step.
    return FormField<String>(
      key: fieldKey,
      validator: (_) {
        if (selectedId == null ||
            !options.any((a) => a.account.id == selectedId)) {
          return l10n.required;
        }
        return extraValidator?.call(selectedId);
      },
      builder: (field) {
        final selected =
            options.where((a) => a.account.id == selectedId).firstOrNull;
        return LedgerFormRow(
          card: true,
          icon: icon,
          onTap: () async {
            final result = await showModalBottomSheet<String>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (context) => LedgerSelectionSheet<AccountUiModel>(
                title: label,
                options: options,
                getLabel: (a) => a.account.name,
                // Each account's own currency, not the global display
                // preference: with transfers in this form the two legs can
                // be read side by side, and a shared symbol would mislabel
                // one of them whenever the accounts differ. The model has
                // already applied that rule.
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
                isSelected: (a) => a.account.id == selectedId,
                onSelected: (a) => Navigator.pop(context, a.account.id),
                onManageTap: () => context.push('/accounts_management'),
                manageButtonText: l10n.manageAccounts,
              ),
            );
            if (result != null) onSelected(result);
          },
          child: LedgerSelectorField(
            alignEnd: true,
            leading: selected == null
                ? null
                : LedgerAccountValueIcon(type: selected.account.type),
            label: label,
            labelWidth: labelWidth,
            text: selected?.account.name ??
                (field.hasError && selected == null
                    ? l10n.required
                    : l10n.select),
            textStyle: selected == null
                ? theme.textTheme.bodyLarge?.copyWith(
                    color: field.hasError
                        ? theme.colorScheme.error
                        : theme.hintColor)
                : null,
            errorText: selected == null || field.errorText == l10n.required
                ? null
                : field.errorText,
          ),
        );
      },
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          ref.read(transactionFormViewModelProvider(widget.transaction)).date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_current.date),
    );

    _vm.setDate(DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? _current.date.hour,
      time?.minute ?? _current.date.minute,
    ));
  }

  TransactionFormViewState get _current =>
      ref.read(transactionFormViewModelProvider(widget.transaction));

  void _submit() async {
    // Validation stays here: it is the Form's job, and the rows render their
    // own errors out of it.
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    final vm =
        ref.read(transactionFormViewModelProvider(widget.transaction).notifier);

    // The rule is the view model's; the question is the screen's.
    if (vm.wouldOverdraft()) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.overdraftWarningTitle),
          content: Text(l10n.overdraftWarningMessage),
          actions: [
            AppButton.text(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            AppButton.text(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.save),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    DateTime? materializeFrom;
    final now = ref.read(ledgerClockProvider).now();
    if (vm.needsDistantPastConfirmation(now)) {
      materializeFrom = await DistantPastStartDialog.show(
        context,
        startDate: vm.targetRepeatStartDate,
        now: now,
      );
      if (materializeFrom == null || !mounted) return;
    }

    final outcome = await vm.submit(materializeFrom: materializeFrom);
    if (!mounted) return;

    switch (outcome) {
      case TransactionFormSaveFailed(:final code):
        _report(code.message(l10n));
      case TransactionFormSaved(:final autoPostedCount):
        if (autoPostedCount > 0) {
          _report(l10n.autoPostedCountMessage(autoPostedCount));
        }
        context.pop();
    }
  }

  void _report(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

/// The three modes the form offers (see [TransactionFormMode]): what the entry
/// is, chosen before the details. Rendered only where a mode is meaningful —
/// a new income/expense entry.
class _TransactionFormModeSelector extends StatelessWidget {
  const _TransactionFormModeSelector({
    required this.selected,
    required this.onSelected,
    required this.l10n,
  });

  final TransactionFormMode selected;
  final ValueChanged<TransactionFormMode> onSelected;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AppChoiceChips<TransactionFormMode>(
      choices: [
        for (final mode in TransactionFormMode.values)
          ButtonSegment(value: mode, label: Text(_label(mode)))
      ],
      selected: selected,
      onSelected: onSelected,
    );
  }

  String _label(TransactionFormMode mode) => switch (mode) {
        TransactionFormMode.defaultMode => l10n.transactionModeDefault,
        TransactionFormMode.planned => l10n.transactionModePlanned,
        TransactionFormMode.repeating => l10n.transactionModeRepeating,
      };
}
