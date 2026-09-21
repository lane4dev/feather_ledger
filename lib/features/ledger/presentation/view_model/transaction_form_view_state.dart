import 'package:file_selector/file_selector.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/domain/model/transaction.dart';
import 'package:feather_ledger/shared/presentation/models/account_ui_model.dart';
import 'package:feather_ledger/shared/presentation/money_format.dart';

import '../models/transaction_tile_ui_model.dart';
import '../models/custom_recurrence.dart';

/// What the entry IS: a record, a plan, or a schedule.
///
/// Presentation-layer intent — the domain expresses the same things as a
/// one-shot series (计划: `startDate == endDate`) and an `autoPost` flag
/// (订阅), and has no mode concept. [TransactionFormMode.defaultMode] is a
/// plain recorded entry.
enum TransactionFormMode { defaultMode, planned, repeating }

/// What the transaction form is holding, and the rules that read it.
///
/// The amount is the **text** the field shows, not minor units: the field
/// cannot re-format while the user types without moving the caret, so the text
/// is what travels and the conversion happens once, where the value is used
/// ([amountMinor]). It is formatted once, here, when the form is seeded.
class TransactionFormViewState {
  /// The entry being corrected, or null when this form records a new one.
  final TransactionTileUiModel? original;

  final TransactionKind type;
  final DateTime date;
  final String amountText;

  /// The note's text; '' when empty.
  final String note;

  /// [repeatNever], or a code from [repeatOptions].
  final String repeat;
  final CustomRecurrence? customRecurrence;
  final int? reminderMinutes;

  /// What this entry is: a record, a plan, or a schedule. Only meaningful
  /// where [canRepeat] holds — the selector is not rendered otherwise.
  final TransactionFormMode mode;

  /// The debit leg: the account of an income/expense, and a transfer's **from**.
  final String? accountId;
  final String? categoryId;

  /// The credit leg. Only a transfer has one.
  final String? toAccountId;

  /// The currency this form is locked to: the current setting when a new
  /// form opens, the original account's currency when editing. Null means
  /// "not yet decided" and the screen falls back to the current setting.
  final String? currencyCode;

  /// Attachments already in app storage.
  final List<TransactionAttachment> attachments;

  /// Files the user picked, moved into app storage only when the entry is
  /// saved — so cancelling the form leaves nothing behind.
  final List<XFile> pendingAttachments;

  const TransactionFormViewState({
    required this.original,
    required this.type,
    required this.date,
    required this.amountText,
    required this.note,
    required this.repeat,
    this.customRecurrence,
    this.reminderMinutes,
    required this.mode,
    required this.accountId,
    required this.categoryId,
    required this.toAccountId,
    this.currencyCode,
    required this.attachments,
    required this.pendingAttachments,
  });

  static const repeatNever = 'NEVER';
  static const repeatFrequencies = ['DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY'];
  static const repeatOptions = [repeatNever, ...repeatFrequencies];

  /// A blank entry: the common case, and the one the FAB is for.
  factory TransactionFormViewState.initial({String? currencyCode}) =>
      TransactionFormViewState(
        original: null,
        type: TransactionKind.expense,
        date: DateTime.now(),
        amountText: '',
        note: '',
        repeat: repeatNever,
        mode: TransactionFormMode.defaultMode,
        accountId: null,
        categoryId: null,
        toAccountId: null,
        currencyCode: currencyCode,
        attachments: const [],
        pendingAttachments: const [],
      );

  /// Fills the form with the entry being corrected.
  factory TransactionFormViewState.fromTile(TransactionTileUiModel tile) =>
      TransactionFormViewState(
        original: tile,
        type: tile.type,
        date: tile.date,
        // A balance purpose's sign is part of its amount: the tile carries
        // them apart (amount always positive, direction in `displaySign`),
        // because a *row* says the direction with a label. A field cannot, so
        // the two are put back together here.
        amountText: tile.type.isBalancePurpose && tile.displaySign == '-'
            ? formatMinor(-tile.amount)
            : formatMinor(tile.amount),
        note: tile.note ?? '',
        // Editing never touches a series: changing a rule is "deactivate and
        // create another".
        repeat: repeatNever,
        mode: TransactionFormMode.defaultMode,
        accountId: tile.account.id,
        // The mapper hands a transfer an empty category; only a kind that
        // requires one gets to carry an id.
        categoryId: tile.type.requiresCategory ? tile.category?.id : null,
        toAccountId: tile.toAccount?.id,
        currencyCode: tile.account.currencyCode,
        attachments: tile.attachments,
        pendingAttachments: const [],
      );

  /// A field that reads null here means "leave it alone", which is the house
  /// convention — but three of these fields are nullable *and* have to be
  /// settable back to null: switching kind clears the category and the
  /// destination, and that is a real transition, not a missing argument. Those
  /// three take [_unset] as their default so an explicit null can mean "clear
  /// me" instead.
  static const _unset = Object();

  TransactionFormViewState copyWith({
    TransactionKind? type,
    DateTime? date,
    String? amountText,
    String? note,
    String? repeat,
    Object? customRecurrence = _unset,
    Object? reminderMinutes = _unset,
    TransactionFormMode? mode,
    Object? accountId = _unset,
    Object? categoryId = _unset,
    Object? toAccountId = _unset,
    String? currencyCode,
    List<TransactionAttachment>? attachments,
    List<XFile>? pendingAttachments,
  }) =>
      TransactionFormViewState(
        original: original,
        type: type ?? this.type,
        date: date ?? this.date,
        amountText: amountText ?? this.amountText,
        note: note ?? this.note,
        repeat: repeat ?? this.repeat,
        reminderMinutes: identical(reminderMinutes, _unset)
            ? this.reminderMinutes
            : reminderMinutes as int?,
        customRecurrence: identical(customRecurrence, _unset)
            ? this.customRecurrence
            : customRecurrence as CustomRecurrence?,
        mode: mode ?? this.mode,
        accountId: identical(accountId, _unset)
            ? this.accountId
            : accountId as String?,
        categoryId: identical(categoryId, _unset)
            ? this.categoryId
            : categoryId as String?,
        toAccountId: identical(toAccountId, _unset)
            ? this.toAccountId
            : toAccountId as String?,
        currencyCode: currencyCode ?? this.currencyCode,
        attachments: attachments ?? this.attachments,
        pendingAttachments: pendingAttachments ?? this.pendingAttachments,
      );

  bool get isEditing => original != null;
  bool get isTransfer => type == TransactionKind.transfer;
  bool get isBalancePurpose => type.isBalancePurpose;

  /// Whether this form can start a series at all: a series has one account, so
  /// a transfer cannot be one (ADR-0002), and a corrected entry does not touch
  /// its series.
  bool get canRepeat => !isTransfer && !isBalancePurpose && original == null;

  /// Whether the frequency row shows: only a series mode has a frequency, and
  /// only where [canRepeat] holds. Default and 计划 have none — the picker
  /// never offers "does not repeat", because the mode already answered that.
  bool get showsRepeatRow =>
      canRepeat && mode == TransactionFormMode.repeating;

  /// Whether the attachment row shows. A series row cannot carry attachments,
  /// and an invisible picked-files list would be a leak.
  bool get showsAttachments => mode != TransactionFormMode.planned;

  /// Whether saving creates a recurring series (重复).
  bool get wantsSeries => mode == TransactionFormMode.repeating;

  // Categories are typed by CategoryType, which has no transfer member; a
  // transfer has no category at all.
  CategoryType get categoryType => type == TransactionKind.income
      ? CategoryType.income
      : CategoryType.expense;

  /// What the field's formatter admits. Re-checked here so that reading the
  /// amount is total: [parseMinor] rejects sub-cent precision by throwing, and
  /// a getter that can throw from a build is a trap.
  static final _moneyText = RegExp(r'^\d*\.?\d{0,2}$');
  static final _signedMoneyText = RegExp(r'^-?\d*\.?\d{0,2}$');

  /// The amount in minor units — signed for a balance purpose, whose direction
  /// is the number itself. Null while the field is empty or not yet a number.
  int? get amountMinor {
    if (!(isBalancePurpose ? _signedMoneyText : _moneyText)
        .hasMatch(amountText)) {
      return null;
    }
    final parsed = double.tryParse(amountText);
    // Zero is not an amount, whichever way it points.
    if (parsed == null || parsed == 0) return null;
    // A kind that carries the direction does not let the number disagree with
    // it, so a minus typed into an income is not an amount either.
    if (!isBalancePurpose && parsed < 0) return null;
    return parseMinor(amountText);
  }

  int get attachmentCount => attachments.length + pendingAttachments.length;

  /// Accounts a picker may offer: an archived account is history, not a
  /// choice (spec 003, US3), and the form is locked to one currency — an
  /// account in another currency would change what the recorded amount means.
  List<AccountUiModel> activeAccounts(Iterable<AccountUiModel> all) => all
      .where((a) => !a.account.archived)
      .where((a) =>
          currencyCode == null || a.account.currencyCode == currencyCode)
      .toList();

  AccountUiModel? selectedAccount(Iterable<AccountUiModel> all) =>
      all.where((a) => a.account.id == accountId).firstOrNull;

  /// Where a transfer may land. Two rules, both of them invariants of the
  /// aggregate rather than preferences, so the pair is unreachable instead of
  /// chosen and then refused: a transfer needs two different accounts, and both
  /// legs are in one currency (cross-currency transfers wait for exchange
  /// rates).
  List<AccountUiModel> transferDestinations(Iterable<AccountUiModel> active) {
    final from = selectedAccount(active)?.account;
    return active
        .where((a) => a.account.id != accountId)
        .where(
            (a) => from == null || a.account.currencyCode == from.currencyCode)
        .toList();
  }
}
