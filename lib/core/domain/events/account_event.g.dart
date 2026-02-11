// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountCreated _$AccountCreatedFromJson(Map<String, dynamic> json) =>
    AccountCreated(
      eventId: json['eventId'] as String,
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      accountId: json['accountId'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$AccountTypeEnumMap, json['type']),
      initialBalance: (json['initialBalance'] as num).toInt(),
    )..id = (json['id'] as num?)?.toInt();

Map<String, dynamic> _$AccountCreatedToJson(AccountCreated instance) =>
    <String, dynamic>{
      'id': instance.id,
      'eventId': instance.eventId,
      'occurredAt': instance.occurredAt.toIso8601String(),
      'recordedAt': instance.recordedAt.toIso8601String(),
      'accountId': instance.accountId,
      'name': instance.name,
      'type': _$AccountTypeEnumMap[instance.type]!,
      'initialBalance': instance.initialBalance,
    };

const _$AccountTypeEnumMap = {
  AccountType.cash: 'cash',
  AccountType.bank: 'bank',
  AccountType.credit: 'credit',
  AccountType.other: 'other',
};

AccountUpdated _$AccountUpdatedFromJson(Map<String, dynamic> json) =>
    AccountUpdated(
      eventId: json['eventId'] as String,
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      accountId: json['accountId'] as String,
      name: json['name'] as String?,
      type: $enumDecodeNullable(_$AccountTypeEnumMap, json['type']),
    )..id = (json['id'] as num?)?.toInt();

Map<String, dynamic> _$AccountUpdatedToJson(AccountUpdated instance) =>
    <String, dynamic>{
      'id': instance.id,
      'eventId': instance.eventId,
      'occurredAt': instance.occurredAt.toIso8601String(),
      'recordedAt': instance.recordedAt.toIso8601String(),
      'accountId': instance.accountId,
      'name': instance.name,
      'type': _$AccountTypeEnumMap[instance.type],
    };

AccountDeleted _$AccountDeletedFromJson(Map<String, dynamic> json) =>
    AccountDeleted(
      eventId: json['eventId'] as String,
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      accountId: json['accountId'] as String,
    )..id = (json['id'] as num?)?.toInt();

Map<String, dynamic> _$AccountDeletedToJson(AccountDeleted instance) =>
    <String, dynamic>{
      'id': instance.id,
      'eventId': instance.eventId,
      'occurredAt': instance.occurredAt.toIso8601String(),
      'recordedAt': instance.recordedAt.toIso8601String(),
      'accountId': instance.accountId,
    };
