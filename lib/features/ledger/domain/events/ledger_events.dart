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

  TransactionRecorded({
    required this.transactionId,
    required this.occurredAt,
    required this.kind,
    required this.description,
    this.notes,
    required this.postings,
  });

  @override
  String get eventType => 'TransactionRecorded';

  @override
  String get streamId => transactionId;

  @override
  Map<String, dynamic> toJson() => {
        'schemaVersion': 1,
        'transactionId': transactionId,
        'occurredAt': occurredAt.toIso8601String(),
        'kind': kind.name,
        'description': description,
        if (notes != null) 'notes': notes,
        'postings': postings.map((p) => p.toJson()).toList(),
      };

  factory TransactionRecorded.fromJson(Map<String, dynamic> json) =>
      TransactionRecorded(
        transactionId: json['transactionId'] as String,
        occurredAt: DateTime.parse(json['occurredAt'] as String),
        kind: TransactionKind.values.byName(json['kind'] as String),
        description: json['description'] as String,
        notes: json['notes'] as String?,
        postings: (json['postings'] as List)
            .map((e) => Posting.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
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

  /// Initial balance is deliberately absent — accounts are created at
  /// zero and a non-zero opening balance is a separate [OpeningBalanceSet].
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
  Map<String, dynamic> toJson() =>
      {'schemaVersion': 1, 'accountId': accountId};

  factory AccountArchived.fromJson(Map<String, dynamic> json) =>
      AccountArchived(accountId: json['accountId'] as String);
}

/// — Category stream ———————————————————————————————————————————————

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
        'schemaVersion': 1,
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

/// Sets an account's opening balance. Only legal at account creation; the
/// projector sets the balance to the absolute value of [amountMinor].
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
