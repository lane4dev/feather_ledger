/// Final ledger event payloads (spec 003, Event Model / 事件目录).
///
/// Nine event types, all amounts int minor units. Each payload knows its
/// stable [eventType] string (Dart class name — never persisted via
/// `runtimeType.toString()`) and serializes with an embedded
/// `schemaVersion`.
///
/// Envelope-level fields (eventId, streamId, streamVersion, GSN,
/// occurredAt, recordedAt, commandId) are *not* duplicated here; payloads
/// carry business data only and travel inside `EventEnvelope.payloadJson`.
library;

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/constants/category_constants.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';

import '../model/transaction.dart';

/// Contract every final event payload implements.
abstract interface class LedgerEventPayload {
  /// Stable persistence string == Dart class name.
  String get eventType;

  /// Aggregate root id this event belongs to (transaction/account/category
  /// id) — matches `EventEnvelope.streamId`.
  String get streamId;

  Map<String, dynamic> toJson();
}

/// Builds a spec envelope around a final payload (spec 003, Event Model).
/// Used by the US3+ commands; [streamVersion] is the payload's position on
/// its aggregate stream (0 for a fresh aggregate).
EventEnvelope envelopeFor(
  LedgerEventPayload payload, {
  required AggregateType aggregateType,
  required int streamVersion,
  required String commandId,
  required String eventId,
  DateTime? occurredAt,
}) =>
    EventEnvelope(
      eventId: eventId,
      streamId: payload.streamId,
      aggregateType: aggregateType,
      eventType: payload.eventType,
      streamVersion: streamVersion,
      payloadJson: payload.toJson(),
      occurredAt: occurredAt ?? DateTime.now(),
      recordedAt: DateTime.now(),
      commandId: commandId,
    );

/// — Transaction stream ——————————————————————————————————————————————

class TransactionRecorded implements LedgerEventPayload {
  final String transactionId;
  final DateTime occurredAt;
  final TransactionKind kind;
  final String description;
  final String? notes;
  final List<Posting> postings;
  final List<TransactionAttachment> attachments;
  final String? categorySnapshotName;
  final String? categorySnapshotIcon;
  final String? categorySnapshotColor;

  /// The scheduled bill (its instance id) this transaction was posted from,
  /// carried on the *event* so the source-bill → latest-transaction link
  /// survives corrections and rebuilds (spec 006, US47). Null for every
  /// transaction that did not come from a scheduled bill.
  final String? sourceScheduledBillId;

  TransactionRecorded({
    required this.transactionId,
    required this.occurredAt,
    required this.kind,
    required this.description,
    this.notes,
    required this.postings,
    this.attachments = const [],
    this.categorySnapshotName,
    this.categorySnapshotIcon,
    this.categorySnapshotColor,
    this.sourceScheduledBillId,
  });

  @override
  String get eventType => 'TransactionRecorded';

  @override
  String get streamId => transactionId;

  @override
  Map<String, dynamic> toJson() => {
        'schemaVersion': 4,
        'transactionId': transactionId,
        'occurredAt': occurredAt.toIso8601String(),
        'kind': kind.name,
        'description': description,
        if (notes != null) 'notes': notes,
        if (sourceScheduledBillId != null)
          'sourceScheduledBillId': sourceScheduledBillId,
        'postings': postings.map((p) => p.toJson()).toList(),
        'attachments': attachments.map((a) => a.toJson()).toList(),
        if (categorySnapshotName != null)
          'categorySnapshot': {
            'name': categorySnapshotName,
            'icon': categorySnapshotIcon,
            'color': categorySnapshotColor,
          },
      };

  factory TransactionRecorded.fromJson(Map<String, dynamic> json) =>
      TransactionRecorded(
        transactionId: json['transactionId'] as String,
        occurredAt: DateTime.parse(json['occurredAt'] as String),
        kind: TransactionKind.values.byName(json['kind'] as String),
        description: json['description'] as String,
        notes: json['notes'] as String?,
        sourceScheduledBillId: json['sourceScheduledBillId'] as String?,
        categorySnapshotName:
            (json['categorySnapshot'] as Map?)?['name'] as String?,
        categorySnapshotIcon:
            (json['categorySnapshot'] as Map?)?['icon'] as String?,
        categorySnapshotColor:
            (json['categorySnapshot'] as Map?)?['color'] as String?,
        postings: (json['postings'] as List)
            .map((e) => Posting.fromJson(e as Map<String, dynamic>))
            .toList(),
        attachments: (json['attachments'] as List? ?? const [])
            .map((e) => TransactionAttachment.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

/// Compatibility interpretation for records written before balance purposes
/// existed. Their immutable events remain income/expense rows using fixed
/// system category IDs; projection replay derives the modern purpose from
/// that stable identity. Account creation used a derived command id ending in
/// `-opening`, which distinguishes its opening record from later adjustments.
///
/// **The event's `kind` and the projected `kind` disagree on purpose**, and
/// this function is the whole of the disagreement: for these rows
/// `transactions_view.kind` says `openingBalance`/`balanceAdjustment` while
/// the payload still says `income`/`expense`. That is not drift to be
/// reconciled — *the event is history and the view is the reading of it*, and
/// rewriting the payload would mean editing immutable events to say something
/// their author never wrote. So: never "fix" a stored payload to match this,
/// and never read the payload's kind to decide how a ledger row behaves.
///
/// The `-opening` suffix is a string test on a command id, which is only
/// tolerable because the set of writers it has to recognise is closed — the
/// old `createAccount` derived that suffix, the old `adjustAccountBalance`
/// minted a UUID, and neither producer exists any more. Anything that writes
/// these kinds from now on chooses the kind directly.
TransactionKind projectedTransactionKind(
  TransactionRecorded transaction, {
  required String commandId,
}) {
  final categoryId = transaction.postings.isEmpty
      ? null
      : transaction.postings.first.categoryId;
  final isLegacyBalanceCategory =
      categoryId == CategoryConstants.reversalIncomeId ||
          categoryId == CategoryConstants.reversalExpenseId;
  if (!isLegacyBalanceCategory) return transaction.kind;
  return commandId.endsWith('-opening')
      ? TransactionKind.openingBalance
      : TransactionKind.balanceAdjustment;
}

/// Reversal reason: UI delete vs. edit-as-reverse-and-re-record.
enum ReversalReason { userDeleted, correction }

class TransactionReversed implements LedgerEventPayload {
  final String originalTransactionId;
  final ReversalReason reason;

  TransactionReversed({
    required this.originalTransactionId,
    required this.reason,
  });

  @override
  String get eventType => 'TransactionReversed';

  @override
  String get streamId => originalTransactionId;

  @override
  Map<String, dynamic> toJson() => {
        'schemaVersion': 1,
        'originalTransactionId': originalTransactionId,
        'reason': reason.name,
      };

  factory TransactionReversed.fromJson(Map<String, dynamic> json) =>
      TransactionReversed(
        originalTransactionId: json['originalTransactionId'] as String,
        reason: ReversalReason.values.byName(json['reason'] as String),
      );
}

/// — Account stream ————————————————————————————————————————————————

class AccountCreated implements LedgerEventPayload {
  final String accountId;
  final String name;
  final AccountType type;
  final String currencyCode;

  /// Initial balance is deliberately absent — accounts are created at zero
  /// and a non-zero opening balance is a separate `TransactionRecorded`
  /// whose kind is `openingBalance`. [OpeningBalanceSet] remains readable
  /// for legacy streams only.
  AccountCreated({
    required this.accountId,
    required this.name,
    required this.type,
    required this.currencyCode,
  });

  @override
  String get eventType => 'AccountCreated';

  @override
  String get streamId => accountId;

  @override
  Map<String, dynamic> toJson() => {
        'schemaVersion': 1,
        'accountId': accountId,
        'name': name,
        'type': type.name,
        'currencyCode': currencyCode,
      };

  factory AccountCreated.fromJson(Map<String, dynamic> json) => AccountCreated(
        accountId: json['accountId'] as String,
        name: json['name'] as String,
        type: AccountType.values.byName(json['type'] as String),
        currencyCode: json['currencyCode'] as String,
      );
}

class AccountRenamed implements LedgerEventPayload {
  final String accountId;
  final String name;

  AccountRenamed({required this.accountId, required this.name});

  @override
  String get eventType => 'AccountRenamed';

  @override
  String get streamId => accountId;

  @override
  Map<String, dynamic> toJson() =>
      {'schemaVersion': 1, 'accountId': accountId, 'name': name};

  factory AccountRenamed.fromJson(Map<String, dynamic> json) => AccountRenamed(
        accountId: json['accountId'] as String,
        name: json['name'] as String,
      );
}

class AccountArchived implements LedgerEventPayload {
  final String accountId;

  AccountArchived({required this.accountId});

  @override
  String get eventType => 'AccountArchived';

  @override
  String get streamId => accountId;

  @override
  Map<String, dynamic> toJson() => {'schemaVersion': 1, 'accountId': accountId};

  factory AccountArchived.fromJson(Map<String, dynamic> json) =>
      AccountArchived(accountId: json['accountId'] as String);
}

class AccountRestored implements LedgerEventPayload {
  final String accountId;
  AccountRestored({required this.accountId});
  @override
  String get eventType => 'AccountRestored';
  @override
  String get streamId => accountId;
  @override
  Map<String, dynamic> toJson() => {'schemaVersion': 1, 'accountId': accountId};
  factory AccountRestored.fromJson(Map<String, dynamic> json) =>
      AccountRestored(accountId: json['accountId'] as String);
}

class AccountDeleted implements LedgerEventPayload {
  final String accountId;
  AccountDeleted({required this.accountId});
  @override
  String get eventType => 'AccountDeleted';
  @override
  String get streamId => accountId;
  @override
  Map<String, dynamic> toJson() => {'schemaVersion': 1, 'accountId': accountId};
  factory AccountDeleted.fromJson(Map<String, dynamic> json) =>
      AccountDeleted(accountId: json['accountId'] as String);
}

/// An account was included in, or taken out of, the **ledger totals**
/// (CONTEXT.md).
///
/// An account is created counting (the projection's column default is true,
/// and this event is the only thing that ever writes `false`). So creating an
/// account with the switch already off is two events — `AccountCreated`, then
/// this one — the same shape as a starting balance, which is `AccountCreated`
/// followed by a transaction. Payload version 1 and it stays there: nothing
/// about the existing events had to change to make room for this.
///
/// Nothing behind the totals is recomputed when this lands. The figures are
/// summed at read time, so flipping the flag changes which rows a sum walks,
/// never what any row says — see `WatchMonthlySnapshotQuery`. Mirroring
/// [AccountArchived], which likewise refreshes no snapshot.
class AccountTotalsInclusionChanged implements LedgerEventPayload {
  final String accountId;
  final bool includeInTotals;

  AccountTotalsInclusionChanged({
    required this.accountId,
    required this.includeInTotals,
  });

  @override
  String get eventType => 'AccountTotalsInclusionChanged';

  @override
  String get streamId => accountId;

  @override
  Map<String, dynamic> toJson() => {
        'schemaVersion': 1,
        'accountId': accountId,
        'includeInTotals': includeInTotals,
      };

  factory AccountTotalsInclusionChanged.fromJson(Map<String, dynamic> json) =>
      AccountTotalsInclusionChanged(
        accountId: json['accountId'] as String,
        includeInTotals: json['includeInTotals'] as bool,
      );
}

/// — Category stream ———————————————————————————————————————————————

/// A category was created.
///
/// **v2 changed what [iconKey] means.** v1 stored a Material Icons code point;
/// v2 stores a Lucide one, because the app's icons moved to that set. The
/// field is still an opaque string of digits to everything that only stores
/// and compares it; only the renderer and the palette care which font it names.
/// An upcaster translates v1 payloads — see `register_ledger_events.dart`.
class CategoryCreated implements LedgerEventPayload {
  final String categoryId;
  final String name;
  final String iconKey;
  final int colorInt;

  /// income / expense (category kind, not transaction kind).
  final CategoryType type;
  final String? systemCode;

  CategoryCreated({
    required this.categoryId,
    required this.name,
    required this.iconKey,
    required this.colorInt,
    required this.type,
    this.systemCode,
  });

  @override
  String get eventType => 'CategoryCreated';

  @override
  String get streamId => categoryId;

  @override
  Map<String, dynamic> toJson() => {
        'schemaVersion': 2,
        'categoryId': categoryId,
        'name': name,
        'iconKey': iconKey,
        'colorInt': colorInt,
        'type': type.name,
        if (systemCode != null) 'systemCode': systemCode,
      };

  factory CategoryCreated.fromJson(Map<String, dynamic> json) =>
      CategoryCreated(
        categoryId: json['categoryId'] as String,
        name: json['name'] as String,
        iconKey: json['iconKey'] as String,
        colorInt: json['colorInt'] as int,
        type: CategoryType.values.byName(json['type'] as String),
        systemCode: json['systemCode'] as String?,
      );
}

/// A category's current appearance; transaction snapshots remain unchanged.
class CategoryAppearanceChanged implements LedgerEventPayload {
  final String categoryId;
  final String iconKey;
  final int colorInt;

  CategoryAppearanceChanged(
      {required this.categoryId,
      required this.iconKey,
      required this.colorInt});

  @override
  String get eventType => 'CategoryAppearanceChanged';

  @override
  String get streamId => categoryId;

  @override
  Map<String, dynamic> toJson() => {
        'schemaVersion': 1,
        'categoryId': categoryId,
        'iconKey': iconKey,
        'colorInt': colorInt,
      };

  factory CategoryAppearanceChanged.fromJson(Map<String, dynamic> json) =>
      CategoryAppearanceChanged(
        categoryId: json['categoryId'] as String,
        iconKey: json['iconKey'] as String,
        colorInt: json['colorInt'] as int,
      );
}

class CategoryRenamed implements LedgerEventPayload {
  final String categoryId;
  final String name;

  CategoryRenamed({required this.categoryId, required this.name});

  @override
  String get eventType => 'CategoryRenamed';

  @override
  String get streamId => categoryId;

  @override
  Map<String, dynamic> toJson() =>
      {'schemaVersion': 1, 'categoryId': categoryId, 'name': name};

  factory CategoryRenamed.fromJson(Map<String, dynamic> json) =>
      CategoryRenamed(
        categoryId: json['categoryId'] as String,
        name: json['name'] as String,
      );
}

class CategoryArchived implements LedgerEventPayload {
  final String categoryId;

  CategoryArchived({required this.categoryId});

  @override
  String get eventType => 'CategoryArchived';

  @override
  String get streamId => categoryId;

  @override
  Map<String, dynamic> toJson() =>
      {'schemaVersion': 1, 'categoryId': categoryId};

  factory CategoryArchived.fromJson(Map<String, dynamic> json) =>
      CategoryArchived(categoryId: json['categoryId'] as String);
}

/// — Account opening balance ————————————————————————————————————————

/// Legacy opening-balance payload retained to rebuild historical streams.
/// New commands never emit it: it cannot display a ledger row or preserve a
/// signed liability balance, both of which `TransactionRecorded` with
/// `openingBalance` does.
class OpeningBalanceSet implements LedgerEventPayload {
  final String accountId;
  final int amountMinor;
  final String currencyCode;

  OpeningBalanceSet({
    required this.accountId,
    required this.amountMinor,
    required this.currencyCode,
  });

  @override
  String get eventType => 'OpeningBalanceSet';

  @override
  String get streamId => accountId;

  @override
  Map<String, dynamic> toJson() => {
        'schemaVersion': 1,
        'accountId': accountId,
        'amountMinor': amountMinor,
        'currencyCode': currencyCode,
      };

  factory OpeningBalanceSet.fromJson(Map<String, dynamic> json) =>
      OpeningBalanceSet(
        accountId: json['accountId'] as String,
        amountMinor: json['amountMinor'] as int,
        currencyCode: json['currencyCode'] as String,
      );
}
