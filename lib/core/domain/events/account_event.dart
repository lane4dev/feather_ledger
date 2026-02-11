import 'package:json_annotation/json_annotation.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/events/ledger_event.dart';

part 'account_event.g.dart';

@JsonSerializable(explicitToJson: true)
class AccountCreated extends LedgerEvent {
  final String accountId;
  final String name;
  final AccountType type;
  final int initialBalance; // Minor units

  AccountCreated({
    required super.eventId,
    required super.occurredAt,
    required super.recordedAt,
    required this.accountId,
    required this.name,
    required this.type,
    required this.initialBalance,
  });

  factory AccountCreated.fromJson(Map<String, dynamic> json) =>
      _$AccountCreatedFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AccountCreatedToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AccountUpdated extends LedgerEvent {
  final String accountId;
  final String? name;
  final AccountType? type;

  AccountUpdated({
    required super.eventId,
    required super.occurredAt,
    required super.recordedAt,
    required this.accountId,
    this.name,
    this.type,
  });

  factory AccountUpdated.fromJson(Map<String, dynamic> json) =>
      _$AccountUpdatedFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AccountUpdatedToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AccountDeleted extends LedgerEvent {
  final String accountId;

  AccountDeleted({
    required super.eventId,
    required super.occurredAt,
    required super.recordedAt,
    required this.accountId,
  });

  factory AccountDeleted.fromJson(Map<String, dynamic> json) =>
      _$AccountDeletedFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AccountDeletedToJson(this);
}
