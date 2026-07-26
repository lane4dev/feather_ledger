import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feather_ledger/app/theme/category_tokens.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/features/ledger/domain/model/transaction.dart';
import 'package:feather_ledger/features/ledger/presentation/theme/ledger_theme.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/shared/presentation/models/account_ui_model.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_dialog_option.dart';
import 'package:feather_ledger/shared/presentation/extensions/account_type_extension.dart';
import 'package:feather_ledger/shared/presentation/ledger_error_localizer.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/transaction_date_label.dart';
import '../models/transaction_tile_ui_model.dart';

import '../view_model/transaction_form_view_model.dart';
import '../view_model/transaction_form_view_state.dart';
import '../widgets/ledger_amount_input.dart';
import '../widgets/ledger_form_row.dart';
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
    final currencyKey = ref.watch(currencyControllerProvider).value ??
        AppCurrencies.supportedCurrencyCodes.first;

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
    final labelWidth = LedgerTheme.formLabelWidth(context, [
      l10n.transactionType,
      l10n.date,
      l10n.repeat,
      l10n.account,
      l10n.transferFrom,
      l10n.transferTo,
      l10n.category,
      l10n.note,
      l10n.attachments,
    ]);

    // Same currency is an aggregate invariant, so the eligible destinations
    // are narrowed rather than letting the pair be chosen and refused. The
    // list is empty until a source is picked, which is also the honest answer.
    final toAccountOptions = state.transferDestinations(activeAccounts);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
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
            // No horizontal padding: it would clip every row's ripple a page
            // margin short of the edge. The rows inset their own contents
            // (LedgerFormRow) and everything else in the column is wrapped in
            // [_inset].
            padding: EdgeInsets.symmetric(vertical: context.spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transaction kind and amount describe the same action, so
                // they intentionally read as one compact primary module.
                if (!state.isBalancePurpose)
                  _inset(
                    LedgerTypeSelector(
                      selectedType: state.type,
                      onSelectionChanged: vm.setType,
                      widthFactor: 0.72,
                    ),
                  )
                else
                  LedgerFormRow(
                    icon: LucideIcons.badgeInfo,
                    child: LedgerSelectorField(
                      label: l10n.transactionType,
                      labelWidth: labelWidth,
                      text: state.type == TransactionKind.openingBalance
                          ? l10n.initialBalance
                          : l10n.accountBalanceAdjustmentDescription,
                    ),
                  ),
                SizedBox(height: context.spacing.xl),

                // The large amount gets the same visual prominence as an event
                // title while keeping its numeric validation in LedgerAmountInput.
                _inset(
                  LedgerAmountInput(
                    controller: _amountController,
                    onChanged: vm.setAmountText,
                    type: state.type,
                    currencySymbol: currencySymbol,
                    autofocus: !state.isEditing,
                  ),
                ),
                SizedBox(height: context.spacing.lg),

                _inset(const FeatherDivider()),
                SizedBox(height: context.spacing.sm),

                // Time information stays together: when it happened,
                // then whether it will happen again.
                LedgerFormRow(
                  icon: LucideIcons.clock,
                  onTap: _pickDateTime,
                  child: LedgerSelectorField(
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

                if (state.canRepeat) ...[
                  const SizedBox(height: 8),
                  _repeatRow(l10n, labelWidth, state),
                ],

                SizedBox(height: context.spacing.sm),
                _inset(const FeatherDivider()),
                SizedBox(height: context.spacing.sm),

                // Where the money moved, then what it was for: an account is
                // the one field every kind has, and the category names the
                // entry rather than the movement. A transfer keeps its
                // explicit two accounts and has no category at all.
                if (state.isBalancePurpose)
                  LedgerFormRow(
                    icon: LucideIcons.wallet,
                    child: LedgerSelectorField(
                      label: l10n.account,
                      labelWidth: labelWidth,
                      text: state.original!.account.name,
                    ),
                  )
                else
                  _accountRow(
                    fieldKey: ValueKey('account-${state.type}'),
                    icon: state.isTransfer
                        ? LucideIcons.arrowUp
                        : LucideIcons.wallet,
                    // A transfer's debit leg is its "from" side, and saying so is
                    // the whole point of the screen — the same labels the detail
                    // sheet uses.
                    label: state.isTransfer ? l10n.transferFrom : l10n.account,
                    labelWidth: labelWidth,
                    options: activeAccounts,
                    selectedId: state.accountId,
                    onSelected: vm.selectAccount,
                  ),

                if (state.isTransfer) ...[
                  const SizedBox(height: 8),
                  _accountRow(
                    fieldKey: ValueKey('to-account-${state.accountId}'),
                    icon: LucideIcons.arrowDown,
                    label: l10n.transferTo,
                    labelWidth: labelWidth,
                    options: toAccountOptions,
                    selectedId: state.toAccountId,
                    onSelected: vm.selectToAccount,
                    // Defence in depth: the options already exclude it, but the
                    // aggregate is the real guard and this keeps an unreachable
                    // state from becoming reachable through a refactor.
                    extraValidator: (value) =>
                        value != null && value == state.accountId
                            ? l10n.errorSameAccountTransfer
                            : null,
                  ),
                ],

                if (!state.isTransfer && !state.isBalancePurpose) ...[
                  const SizedBox(height: 8),
                  // The FormField is pulled out of the stream's branches so
                  // the row — and with it the tap target and the icon column —
                  // is the same widget in every state. Inside `.when`, the
                  // loading branch would lose its icon and shift the bar left.
                  FormField<String>(
                    // A fresh error slot when the kind changes: a failed save
                    // leaves an error on this row, and the value that failed
                    // has nothing to do with the kind that just replaced it.
                    key: ValueKey('category-${state.type}'),
                    validator: (_) =>
                        state.categoryId == null ? l10n.required : null,
                    builder: (field) => LedgerFormRow(
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
                          final selected = categories
                              .where((c) => c.id == state.categoryId)
                              .firstOrNull;
                          return LedgerSelectorField(
                            label: l10n.category,
                            labelWidth: labelWidth,
                            text: selected?.name ?? l10n.select,
                            textStyle: selected == null
                                ? theme.textTheme.bodyLarge
                                    ?.copyWith(color: theme.hintColor)
                                : null,
                            errorText: field.hasError ? field.errorText : null,
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const SizedBox(),
                      ),
                    ),
                  ),
                ],

                SizedBox(height: context.spacing.sm),
                _inset(const FeatherDivider()),
                SizedBox(height: context.spacing.sm),

                // 6. Note. Named in the same column as every other field, and
                //    typed from the same edge as every other value — it is a
                //    value like the rest, not a right-aligned caption.
                LedgerFormRow(
                  icon: LucideIcons.stickyNote,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: SizedBox(
                          width: labelWidth,
                          child: Text(
                            l10n.note,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ),
                      const SizedBox(width: LedgerTheme.formLabelGap),
                      Expanded(
                        child: TextFormField(
                          controller: _noteController,
                          onChanged: vm.setNote,
                          decoration: InputDecoration(
                            // The name is in the column to the left, so the
                            // hint says what to write rather than repeating it
                            // — and in the same low-emphasis grey the other
                            // rows use for "nothing chosen yet".
                            hintText: l10n.noteHint,
                            hintStyle: theme.textTheme.bodyLarge
                                ?.copyWith(color: theme.hintColor),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                            isDense: true,
                          ),
                          minLines: 1,
                          maxLines: 3,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: context.spacing.sm),

                // Files are listed in-place like Calendar attachments. They are
                // imported only when Save is pressed, so cancelling is clean.
                _attachmentRow(l10n, labelWidth, state),

                SizedBox(height: context.spacing.sm),

                SizedBox(height: context.spacing.xl),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: kThemeAnimationDuration,
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(
          context.spacing.lg,
          context.spacing.sm,
          context.spacing.lg,
          MediaQuery.viewInsetsOf(context).bottom + context.spacing.sm,
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: AppButton(
              onPressed: _submit,
              child: Text(l10n.save),
            ),
          ),
        ),
      ),
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
        padding: LedgerTheme.pageInset(context),
        child: child,
      );

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
        // The icon column's width (24 icon + 24 padding), so the names line up
        // under the field's name rather than under the icon.
        _inset(
          Padding(
            padding: const EdgeInsets.only(left: 48),
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
          IconButton(
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
        getIcon: (c) => CategoryTokens.iconFor(c.iconKey),
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

  /// The repeat picker. Shaped like [_accountRow] because it is the same
  /// gesture, but over plain frequency strings rather than entities.
  Widget _repeatRow(
    AppLocalizations l10n,
    double labelWidth,
    TransactionFormViewState state,
  ) =>
      LedgerFormRow(
        icon: LucideIcons.repeat,
        onTap: () => _pickRepeat(state.repeat),
        child: LedgerSelectorField(
          label: l10n.repeat,
          labelWidth: labelWidth,
          text: _repeatOptionLabel(l10n, state.repeat),
        ),
      );

  /// Five plain options, and picking one is the whole answer — a menu, not a
  /// question, so it carries no confirm button.
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
          for (final option in TransactionFormViewState.repeatOptions)
            FeatherDialogOption<String>(
              label: _repeatOptionLabel(l10n, option),
              value: option,
              groupValue: current,
              onChanged: (value) => Navigator.pop(context, value),
            ),
        ],
      ),
    );
    if (result != null) _vm.setRepeat(result);
  }

  /// What the row shows for a rule, and what its option says — one source, so
  /// the dialog cannot name a choice differently from the field that chose it.
  static String _repeatOptionLabel(AppLocalizations l10n, String value) =>
      value == TransactionFormViewState.repeatNever
          ? l10n.repeatNever
          : _frequencyLabel(l10n, value);

  static String _frequencyLabel(AppLocalizations l10n, String frequency) =>
      switch (frequency) {
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
    // instead of two that have to be kept in step. The row still lives inside
    // the builder so the error draws under the value's column.
    return FormField<String>(
      key: fieldKey,
      validator: (_) {
        if (selectedId == null) return l10n.required;
        return extraValidator?.call(selectedId);
      },
      builder: (field) {
        final selected =
            options.where((a) => a.account.id == selectedId).firstOrNull;
        return LedgerFormRow(
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
            label: label,
            labelWidth: labelWidth,
            text: selected?.account.name ?? l10n.select,
            textStyle: selected == null
                ? theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor)
                : null,
            errorText: field.hasError ? field.errorText : null,
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
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.save),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    final outcome = await vm.submit();
    if (!mounted) return;

    switch (outcome) {
      case TransactionFormSaveFailed(:final code):
        _report(code.message(l10n));
      case TransactionFormSavedSeriesFailed(:final code):
        // The snackbar first: it lives on the messenger above this route, so
        // it survives the pop. The entry itself was recorded.
        _report(l10n.repeatSetupFailed(code.message(l10n)));
        context.pop();
      case TransactionFormSaved():
        context.pop();
    }
  }

  void _report(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
