import 'package:json_annotation/json_annotation.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/events/ledger_event.dart';

part 'transaction_event.g.dart';

@JsonSerializable()
class TransactionLeg {
  final String accountId;
  final int amount; // Minor units (cents)
  final TransactionRole role; // 'outflow' or 'inflow'

  TransactionLeg({
    required this.accountId,
    required this.amount,
    required this.role,
  });

  factory TransactionLeg.fromJson(Map<String, dynamic> json) =>
      _$TransactionLegFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionLegToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TransactionPosted extends LedgerEvent {
  final String transactionId;
  final List<TransactionLeg> legs;
  final String description;
  final String categoryId;
  final List<String> tags;
  final String? notes;

  TransactionPosted({
    required super.eventId,
    required super.occurredAt,
    required super.recordedAt,
    required this.transactionId,
    required this.legs,
    required this.description,
    required this.categoryId,
    this.tags = const [],
    this.notes,
  });

  factory TransactionPosted.fromJson(Map<String, dynamic> json) =>
      _$TransactionPostedFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TransactionPostedToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TransactionReversed extends LedgerEvent {
  final String originalTransactionId;
  final String reason;

  TransactionReversed({
    required super.eventId,
    required super.occurredAt,
    required super.recordedAt,
    required this.originalTransactionId,
    required this.reason,
  });

  factory TransactionReversed.fromJson(Map<String, dynamic> json) =>
      _$TransactionReversedFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TransactionReversedToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TransactionScheduled extends LedgerEvent {
  final String seriesId;
  final DateTime nextOccurrence;

  TransactionScheduled({
    required super.eventId,
    required super.occurredAt,
    required super.recordedAt,
    required this.seriesId,
    required this.nextOccurrence,
  });

  factory TransactionScheduled.fromJson(Map<String, dynamic> json) =>
      _$TransactionScheduledFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TransactionScheduledToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TransactionPendingAdded extends LedgerEvent {
  final String transactionId;
  final double
      amount; // Placeholder, using double for now but should check conventions
  final String accountId;

  TransactionPendingAdded({
    required super.eventId,
    required super.occurredAt,
    required super.recordedAt,
    required this.transactionId,
    required this.amount,
    required this.accountId,
  });

  factory TransactionPendingAdded.fromJson(Map<String, dynamic> json) =>
      _$TransactionPendingAddedFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TransactionPendingAddedToJson(this);
}
