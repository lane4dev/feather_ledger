// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransactionLeg _$TransactionLegFromJson(Map<String, dynamic> json) =>
    TransactionLeg(
      accountId: json['accountId'] as String,
      amount: (json['amount'] as num).toInt(),
      role: $enumDecode(_$TransactionRoleEnumMap, json['role']),
    );

Map<String, dynamic> _$TransactionLegToJson(TransactionLeg instance) =>
    <String, dynamic>{
      'accountId': instance.accountId,
      'amount': instance.amount,
      'role': _$TransactionRoleEnumMap[instance.role]!,
    };

const _$TransactionRoleEnumMap = {
  TransactionRole.outflow: 'outflow',
  TransactionRole.inflow: 'inflow',
};

TransactionPosted _$TransactionPostedFromJson(Map<String, dynamic> json) =>
    TransactionPosted(
      eventId: json['eventId'] as String,
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      transactionId: json['transactionId'] as String,
      legs: (json['legs'] as List<dynamic>)
          .map((e) => TransactionLeg.fromJson(e as Map<String, dynamic>))
          .toList(),
      description: json['description'] as String,
      categoryId: json['categoryId'] as String,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      notes: json['notes'] as String?,
    )..id = (json['id'] as num?)?.toInt();

Map<String, dynamic> _$TransactionPostedToJson(TransactionPosted instance) =>
    <String, dynamic>{
      'id': instance.id,
      'eventId': instance.eventId,
      'occurredAt': instance.occurredAt.toIso8601String(),
      'recordedAt': instance.recordedAt.toIso8601String(),
      'transactionId': instance.transactionId,
      'legs': instance.legs.map((e) => e.toJson()).toList(),
      'description': instance.description,
      'categoryId': instance.categoryId,
      'tags': instance.tags,
      'notes': instance.notes,
    };

TransactionReversed _$TransactionReversedFromJson(Map<String, dynamic> json) =>
    TransactionReversed(
      eventId: json['eventId'] as String,
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      originalTransactionId: json['originalTransactionId'] as String,
      reason: json['reason'] as String,
    )..id = (json['id'] as num?)?.toInt();

Map<String, dynamic> _$TransactionReversedToJson(
        TransactionReversed instance) =>
    <String, dynamic>{
      'id': instance.id,
      'eventId': instance.eventId,
      'occurredAt': instance.occurredAt.toIso8601String(),
      'recordedAt': instance.recordedAt.toIso8601String(),
      'originalTransactionId': instance.originalTransactionId,
      'reason': instance.reason,
    };

TransactionScheduled _$TransactionScheduledFromJson(
        Map<String, dynamic> json) =>
    TransactionScheduled(
      eventId: json['eventId'] as String,
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      seriesId: json['seriesId'] as String,
      nextOccurrence: DateTime.parse(json['nextOccurrence'] as String),
    )..id = (json['id'] as num?)?.toInt();

Map<String, dynamic> _$TransactionScheduledToJson(
        TransactionScheduled instance) =>
    <String, dynamic>{
      'id': instance.id,
      'eventId': instance.eventId,
      'occurredAt': instance.occurredAt.toIso8601String(),
      'recordedAt': instance.recordedAt.toIso8601String(),
      'seriesId': instance.seriesId,
      'nextOccurrence': instance.nextOccurrence.toIso8601String(),
    };

TransactionPendingAdded _$TransactionPendingAddedFromJson(
        Map<String, dynamic> json) =>
    TransactionPendingAdded(
      eventId: json['eventId'] as String,
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      transactionId: json['transactionId'] as String,
      amount: (json['amount'] as num).toDouble(),
      accountId: json['accountId'] as String,
    )..id = (json['id'] as num?)?.toInt();

Map<String, dynamic> _$TransactionPendingAddedToJson(
        TransactionPendingAdded instance) =>
    <String, dynamic>{
      'id': instance.id,
      'eventId': instance.eventId,
      'occurredAt': instance.occurredAt.toIso8601String(),
      'recordedAt': instance.recordedAt.toIso8601String(),
      'transactionId': instance.transactionId,
      'amount': instance.amount,
      'accountId': instance.accountId,
    };
