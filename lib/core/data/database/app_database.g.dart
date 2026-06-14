// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LedgerEventsTable extends LedgerEvents
    with TableInfo<$LedgerEventsTable, LedgerEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LedgerEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _eventIdMeta =
      const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
      'event_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _streamIdMeta =
      const VerificationMeta('streamId');
  @override
  late final GeneratedColumn<String> streamId = GeneratedColumn<String>(
      'stream_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<AggregateType, int>
      aggregateType = GeneratedColumn<int>('aggregate_type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<AggregateType>(
              $LedgerEventsTable.$converteraggregateType);
  static const VerificationMeta _eventTypeMeta =
      const VerificationMeta('eventType');
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
      'event_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _streamVersionMeta =
      const VerificationMeta('streamVersion');
  @override
  late final GeneratedColumn<int> streamVersion = GeneratedColumn<int>(
      'stream_version', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _occurredAtMeta =
      const VerificationMeta('occurredAt');
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
      'occurred_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _recordedAtMeta =
      const VerificationMeta('recordedAt');
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
      'recorded_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _commandIdMeta =
      const VerificationMeta('commandId');
  @override
  late final GeneratedColumn<String> commandId = GeneratedColumn<String>(
      'command_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        eventId,
        streamId,
        aggregateType,
        eventType,
        streamVersion,
        occurredAt,
        recordedAt,
        commandId,
        payload
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_events';
  @override
  VerificationContext validateIntegrity(Insertable<LedgerEventRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('stream_id')) {
      context.handle(_streamIdMeta,
          streamId.isAcceptableOrUnknown(data['stream_id']!, _streamIdMeta));
    } else if (isInserting) {
      context.missing(_streamIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(_eventTypeMeta,
          eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta));
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('stream_version')) {
      context.handle(
          _streamVersionMeta,
          streamVersion.isAcceptableOrUnknown(
              data['stream_version']!, _streamVersionMeta));
    } else if (isInserting) {
      context.missing(_streamVersionMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
          _occurredAtMeta,
          occurredAt.isAcceptableOrUnknown(
              data['occurred_at']!, _occurredAtMeta));
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
          _recordedAtMeta,
          recordedAt.isAcceptableOrUnknown(
              data['recorded_at']!, _recordedAtMeta));
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('command_id')) {
      context.handle(_commandIdMeta,
          commandId.isAcceptableOrUnknown(data['command_id']!, _commandIdMeta));
    } else if (isInserting) {
      context.missing(_commandIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {streamId, streamVersion},
      ];
  @override
  LedgerEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerEventRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_id'])!,
      streamId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stream_id'])!,
      aggregateType: $LedgerEventsTable.$converteraggregateType.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.int, data['${effectivePrefix}aggregate_type'])!),
      eventType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_type'])!,
      streamVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stream_version'])!,
      occurredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}occurred_at'])!,
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
      commandId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}command_id'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
    );
  }

  @override
  $LedgerEventsTable createAlias(String alias) {
    return $LedgerEventsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AggregateType, int, int> $converteraggregateType =
      const EnumIndexConverter<AggregateType>(AggregateType.values);
}

class LedgerEventRow extends DataClass implements Insertable<LedgerEventRow> {
  final int id;
  final String eventId;
  final String streamId;
  final AggregateType aggregateType;
  final String eventType;
  final int streamVersion;
  final DateTime occurredAt;
  final DateTime recordedAt;
  final String commandId;
  final String payload;
  const LedgerEventRow(
      {required this.id,
      required this.eventId,
      required this.streamId,
      required this.aggregateType,
      required this.eventType,
      required this.streamVersion,
      required this.occurredAt,
      required this.recordedAt,
      required this.commandId,
      required this.payload});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['event_id'] = Variable<String>(eventId);
    map['stream_id'] = Variable<String>(streamId);
    {
      map['aggregate_type'] = Variable<int>(
          $LedgerEventsTable.$converteraggregateType.toSql(aggregateType));
    }
    map['event_type'] = Variable<String>(eventType);
    map['stream_version'] = Variable<int>(streamVersion);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['command_id'] = Variable<String>(commandId);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  LedgerEventsCompanion toCompanion(bool nullToAbsent) {
    return LedgerEventsCompanion(
      id: Value(id),
      eventId: Value(eventId),
      streamId: Value(streamId),
      aggregateType: Value(aggregateType),
      eventType: Value(eventType),
      streamVersion: Value(streamVersion),
      occurredAt: Value(occurredAt),
      recordedAt: Value(recordedAt),
      commandId: Value(commandId),
      payload: Value(payload),
    );
  }

  factory LedgerEventRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerEventRow(
      id: serializer.fromJson<int>(json['id']),
      eventId: serializer.fromJson<String>(json['eventId']),
      streamId: serializer.fromJson<String>(json['streamId']),
      aggregateType: $LedgerEventsTable.$converteraggregateType
          .fromJson(serializer.fromJson<int>(json['aggregateType'])),
      eventType: serializer.fromJson<String>(json['eventType']),
      streamVersion: serializer.fromJson<int>(json['streamVersion']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      commandId: serializer.fromJson<String>(json['commandId']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'eventId': serializer.toJson<String>(eventId),
      'streamId': serializer.toJson<String>(streamId),
      'aggregateType': serializer.toJson<int>(
          $LedgerEventsTable.$converteraggregateType.toJson(aggregateType)),
      'eventType': serializer.toJson<String>(eventType),
      'streamVersion': serializer.toJson<int>(streamVersion),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'commandId': serializer.toJson<String>(commandId),
      'payload': serializer.toJson<String>(payload),
    };
  }

  LedgerEventRow copyWith(
          {int? id,
          String? eventId,
          String? streamId,
          AggregateType? aggregateType,
          String? eventType,
          int? streamVersion,
          DateTime? occurredAt,
          DateTime? recordedAt,
          String? commandId,
          String? payload}) =>
      LedgerEventRow(
        id: id ?? this.id,
        eventId: eventId ?? this.eventId,
        streamId: streamId ?? this.streamId,
        aggregateType: aggregateType ?? this.aggregateType,
        eventType: eventType ?? this.eventType,
        streamVersion: streamVersion ?? this.streamVersion,
        occurredAt: occurredAt ?? this.occurredAt,
        recordedAt: recordedAt ?? this.recordedAt,
        commandId: commandId ?? this.commandId,
        payload: payload ?? this.payload,
      );
  LedgerEventRow copyWithCompanion(LedgerEventsCompanion data) {
    return LedgerEventRow(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      streamId: data.streamId.present ? data.streamId.value : this.streamId,
      aggregateType: data.aggregateType.present
          ? data.aggregateType.value
          : this.aggregateType,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      streamVersion: data.streamVersion.present
          ? data.streamVersion.value
          : this.streamVersion,
      occurredAt:
          data.occurredAt.present ? data.occurredAt.value : this.occurredAt,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
      commandId: data.commandId.present ? data.commandId.value : this.commandId,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEventRow(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('streamId: $streamId, ')
          ..write('aggregateType: $aggregateType, ')
          ..write('eventType: $eventType, ')
          ..write('streamVersion: $streamVersion, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('commandId: $commandId, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, eventId, streamId, aggregateType,
      eventType, streamVersion, occurredAt, recordedAt, commandId, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerEventRow &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.streamId == this.streamId &&
          other.aggregateType == this.aggregateType &&
          other.eventType == this.eventType &&
          other.streamVersion == this.streamVersion &&
          other.occurredAt == this.occurredAt &&
          other.recordedAt == this.recordedAt &&
          other.commandId == this.commandId &&
          other.payload == this.payload);
}

class LedgerEventsCompanion extends UpdateCompanion<LedgerEventRow> {
  final Value<int> id;
  final Value<String> eventId;
  final Value<String> streamId;
  final Value<AggregateType> aggregateType;
  final Value<String> eventType;
  final Value<int> streamVersion;
  final Value<DateTime> occurredAt;
  final Value<DateTime> recordedAt;
  final Value<String> commandId;
  final Value<String> payload;
  const LedgerEventsCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.streamId = const Value.absent(),
    this.aggregateType = const Value.absent(),
    this.eventType = const Value.absent(),
    this.streamVersion = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.commandId = const Value.absent(),
    this.payload = const Value.absent(),
  });
  LedgerEventsCompanion.insert({
    this.id = const Value.absent(),
    required String eventId,
    required String streamId,
    required AggregateType aggregateType,
    required String eventType,
    required int streamVersion,
    required DateTime occurredAt,
    required DateTime recordedAt,
    required String commandId,
    required String payload,
  })  : eventId = Value(eventId),
        streamId = Value(streamId),
        aggregateType = Value(aggregateType),
        eventType = Value(eventType),
        streamVersion = Value(streamVersion),
        occurredAt = Value(occurredAt),
        recordedAt = Value(recordedAt),
        commandId = Value(commandId),
        payload = Value(payload);
  static Insertable<LedgerEventRow> custom({
    Expression<int>? id,
    Expression<String>? eventId,
    Expression<String>? streamId,
    Expression<int>? aggregateType,
    Expression<String>? eventType,
    Expression<int>? streamVersion,
    Expression<DateTime>? occurredAt,
    Expression<DateTime>? recordedAt,
    Expression<String>? commandId,
    Expression<String>? payload,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (streamId != null) 'stream_id': streamId,
      if (aggregateType != null) 'aggregate_type': aggregateType,
      if (eventType != null) 'event_type': eventType,
      if (streamVersion != null) 'stream_version': streamVersion,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (commandId != null) 'command_id': commandId,
      if (payload != null) 'payload': payload,
    });
  }

  LedgerEventsCompanion copyWith(
      {Value<int>? id,
      Value<String>? eventId,
      Value<String>? streamId,
      Value<AggregateType>? aggregateType,
      Value<String>? eventType,
      Value<int>? streamVersion,
      Value<DateTime>? occurredAt,
      Value<DateTime>? recordedAt,
      Value<String>? commandId,
      Value<String>? payload}) {
    return LedgerEventsCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      streamId: streamId ?? this.streamId,
      aggregateType: aggregateType ?? this.aggregateType,
      eventType: eventType ?? this.eventType,
      streamVersion: streamVersion ?? this.streamVersion,
      occurredAt: occurredAt ?? this.occurredAt,
      recordedAt: recordedAt ?? this.recordedAt,
      commandId: commandId ?? this.commandId,
      payload: payload ?? this.payload,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (streamId.present) {
      map['stream_id'] = Variable<String>(streamId.value);
    }
    if (aggregateType.present) {
      map['aggregate_type'] = Variable<int>($LedgerEventsTable
          .$converteraggregateType
          .toSql(aggregateType.value));
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (streamVersion.present) {
      map['stream_version'] = Variable<int>(streamVersion.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (commandId.present) {
      map['command_id'] = Variable<String>(commandId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEventsCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('streamId: $streamId, ')
          ..write('aggregateType: $aggregateType, ')
          ..write('eventType: $eventType, ')
          ..write('streamVersion: $streamVersion, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('commandId: $commandId, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }
}

class $AccountsViewTable extends AccountsView
    with TableInfo<$AccountsViewTable, AccountViewRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsViewTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<AccountType, int> type =
      GeneratedColumn<int>('type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<AccountType>($AccountsViewTable.$convertertype);
  static const VerificationMeta _currencyCodeMeta =
      const VerificationMeta('currencyCode');
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
      'currency_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _balanceMinorMeta =
      const VerificationMeta('balanceMinor');
  @override
  late final GeneratedColumn<int> balanceMinor = GeneratedColumn<int>(
      'balance_minor', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _archivedMeta =
      const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
      'archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastUpdatedEventIdMeta =
      const VerificationMeta('lastUpdatedEventId');
  @override
  late final GeneratedColumn<int> lastUpdatedEventId = GeneratedColumn<int>(
      'last_updated_event_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _projectionVersionMeta =
      const VerificationMeta('projectionVersion');
  @override
  late final GeneratedColumn<int> projectionVersion = GeneratedColumn<int>(
      'projection_version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        type,
        currencyCode,
        balanceMinor,
        archived,
        lastUpdatedEventId,
        projectionVersion
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts_view';
  @override
  VerificationContext validateIntegrity(Insertable<AccountViewRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
          _currencyCodeMeta,
          currencyCode.isAcceptableOrUnknown(
              data['currency_code']!, _currencyCodeMeta));
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('balance_minor')) {
      context.handle(
          _balanceMinorMeta,
          balanceMinor.isAcceptableOrUnknown(
              data['balance_minor']!, _balanceMinorMeta));
    } else if (isInserting) {
      context.missing(_balanceMinorMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta,
          archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    if (data.containsKey('last_updated_event_id')) {
      context.handle(
          _lastUpdatedEventIdMeta,
          lastUpdatedEventId.isAcceptableOrUnknown(
              data['last_updated_event_id']!, _lastUpdatedEventIdMeta));
    } else if (isInserting) {
      context.missing(_lastUpdatedEventIdMeta);
    }
    if (data.containsKey('projection_version')) {
      context.handle(
          _projectionVersionMeta,
          projectionVersion.isAcceptableOrUnknown(
              data['projection_version']!, _projectionVersionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountViewRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountViewRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: $AccountsViewTable.$convertertype.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!),
      currencyCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency_code'])!,
      balanceMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}balance_minor'])!,
      archived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
      lastUpdatedEventId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}last_updated_event_id'])!,
      projectionVersion: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}projection_version'])!,
    );
  }

  @override
  $AccountsViewTable createAlias(String alias) {
    return $AccountsViewTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AccountType, int, int> $convertertype =
      const EnumIndexConverter<AccountType>(AccountType.values);
}

class AccountViewRow extends DataClass implements Insertable<AccountViewRow> {
  final String id;
  final String name;
  final AccountType type;
  final String currencyCode;
  final int balanceMinor;
  final bool archived;
  final int lastUpdatedEventId;
  final int projectionVersion;
  const AccountViewRow(
      {required this.id,
      required this.name,
      required this.type,
      required this.currencyCode,
      required this.balanceMinor,
      required this.archived,
      required this.lastUpdatedEventId,
      required this.projectionVersion});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['type'] =
          Variable<int>($AccountsViewTable.$convertertype.toSql(type));
    }
    map['currency_code'] = Variable<String>(currencyCode);
    map['balance_minor'] = Variable<int>(balanceMinor);
    map['archived'] = Variable<bool>(archived);
    map['last_updated_event_id'] = Variable<int>(lastUpdatedEventId);
    map['projection_version'] = Variable<int>(projectionVersion);
    return map;
  }

  AccountsViewCompanion toCompanion(bool nullToAbsent) {
    return AccountsViewCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      currencyCode: Value(currencyCode),
      balanceMinor: Value(balanceMinor),
      archived: Value(archived),
      lastUpdatedEventId: Value(lastUpdatedEventId),
      projectionVersion: Value(projectionVersion),
    );
  }

  factory AccountViewRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountViewRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: $AccountsViewTable.$convertertype
          .fromJson(serializer.fromJson<int>(json['type'])),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      balanceMinor: serializer.fromJson<int>(json['balanceMinor']),
      archived: serializer.fromJson<bool>(json['archived']),
      lastUpdatedEventId: serializer.fromJson<int>(json['lastUpdatedEventId']),
      projectionVersion: serializer.fromJson<int>(json['projectionVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer
          .toJson<int>($AccountsViewTable.$convertertype.toJson(type)),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'balanceMinor': serializer.toJson<int>(balanceMinor),
      'archived': serializer.toJson<bool>(archived),
      'lastUpdatedEventId': serializer.toJson<int>(lastUpdatedEventId),
      'projectionVersion': serializer.toJson<int>(projectionVersion),
    };
  }

  AccountViewRow copyWith(
          {String? id,
          String? name,
          AccountType? type,
          String? currencyCode,
          int? balanceMinor,
          bool? archived,
          int? lastUpdatedEventId,
          int? projectionVersion}) =>
      AccountViewRow(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        currencyCode: currencyCode ?? this.currencyCode,
        balanceMinor: balanceMinor ?? this.balanceMinor,
        archived: archived ?? this.archived,
        lastUpdatedEventId: lastUpdatedEventId ?? this.lastUpdatedEventId,
        projectionVersion: projectionVersion ?? this.projectionVersion,
      );
  AccountViewRow copyWithCompanion(AccountsViewCompanion data) {
    return AccountViewRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      balanceMinor: data.balanceMinor.present
          ? data.balanceMinor.value
          : this.balanceMinor,
      archived: data.archived.present ? data.archived.value : this.archived,
      lastUpdatedEventId: data.lastUpdatedEventId.present
          ? data.lastUpdatedEventId.value
          : this.lastUpdatedEventId,
      projectionVersion: data.projectionVersion.present
          ? data.projectionVersion.value
          : this.projectionVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountViewRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('balanceMinor: $balanceMinor, ')
          ..write('archived: $archived, ')
          ..write('lastUpdatedEventId: $lastUpdatedEventId, ')
          ..write('projectionVersion: $projectionVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, type, currencyCode, balanceMinor,
      archived, lastUpdatedEventId, projectionVersion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountViewRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.currencyCode == this.currencyCode &&
          other.balanceMinor == this.balanceMinor &&
          other.archived == this.archived &&
          other.lastUpdatedEventId == this.lastUpdatedEventId &&
          other.projectionVersion == this.projectionVersion);
}

class AccountsViewCompanion extends UpdateCompanion<AccountViewRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<AccountType> type;
  final Value<String> currencyCode;
  final Value<int> balanceMinor;
  final Value<bool> archived;
  final Value<int> lastUpdatedEventId;
  final Value<int> projectionVersion;
  final Value<int> rowid;
  const AccountsViewCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.balanceMinor = const Value.absent(),
    this.archived = const Value.absent(),
    this.lastUpdatedEventId = const Value.absent(),
    this.projectionVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsViewCompanion.insert({
    required String id,
    required String name,
    required AccountType type,
    required String currencyCode,
    required int balanceMinor,
    this.archived = const Value.absent(),
    required int lastUpdatedEventId,
    this.projectionVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        type = Value(type),
        currencyCode = Value(currencyCode),
        balanceMinor = Value(balanceMinor),
        lastUpdatedEventId = Value(lastUpdatedEventId);
  static Insertable<AccountViewRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? type,
    Expression<String>? currencyCode,
    Expression<int>? balanceMinor,
    Expression<bool>? archived,
    Expression<int>? lastUpdatedEventId,
    Expression<int>? projectionVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (balanceMinor != null) 'balance_minor': balanceMinor,
      if (archived != null) 'archived': archived,
      if (lastUpdatedEventId != null)
        'last_updated_event_id': lastUpdatedEventId,
      if (projectionVersion != null) 'projection_version': projectionVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsViewCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<AccountType>? type,
      Value<String>? currencyCode,
      Value<int>? balanceMinor,
      Value<bool>? archived,
      Value<int>? lastUpdatedEventId,
      Value<int>? projectionVersion,
      Value<int>? rowid}) {
    return AccountsViewCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      currencyCode: currencyCode ?? this.currencyCode,
      balanceMinor: balanceMinor ?? this.balanceMinor,
      archived: archived ?? this.archived,
      lastUpdatedEventId: lastUpdatedEventId ?? this.lastUpdatedEventId,
      projectionVersion: projectionVersion ?? this.projectionVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] =
          Variable<int>($AccountsViewTable.$convertertype.toSql(type.value));
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (balanceMinor.present) {
      map['balance_minor'] = Variable<int>(balanceMinor.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (lastUpdatedEventId.present) {
      map['last_updated_event_id'] = Variable<int>(lastUpdatedEventId.value);
    }
    if (projectionVersion.present) {
      map['projection_version'] = Variable<int>(projectionVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsViewCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('balanceMinor: $balanceMinor, ')
          ..write('archived: $archived, ')
          ..write('lastUpdatedEventId: $lastUpdatedEventId, ')
          ..write('projectionVersion: $projectionVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsViewTable extends TransactionsView
    with TableInfo<$TransactionsViewTable, TransactionViewRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsViewTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _transactionIdMeta =
      const VerificationMeta('transactionId');
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
      'transaction_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _occurredAtMeta =
      const VerificationMeta('occurredAt');
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
      'occurred_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<TransactionKind, int> kind =
      GeneratedColumn<int>('kind', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<TransactionKind>(
              $TransactionsViewTable.$converterkind);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isReversedMeta =
      const VerificationMeta('isReversed');
  @override
  late final GeneratedColumn<bool> isReversed = GeneratedColumn<bool>(
      'is_reversed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_reversed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _categoryNameMeta =
      const VerificationMeta('categoryName');
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
      'category_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryIconMeta =
      const VerificationMeta('categoryIcon');
  @override
  late final GeneratedColumn<String> categoryIcon = GeneratedColumn<String>(
      'category_icon', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryColorIntMeta =
      const VerificationMeta('categoryColorInt');
  @override
  late final GeneratedColumn<String> categoryColorInt = GeneratedColumn<String>(
      'category_color_int', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _originalEventIdMeta =
      const VerificationMeta('originalEventId');
  @override
  late final GeneratedColumn<int> originalEventId = GeneratedColumn<int>(
      'original_event_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _projectionVersionMeta =
      const VerificationMeta('projectionVersion');
  @override
  late final GeneratedColumn<int> projectionVersion = GeneratedColumn<int>(
      'projection_version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns => [
        transactionId,
        occurredAt,
        kind,
        description,
        isReversed,
        categoryName,
        categoryIcon,
        categoryColorInt,
        originalEventId,
        projectionVersion
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions_view';
  @override
  VerificationContext validateIntegrity(Insertable<TransactionViewRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('transaction_id')) {
      context.handle(
          _transactionIdMeta,
          transactionId.isAcceptableOrUnknown(
              data['transaction_id']!, _transactionIdMeta));
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
          _occurredAtMeta,
          occurredAt.isAcceptableOrUnknown(
              data['occurred_at']!, _occurredAtMeta));
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('is_reversed')) {
      context.handle(
          _isReversedMeta,
          isReversed.isAcceptableOrUnknown(
              data['is_reversed']!, _isReversedMeta));
    }
    if (data.containsKey('category_name')) {
      context.handle(
          _categoryNameMeta,
          categoryName.isAcceptableOrUnknown(
              data['category_name']!, _categoryNameMeta));
    }
    if (data.containsKey('category_icon')) {
      context.handle(
          _categoryIconMeta,
          categoryIcon.isAcceptableOrUnknown(
              data['category_icon']!, _categoryIconMeta));
    }
    if (data.containsKey('category_color_int')) {
      context.handle(
          _categoryColorIntMeta,
          categoryColorInt.isAcceptableOrUnknown(
              data['category_color_int']!, _categoryColorIntMeta));
    }
    if (data.containsKey('original_event_id')) {
      context.handle(
          _originalEventIdMeta,
          originalEventId.isAcceptableOrUnknown(
              data['original_event_id']!, _originalEventIdMeta));
    } else if (isInserting) {
      context.missing(_originalEventIdMeta);
    }
    if (data.containsKey('projection_version')) {
      context.handle(
          _projectionVersionMeta,
          projectionVersion.isAcceptableOrUnknown(
              data['projection_version']!, _projectionVersionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {transactionId};
  @override
  TransactionViewRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionViewRow(
      transactionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transaction_id'])!,
      occurredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}occurred_at'])!,
      kind: $TransactionsViewTable.$converterkind.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kind'])!),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      isReversed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_reversed'])!,
      categoryName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_name']),
      categoryIcon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_icon']),
      categoryColorInt: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}category_color_int']),
      originalEventId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}original_event_id'])!,
      projectionVersion: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}projection_version'])!,
    );
  }

  @override
  $TransactionsViewTable createAlias(String alias) {
    return $TransactionsViewTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TransactionKind, int, int> $converterkind =
      const EnumIndexConverter<TransactionKind>(TransactionKind.values);
}

class TransactionViewRow extends DataClass
    implements Insertable<TransactionViewRow> {
  final String transactionId;
  final DateTime occurredAt;
  final TransactionKind kind;
  final String description;
  final bool isReversed;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColorInt;
  final int originalEventId;
  final int projectionVersion;
  const TransactionViewRow(
      {required this.transactionId,
      required this.occurredAt,
      required this.kind,
      required this.description,
      required this.isReversed,
      this.categoryName,
      this.categoryIcon,
      this.categoryColorInt,
      required this.originalEventId,
      required this.projectionVersion});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['transaction_id'] = Variable<String>(transactionId);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    {
      map['kind'] =
          Variable<int>($TransactionsViewTable.$converterkind.toSql(kind));
    }
    map['description'] = Variable<String>(description);
    map['is_reversed'] = Variable<bool>(isReversed);
    if (!nullToAbsent || categoryName != null) {
      map['category_name'] = Variable<String>(categoryName);
    }
    if (!nullToAbsent || categoryIcon != null) {
      map['category_icon'] = Variable<String>(categoryIcon);
    }
    if (!nullToAbsent || categoryColorInt != null) {
      map['category_color_int'] = Variable<String>(categoryColorInt);
    }
    map['original_event_id'] = Variable<int>(originalEventId);
    map['projection_version'] = Variable<int>(projectionVersion);
    return map;
  }

  TransactionsViewCompanion toCompanion(bool nullToAbsent) {
    return TransactionsViewCompanion(
      transactionId: Value(transactionId),
      occurredAt: Value(occurredAt),
      kind: Value(kind),
      description: Value(description),
      isReversed: Value(isReversed),
      categoryName: categoryName == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryName),
      categoryIcon: categoryIcon == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryIcon),
      categoryColorInt: categoryColorInt == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryColorInt),
      originalEventId: Value(originalEventId),
      projectionVersion: Value(projectionVersion),
    );
  }

  factory TransactionViewRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionViewRow(
      transactionId: serializer.fromJson<String>(json['transactionId']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      kind: $TransactionsViewTable.$converterkind
          .fromJson(serializer.fromJson<int>(json['kind'])),
      description: serializer.fromJson<String>(json['description']),
      isReversed: serializer.fromJson<bool>(json['isReversed']),
      categoryName: serializer.fromJson<String?>(json['categoryName']),
      categoryIcon: serializer.fromJson<String?>(json['categoryIcon']),
      categoryColorInt: serializer.fromJson<String?>(json['categoryColorInt']),
      originalEventId: serializer.fromJson<int>(json['originalEventId']),
      projectionVersion: serializer.fromJson<int>(json['projectionVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'transactionId': serializer.toJson<String>(transactionId),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'kind': serializer
          .toJson<int>($TransactionsViewTable.$converterkind.toJson(kind)),
      'description': serializer.toJson<String>(description),
      'isReversed': serializer.toJson<bool>(isReversed),
      'categoryName': serializer.toJson<String?>(categoryName),
      'categoryIcon': serializer.toJson<String?>(categoryIcon),
      'categoryColorInt': serializer.toJson<String?>(categoryColorInt),
      'originalEventId': serializer.toJson<int>(originalEventId),
      'projectionVersion': serializer.toJson<int>(projectionVersion),
    };
  }

  TransactionViewRow copyWith(
          {String? transactionId,
          DateTime? occurredAt,
          TransactionKind? kind,
          String? description,
          bool? isReversed,
          Value<String?> categoryName = const Value.absent(),
          Value<String?> categoryIcon = const Value.absent(),
          Value<String?> categoryColorInt = const Value.absent(),
          int? originalEventId,
          int? projectionVersion}) =>
      TransactionViewRow(
        transactionId: transactionId ?? this.transactionId,
        occurredAt: occurredAt ?? this.occurredAt,
        kind: kind ?? this.kind,
        description: description ?? this.description,
        isReversed: isReversed ?? this.isReversed,
        categoryName:
            categoryName.present ? categoryName.value : this.categoryName,
        categoryIcon:
            categoryIcon.present ? categoryIcon.value : this.categoryIcon,
        categoryColorInt: categoryColorInt.present
            ? categoryColorInt.value
            : this.categoryColorInt,
        originalEventId: originalEventId ?? this.originalEventId,
        projectionVersion: projectionVersion ?? this.projectionVersion,
      );
  TransactionViewRow copyWithCompanion(TransactionsViewCompanion data) {
    return TransactionViewRow(
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      occurredAt:
          data.occurredAt.present ? data.occurredAt.value : this.occurredAt,
      kind: data.kind.present ? data.kind.value : this.kind,
      description:
          data.description.present ? data.description.value : this.description,
      isReversed:
          data.isReversed.present ? data.isReversed.value : this.isReversed,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      categoryIcon: data.categoryIcon.present
          ? data.categoryIcon.value
          : this.categoryIcon,
      categoryColorInt: data.categoryColorInt.present
          ? data.categoryColorInt.value
          : this.categoryColorInt,
      originalEventId: data.originalEventId.present
          ? data.originalEventId.value
          : this.originalEventId,
      projectionVersion: data.projectionVersion.present
          ? data.projectionVersion.value
          : this.projectionVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionViewRow(')
          ..write('transactionId: $transactionId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('kind: $kind, ')
          ..write('description: $description, ')
          ..write('isReversed: $isReversed, ')
          ..write('categoryName: $categoryName, ')
          ..write('categoryIcon: $categoryIcon, ')
          ..write('categoryColorInt: $categoryColorInt, ')
          ..write('originalEventId: $originalEventId, ')
          ..write('projectionVersion: $projectionVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      transactionId,
      occurredAt,
      kind,
      description,
      isReversed,
      categoryName,
      categoryIcon,
      categoryColorInt,
      originalEventId,
      projectionVersion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionViewRow &&
          other.transactionId == this.transactionId &&
          other.occurredAt == this.occurredAt &&
          other.kind == this.kind &&
          other.description == this.description &&
          other.isReversed == this.isReversed &&
          other.categoryName == this.categoryName &&
          other.categoryIcon == this.categoryIcon &&
          other.categoryColorInt == this.categoryColorInt &&
          other.originalEventId == this.originalEventId &&
          other.projectionVersion == this.projectionVersion);
}

class TransactionsViewCompanion extends UpdateCompanion<TransactionViewRow> {
  final Value<String> transactionId;
  final Value<DateTime> occurredAt;
  final Value<TransactionKind> kind;
  final Value<String> description;
  final Value<bool> isReversed;
  final Value<String?> categoryName;
  final Value<String?> categoryIcon;
  final Value<String?> categoryColorInt;
  final Value<int> originalEventId;
  final Value<int> projectionVersion;
  final Value<int> rowid;
  const TransactionsViewCompanion({
    this.transactionId = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.kind = const Value.absent(),
    this.description = const Value.absent(),
    this.isReversed = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.categoryIcon = const Value.absent(),
    this.categoryColorInt = const Value.absent(),
    this.originalEventId = const Value.absent(),
    this.projectionVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsViewCompanion.insert({
    required String transactionId,
    required DateTime occurredAt,
    required TransactionKind kind,
    required String description,
    this.isReversed = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.categoryIcon = const Value.absent(),
    this.categoryColorInt = const Value.absent(),
    required int originalEventId,
    this.projectionVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : transactionId = Value(transactionId),
        occurredAt = Value(occurredAt),
        kind = Value(kind),
        description = Value(description),
        originalEventId = Value(originalEventId);
  static Insertable<TransactionViewRow> custom({
    Expression<String>? transactionId,
    Expression<DateTime>? occurredAt,
    Expression<int>? kind,
    Expression<String>? description,
    Expression<bool>? isReversed,
    Expression<String>? categoryName,
    Expression<String>? categoryIcon,
    Expression<String>? categoryColorInt,
    Expression<int>? originalEventId,
    Expression<int>? projectionVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (transactionId != null) 'transaction_id': transactionId,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (kind != null) 'kind': kind,
      if (description != null) 'description': description,
      if (isReversed != null) 'is_reversed': isReversed,
      if (categoryName != null) 'category_name': categoryName,
      if (categoryIcon != null) 'category_icon': categoryIcon,
      if (categoryColorInt != null) 'category_color_int': categoryColorInt,
      if (originalEventId != null) 'original_event_id': originalEventId,
      if (projectionVersion != null) 'projection_version': projectionVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsViewCompanion copyWith(
      {Value<String>? transactionId,
      Value<DateTime>? occurredAt,
      Value<TransactionKind>? kind,
      Value<String>? description,
      Value<bool>? isReversed,
      Value<String?>? categoryName,
      Value<String?>? categoryIcon,
      Value<String?>? categoryColorInt,
      Value<int>? originalEventId,
      Value<int>? projectionVersion,
      Value<int>? rowid}) {
    return TransactionsViewCompanion(
      transactionId: transactionId ?? this.transactionId,
      occurredAt: occurredAt ?? this.occurredAt,
      kind: kind ?? this.kind,
      description: description ?? this.description,
      isReversed: isReversed ?? this.isReversed,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColorInt: categoryColorInt ?? this.categoryColorInt,
      originalEventId: originalEventId ?? this.originalEventId,
      projectionVersion: projectionVersion ?? this.projectionVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(
          $TransactionsViewTable.$converterkind.toSql(kind.value));
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isReversed.present) {
      map['is_reversed'] = Variable<bool>(isReversed.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (categoryIcon.present) {
      map['category_icon'] = Variable<String>(categoryIcon.value);
    }
    if (categoryColorInt.present) {
      map['category_color_int'] = Variable<String>(categoryColorInt.value);
    }
    if (originalEventId.present) {
      map['original_event_id'] = Variable<int>(originalEventId.value);
    }
    if (projectionVersion.present) {
      map['projection_version'] = Variable<int>(projectionVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsViewCompanion(')
          ..write('transactionId: $transactionId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('kind: $kind, ')
          ..write('description: $description, ')
          ..write('isReversed: $isReversed, ')
          ..write('categoryName: $categoryName, ')
          ..write('categoryIcon: $categoryIcon, ')
          ..write('categoryColorInt: $categoryColorInt, ')
          ..write('originalEventId: $originalEventId, ')
          ..write('projectionVersion: $projectionVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionPostingsViewTable extends TransactionPostingsView
    with TableInfo<$TransactionPostingsViewTable, TransactionPostingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionPostingsViewTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _transactionIdMeta =
      const VerificationMeta('transactionId');
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
      'transaction_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<PostingDirection, int> direction =
      GeneratedColumn<int>('direction', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<PostingDirection>(
              $TransactionPostingsViewTable.$converterdirection);
  static const VerificationMeta _amountMinorMeta =
      const VerificationMeta('amountMinor');
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
      'amount_minor', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _currencyCodeMeta =
      const VerificationMeta('currencyCode');
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
      'currency_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
      'memo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        transactionId,
        accountId,
        direction,
        amountMinor,
        currencyCode,
        categoryId,
        memo
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_postings_view';
  @override
  VerificationContext validateIntegrity(
      Insertable<TransactionPostingRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
          _transactionIdMeta,
          transactionId.isAcceptableOrUnknown(
              data['transaction_id']!, _transactionIdMeta));
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
          _amountMinorMeta,
          amountMinor.isAcceptableOrUnknown(
              data['amount_minor']!, _amountMinorMeta));
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
          _currencyCodeMeta,
          currencyCode.isAcceptableOrUnknown(
              data['currency_code']!, _currencyCodeMeta));
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('memo')) {
      context.handle(
          _memoMeta, memo.isAcceptableOrUnknown(data['memo']!, _memoMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionPostingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionPostingRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      transactionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transaction_id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      direction: $TransactionPostingsViewTable.$converterdirection.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}direction'])!),
      amountMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_minor'])!,
      currencyCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency_code'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      memo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}memo']),
    );
  }

  @override
  $TransactionPostingsViewTable createAlias(String alias) {
    return $TransactionPostingsViewTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PostingDirection, int, int> $converterdirection =
      const EnumIndexConverter<PostingDirection>(PostingDirection.values);
}

class TransactionPostingRow extends DataClass
    implements Insertable<TransactionPostingRow> {
  final String id;
  final String transactionId;
  final String accountId;
  final PostingDirection direction;
  final int amountMinor;
  final String currencyCode;
  final String? categoryId;
  final String? memo;
  const TransactionPostingRow(
      {required this.id,
      required this.transactionId,
      required this.accountId,
      required this.direction,
      required this.amountMinor,
      required this.currencyCode,
      this.categoryId,
      this.memo});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['transaction_id'] = Variable<String>(transactionId);
    map['account_id'] = Variable<String>(accountId);
    {
      map['direction'] = Variable<int>(
          $TransactionPostingsViewTable.$converterdirection.toSql(direction));
    }
    map['amount_minor'] = Variable<int>(amountMinor);
    map['currency_code'] = Variable<String>(currencyCode);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    return map;
  }

  TransactionPostingsViewCompanion toCompanion(bool nullToAbsent) {
    return TransactionPostingsViewCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      accountId: Value(accountId),
      direction: Value(direction),
      amountMinor: Value(amountMinor),
      currencyCode: Value(currencyCode),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
    );
  }

  factory TransactionPostingRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionPostingRow(
      id: serializer.fromJson<String>(json['id']),
      transactionId: serializer.fromJson<String>(json['transactionId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      direction: $TransactionPostingsViewTable.$converterdirection
          .fromJson(serializer.fromJson<int>(json['direction'])),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      memo: serializer.fromJson<String?>(json['memo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transactionId': serializer.toJson<String>(transactionId),
      'accountId': serializer.toJson<String>(accountId),
      'direction': serializer.toJson<int>(
          $TransactionPostingsViewTable.$converterdirection.toJson(direction)),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'categoryId': serializer.toJson<String?>(categoryId),
      'memo': serializer.toJson<String?>(memo),
    };
  }

  TransactionPostingRow copyWith(
          {String? id,
          String? transactionId,
          String? accountId,
          PostingDirection? direction,
          int? amountMinor,
          String? currencyCode,
          Value<String?> categoryId = const Value.absent(),
          Value<String?> memo = const Value.absent()}) =>
      TransactionPostingRow(
        id: id ?? this.id,
        transactionId: transactionId ?? this.transactionId,
        accountId: accountId ?? this.accountId,
        direction: direction ?? this.direction,
        amountMinor: amountMinor ?? this.amountMinor,
        currencyCode: currencyCode ?? this.currencyCode,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        memo: memo.present ? memo.value : this.memo,
      );
  TransactionPostingRow copyWithCompanion(
      TransactionPostingsViewCompanion data) {
    return TransactionPostingRow(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      direction: data.direction.present ? data.direction.value : this.direction,
      amountMinor:
          data.amountMinor.present ? data.amountMinor.value : this.amountMinor,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      memo: data.memo.present ? data.memo.value : this.memo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionPostingRow(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('accountId: $accountId, ')
          ..write('direction: $direction, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('categoryId: $categoryId, ')
          ..write('memo: $memo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, transactionId, accountId, direction,
      amountMinor, currencyCode, categoryId, memo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionPostingRow &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.accountId == this.accountId &&
          other.direction == this.direction &&
          other.amountMinor == this.amountMinor &&
          other.currencyCode == this.currencyCode &&
          other.categoryId == this.categoryId &&
          other.memo == this.memo);
}

class TransactionPostingsViewCompanion
    extends UpdateCompanion<TransactionPostingRow> {
  final Value<String> id;
  final Value<String> transactionId;
  final Value<String> accountId;
  final Value<PostingDirection> direction;
  final Value<int> amountMinor;
  final Value<String> currencyCode;
  final Value<String?> categoryId;
  final Value<String?> memo;
  final Value<int> rowid;
  const TransactionPostingsViewCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.direction = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.memo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionPostingsViewCompanion.insert({
    required String id,
    required String transactionId,
    required String accountId,
    required PostingDirection direction,
    required int amountMinor,
    required String currencyCode,
    this.categoryId = const Value.absent(),
    this.memo = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        transactionId = Value(transactionId),
        accountId = Value(accountId),
        direction = Value(direction),
        amountMinor = Value(amountMinor),
        currencyCode = Value(currencyCode);
  static Insertable<TransactionPostingRow> custom({
    Expression<String>? id,
    Expression<String>? transactionId,
    Expression<String>? accountId,
    Expression<int>? direction,
    Expression<int>? amountMinor,
    Expression<String>? currencyCode,
    Expression<String>? categoryId,
    Expression<String>? memo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (accountId != null) 'account_id': accountId,
      if (direction != null) 'direction': direction,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (categoryId != null) 'category_id': categoryId,
      if (memo != null) 'memo': memo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionPostingsViewCompanion copyWith(
      {Value<String>? id,
      Value<String>? transactionId,
      Value<String>? accountId,
      Value<PostingDirection>? direction,
      Value<int>? amountMinor,
      Value<String>? currencyCode,
      Value<String?>? categoryId,
      Value<String?>? memo,
      Value<int>? rowid}) {
    return TransactionPostingsViewCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      accountId: accountId ?? this.accountId,
      direction: direction ?? this.direction,
      amountMinor: amountMinor ?? this.amountMinor,
      currencyCode: currencyCode ?? this.currencyCode,
      categoryId: categoryId ?? this.categoryId,
      memo: memo ?? this.memo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (direction.present) {
      map['direction'] = Variable<int>($TransactionPostingsViewTable
          .$converterdirection
          .toSql(direction.value));
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionPostingsViewCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('accountId: $accountId, ')
          ..write('direction: $direction, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('categoryId: $categoryId, ')
          ..write('memo: $memo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesViewTable extends CategoriesView
    with TableInfo<$CategoriesViewTable, CategoryViewRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesViewTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconKeyMeta =
      const VerificationMeta('iconKey');
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
      'icon_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorIntMeta =
      const VerificationMeta('colorInt');
  @override
  late final GeneratedColumn<int> colorInt = GeneratedColumn<int>(
      'color_int', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<CategoryType, int> type =
      GeneratedColumn<int>('type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<CategoryType>($CategoriesViewTable.$convertertype);
  static const VerificationMeta _archivedMeta =
      const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
      'archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _systemCodeMeta =
      const VerificationMeta('systemCode');
  @override
  late final GeneratedColumn<String> systemCode = GeneratedColumn<String>(
      'system_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastUpdatedEventIdMeta =
      const VerificationMeta('lastUpdatedEventId');
  @override
  late final GeneratedColumn<int> lastUpdatedEventId = GeneratedColumn<int>(
      'last_updated_event_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _projectionVersionMeta =
      const VerificationMeta('projectionVersion');
  @override
  late final GeneratedColumn<int> projectionVersion = GeneratedColumn<int>(
      'projection_version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        iconKey,
        colorInt,
        type,
        archived,
        systemCode,
        lastUpdatedEventId,
        projectionVersion
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories_view';
  @override
  VerificationContext validateIntegrity(Insertable<CategoryViewRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon_key')) {
      context.handle(_iconKeyMeta,
          iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta));
    } else if (isInserting) {
      context.missing(_iconKeyMeta);
    }
    if (data.containsKey('color_int')) {
      context.handle(_colorIntMeta,
          colorInt.isAcceptableOrUnknown(data['color_int']!, _colorIntMeta));
    } else if (isInserting) {
      context.missing(_colorIntMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta,
          archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    if (data.containsKey('system_code')) {
      context.handle(
          _systemCodeMeta,
          systemCode.isAcceptableOrUnknown(
              data['system_code']!, _systemCodeMeta));
    }
    if (data.containsKey('last_updated_event_id')) {
      context.handle(
          _lastUpdatedEventIdMeta,
          lastUpdatedEventId.isAcceptableOrUnknown(
              data['last_updated_event_id']!, _lastUpdatedEventIdMeta));
    } else if (isInserting) {
      context.missing(_lastUpdatedEventIdMeta);
    }
    if (data.containsKey('projection_version')) {
      context.handle(
          _projectionVersionMeta,
          projectionVersion.isAcceptableOrUnknown(
              data['projection_version']!, _projectionVersionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryViewRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryViewRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      iconKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_key'])!,
      colorInt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color_int'])!,
      type: $CategoriesViewTable.$convertertype.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!),
      archived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
      systemCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}system_code']),
      lastUpdatedEventId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}last_updated_event_id'])!,
      projectionVersion: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}projection_version'])!,
    );
  }

  @override
  $CategoriesViewTable createAlias(String alias) {
    return $CategoriesViewTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CategoryType, int, int> $convertertype =
      const EnumIndexConverter<CategoryType>(CategoryType.values);
}

class CategoryViewRow extends DataClass implements Insertable<CategoryViewRow> {
  final String id;
  final String name;
  final String iconKey;
  final int colorInt;
  final CategoryType type;
  final bool archived;
  final String? systemCode;
  final int lastUpdatedEventId;
  final int projectionVersion;
  const CategoryViewRow(
      {required this.id,
      required this.name,
      required this.iconKey,
      required this.colorInt,
      required this.type,
      required this.archived,
      this.systemCode,
      required this.lastUpdatedEventId,
      required this.projectionVersion});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['icon_key'] = Variable<String>(iconKey);
    map['color_int'] = Variable<int>(colorInt);
    {
      map['type'] =
          Variable<int>($CategoriesViewTable.$convertertype.toSql(type));
    }
    map['archived'] = Variable<bool>(archived);
    if (!nullToAbsent || systemCode != null) {
      map['system_code'] = Variable<String>(systemCode);
    }
    map['last_updated_event_id'] = Variable<int>(lastUpdatedEventId);
    map['projection_version'] = Variable<int>(projectionVersion);
    return map;
  }

  CategoriesViewCompanion toCompanion(bool nullToAbsent) {
    return CategoriesViewCompanion(
      id: Value(id),
      name: Value(name),
      iconKey: Value(iconKey),
      colorInt: Value(colorInt),
      type: Value(type),
      archived: Value(archived),
      systemCode: systemCode == null && nullToAbsent
          ? const Value.absent()
          : Value(systemCode),
      lastUpdatedEventId: Value(lastUpdatedEventId),
      projectionVersion: Value(projectionVersion),
    );
  }

  factory CategoryViewRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryViewRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      iconKey: serializer.fromJson<String>(json['iconKey']),
      colorInt: serializer.fromJson<int>(json['colorInt']),
      type: $CategoriesViewTable.$convertertype
          .fromJson(serializer.fromJson<int>(json['type'])),
      archived: serializer.fromJson<bool>(json['archived']),
      systemCode: serializer.fromJson<String?>(json['systemCode']),
      lastUpdatedEventId: serializer.fromJson<int>(json['lastUpdatedEventId']),
      projectionVersion: serializer.fromJson<int>(json['projectionVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'iconKey': serializer.toJson<String>(iconKey),
      'colorInt': serializer.toJson<int>(colorInt),
      'type': serializer
          .toJson<int>($CategoriesViewTable.$convertertype.toJson(type)),
      'archived': serializer.toJson<bool>(archived),
      'systemCode': serializer.toJson<String?>(systemCode),
      'lastUpdatedEventId': serializer.toJson<int>(lastUpdatedEventId),
      'projectionVersion': serializer.toJson<int>(projectionVersion),
    };
  }

  CategoryViewRow copyWith(
          {String? id,
          String? name,
          String? iconKey,
          int? colorInt,
          CategoryType? type,
          bool? archived,
          Value<String?> systemCode = const Value.absent(),
          int? lastUpdatedEventId,
          int? projectionVersion}) =>
      CategoryViewRow(
        id: id ?? this.id,
        name: name ?? this.name,
        iconKey: iconKey ?? this.iconKey,
        colorInt: colorInt ?? this.colorInt,
        type: type ?? this.type,
        archived: archived ?? this.archived,
        systemCode: systemCode.present ? systemCode.value : this.systemCode,
        lastUpdatedEventId: lastUpdatedEventId ?? this.lastUpdatedEventId,
        projectionVersion: projectionVersion ?? this.projectionVersion,
      );
  CategoryViewRow copyWithCompanion(CategoriesViewCompanion data) {
    return CategoryViewRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      colorInt: data.colorInt.present ? data.colorInt.value : this.colorInt,
      type: data.type.present ? data.type.value : this.type,
      archived: data.archived.present ? data.archived.value : this.archived,
      systemCode:
          data.systemCode.present ? data.systemCode.value : this.systemCode,
      lastUpdatedEventId: data.lastUpdatedEventId.present
          ? data.lastUpdatedEventId.value
          : this.lastUpdatedEventId,
      projectionVersion: data.projectionVersion.present
          ? data.projectionVersion.value
          : this.projectionVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryViewRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorInt: $colorInt, ')
          ..write('type: $type, ')
          ..write('archived: $archived, ')
          ..write('systemCode: $systemCode, ')
          ..write('lastUpdatedEventId: $lastUpdatedEventId, ')
          ..write('projectionVersion: $projectionVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, iconKey, colorInt, type, archived,
      systemCode, lastUpdatedEventId, projectionVersion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryViewRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.iconKey == this.iconKey &&
          other.colorInt == this.colorInt &&
          other.type == this.type &&
          other.archived == this.archived &&
          other.systemCode == this.systemCode &&
          other.lastUpdatedEventId == this.lastUpdatedEventId &&
          other.projectionVersion == this.projectionVersion);
}

class CategoriesViewCompanion extends UpdateCompanion<CategoryViewRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> iconKey;
  final Value<int> colorInt;
  final Value<CategoryType> type;
  final Value<bool> archived;
  final Value<String?> systemCode;
  final Value<int> lastUpdatedEventId;
  final Value<int> projectionVersion;
  final Value<int> rowid;
  const CategoriesViewCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.colorInt = const Value.absent(),
    this.type = const Value.absent(),
    this.archived = const Value.absent(),
    this.systemCode = const Value.absent(),
    this.lastUpdatedEventId = const Value.absent(),
    this.projectionVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesViewCompanion.insert({
    required String id,
    required String name,
    required String iconKey,
    required int colorInt,
    required CategoryType type,
    this.archived = const Value.absent(),
    this.systemCode = const Value.absent(),
    required int lastUpdatedEventId,
    this.projectionVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        iconKey = Value(iconKey),
        colorInt = Value(colorInt),
        type = Value(type),
        lastUpdatedEventId = Value(lastUpdatedEventId);
  static Insertable<CategoryViewRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? iconKey,
    Expression<int>? colorInt,
    Expression<int>? type,
    Expression<bool>? archived,
    Expression<String>? systemCode,
    Expression<int>? lastUpdatedEventId,
    Expression<int>? projectionVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (iconKey != null) 'icon_key': iconKey,
      if (colorInt != null) 'color_int': colorInt,
      if (type != null) 'type': type,
      if (archived != null) 'archived': archived,
      if (systemCode != null) 'system_code': systemCode,
      if (lastUpdatedEventId != null)
        'last_updated_event_id': lastUpdatedEventId,
      if (projectionVersion != null) 'projection_version': projectionVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesViewCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? iconKey,
      Value<int>? colorInt,
      Value<CategoryType>? type,
      Value<bool>? archived,
      Value<String?>? systemCode,
      Value<int>? lastUpdatedEventId,
      Value<int>? projectionVersion,
      Value<int>? rowid}) {
    return CategoriesViewCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorInt: colorInt ?? this.colorInt,
      type: type ?? this.type,
      archived: archived ?? this.archived,
      systemCode: systemCode ?? this.systemCode,
      lastUpdatedEventId: lastUpdatedEventId ?? this.lastUpdatedEventId,
      projectionVersion: projectionVersion ?? this.projectionVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (colorInt.present) {
      map['color_int'] = Variable<int>(colorInt.value);
    }
    if (type.present) {
      map['type'] =
          Variable<int>($CategoriesViewTable.$convertertype.toSql(type.value));
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (systemCode.present) {
      map['system_code'] = Variable<String>(systemCode.value);
    }
    if (lastUpdatedEventId.present) {
      map['last_updated_event_id'] = Variable<int>(lastUpdatedEventId.value);
    }
    if (projectionVersion.present) {
      map['projection_version'] = Variable<int>(projectionVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesViewCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorInt: $colorInt, ')
          ..write('type: $type, ')
          ..write('archived: $archived, ')
          ..write('systemCode: $systemCode, ')
          ..write('lastUpdatedEventId: $lastUpdatedEventId, ')
          ..write('projectionVersion: $projectionVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecurringSeriesTable extends RecurringSeries
    with TableInfo<$RecurringSeriesTable, RecurringSeriesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringSeriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rruleMeta = const VerificationMeta('rrule');
  @override
  late final GeneratedColumn<String> rrule = GeneratedColumn<String>(
      'rrule', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'end_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _frequencyMeta =
      const VerificationMeta('frequency');
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
      'frequency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _intervalMeta =
      const VerificationMeta('interval');
  @override
  late final GeneratedColumn<int> interval = GeneratedColumn<int>(
      'interval', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _countLimitMeta =
      const VerificationMeta('countLimit');
  @override
  late final GeneratedColumn<int> countLimit = GeneratedColumn<int>(
      'count_limit', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _amountMinorMeta =
      const VerificationMeta('amountMinor');
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
      'amount_minor', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<TransactionKind, int> type =
      GeneratedColumn<int>('type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<TransactionKind>($RecurringSeriesTable.$convertertype);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        rrule,
        startDate,
        endDate,
        frequency,
        interval,
        countLimit,
        amountMinor,
        description,
        categoryId,
        accountId,
        type
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_series';
  @override
  VerificationContext validateIntegrity(Insertable<RecurringSeriesRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('rrule')) {
      context.handle(
          _rruleMeta, rrule.isAcceptableOrUnknown(data['rrule']!, _rruleMeta));
    } else if (isInserting) {
      context.missing(_rruleMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    }
    if (data.containsKey('frequency')) {
      context.handle(_frequencyMeta,
          frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta));
    } else if (isInserting) {
      context.missing(_frequencyMeta);
    }
    if (data.containsKey('interval')) {
      context.handle(_intervalMeta,
          interval.isAcceptableOrUnknown(data['interval']!, _intervalMeta));
    }
    if (data.containsKey('count_limit')) {
      context.handle(
          _countLimitMeta,
          countLimit.isAcceptableOrUnknown(
              data['count_limit']!, _countLimitMeta));
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
          _amountMinorMeta,
          amountMinor.isAcceptableOrUnknown(
              data['amount_minor']!, _amountMinorMeta));
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringSeriesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringSeriesRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      rrule: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rrule'])!,
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date']),
      frequency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}frequency'])!,
      interval: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}interval']),
      countLimit: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}count_limit']),
      amountMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_minor'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      type: $RecurringSeriesTable.$convertertype.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!),
    );
  }

  @override
  $RecurringSeriesTable createAlias(String alias) {
    return $RecurringSeriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TransactionKind, int, int> $convertertype =
      const EnumIndexConverter<TransactionKind>(TransactionKind.values);
}

class RecurringSeriesRow extends DataClass
    implements Insertable<RecurringSeriesRow> {
  final String id;
  final String rrule;
  final DateTime startDate;
  final DateTime? endDate;
  final String frequency;
  final int? interval;
  final int? countLimit;
  final int amountMinor;
  final String description;
  final String categoryId;
  final String accountId;
  final TransactionKind type;
  const RecurringSeriesRow(
      {required this.id,
      required this.rrule,
      required this.startDate,
      this.endDate,
      required this.frequency,
      this.interval,
      this.countLimit,
      required this.amountMinor,
      required this.description,
      required this.categoryId,
      required this.accountId,
      required this.type});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['rrule'] = Variable<String>(rrule);
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    map['frequency'] = Variable<String>(frequency);
    if (!nullToAbsent || interval != null) {
      map['interval'] = Variable<int>(interval);
    }
    if (!nullToAbsent || countLimit != null) {
      map['count_limit'] = Variable<int>(countLimit);
    }
    map['amount_minor'] = Variable<int>(amountMinor);
    map['description'] = Variable<String>(description);
    map['category_id'] = Variable<String>(categoryId);
    map['account_id'] = Variable<String>(accountId);
    {
      map['type'] =
          Variable<int>($RecurringSeriesTable.$convertertype.toSql(type));
    }
    return map;
  }

  RecurringSeriesCompanion toCompanion(bool nullToAbsent) {
    return RecurringSeriesCompanion(
      id: Value(id),
      rrule: Value(rrule),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      frequency: Value(frequency),
      interval: interval == null && nullToAbsent
          ? const Value.absent()
          : Value(interval),
      countLimit: countLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(countLimit),
      amountMinor: Value(amountMinor),
      description: Value(description),
      categoryId: Value(categoryId),
      accountId: Value(accountId),
      type: Value(type),
    );
  }

  factory RecurringSeriesRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringSeriesRow(
      id: serializer.fromJson<String>(json['id']),
      rrule: serializer.fromJson<String>(json['rrule']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      frequency: serializer.fromJson<String>(json['frequency']),
      interval: serializer.fromJson<int?>(json['interval']),
      countLimit: serializer.fromJson<int?>(json['countLimit']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      description: serializer.fromJson<String>(json['description']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      type: $RecurringSeriesTable.$convertertype
          .fromJson(serializer.fromJson<int>(json['type'])),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'rrule': serializer.toJson<String>(rrule),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'frequency': serializer.toJson<String>(frequency),
      'interval': serializer.toJson<int?>(interval),
      'countLimit': serializer.toJson<int?>(countLimit),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'description': serializer.toJson<String>(description),
      'categoryId': serializer.toJson<String>(categoryId),
      'accountId': serializer.toJson<String>(accountId),
      'type': serializer
          .toJson<int>($RecurringSeriesTable.$convertertype.toJson(type)),
    };
  }

  RecurringSeriesRow copyWith(
          {String? id,
          String? rrule,
          DateTime? startDate,
          Value<DateTime?> endDate = const Value.absent(),
          String? frequency,
          Value<int?> interval = const Value.absent(),
          Value<int?> countLimit = const Value.absent(),
          int? amountMinor,
          String? description,
          String? categoryId,
          String? accountId,
          TransactionKind? type}) =>
      RecurringSeriesRow(
        id: id ?? this.id,
        rrule: rrule ?? this.rrule,
        startDate: startDate ?? this.startDate,
        endDate: endDate.present ? endDate.value : this.endDate,
        frequency: frequency ?? this.frequency,
        interval: interval.present ? interval.value : this.interval,
        countLimit: countLimit.present ? countLimit.value : this.countLimit,
        amountMinor: amountMinor ?? this.amountMinor,
        description: description ?? this.description,
        categoryId: categoryId ?? this.categoryId,
        accountId: accountId ?? this.accountId,
        type: type ?? this.type,
      );
  RecurringSeriesRow copyWithCompanion(RecurringSeriesCompanion data) {
    return RecurringSeriesRow(
      id: data.id.present ? data.id.value : this.id,
      rrule: data.rrule.present ? data.rrule.value : this.rrule,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      interval: data.interval.present ? data.interval.value : this.interval,
      countLimit:
          data.countLimit.present ? data.countLimit.value : this.countLimit,
      amountMinor:
          data.amountMinor.present ? data.amountMinor.value : this.amountMinor,
      description:
          data.description.present ? data.description.value : this.description,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      type: data.type.present ? data.type.value : this.type,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringSeriesRow(')
          ..write('id: $id, ')
          ..write('rrule: $rrule, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('frequency: $frequency, ')
          ..write('interval: $interval, ')
          ..write('countLimit: $countLimit, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('description: $description, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      rrule,
      startDate,
      endDate,
      frequency,
      interval,
      countLimit,
      amountMinor,
      description,
      categoryId,
      accountId,
      type);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringSeriesRow &&
          other.id == this.id &&
          other.rrule == this.rrule &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.frequency == this.frequency &&
          other.interval == this.interval &&
          other.countLimit == this.countLimit &&
          other.amountMinor == this.amountMinor &&
          other.description == this.description &&
          other.categoryId == this.categoryId &&
          other.accountId == this.accountId &&
          other.type == this.type);
}

class RecurringSeriesCompanion extends UpdateCompanion<RecurringSeriesRow> {
  final Value<String> id;
  final Value<String> rrule;
  final Value<DateTime> startDate;
  final Value<DateTime?> endDate;
  final Value<String> frequency;
  final Value<int?> interval;
  final Value<int?> countLimit;
  final Value<int> amountMinor;
  final Value<String> description;
  final Value<String> categoryId;
  final Value<String> accountId;
  final Value<TransactionKind> type;
  final Value<int> rowid;
  const RecurringSeriesCompanion({
    this.id = const Value.absent(),
    this.rrule = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.frequency = const Value.absent(),
    this.interval = const Value.absent(),
    this.countLimit = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.description = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.type = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecurringSeriesCompanion.insert({
    required String id,
    required String rrule,
    required DateTime startDate,
    this.endDate = const Value.absent(),
    required String frequency,
    this.interval = const Value.absent(),
    this.countLimit = const Value.absent(),
    required int amountMinor,
    required String description,
    required String categoryId,
    required String accountId,
    required TransactionKind type,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        rrule = Value(rrule),
        startDate = Value(startDate),
        frequency = Value(frequency),
        amountMinor = Value(amountMinor),
        description = Value(description),
        categoryId = Value(categoryId),
        accountId = Value(accountId),
        type = Value(type);
  static Insertable<RecurringSeriesRow> custom({
    Expression<String>? id,
    Expression<String>? rrule,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<String>? frequency,
    Expression<int>? interval,
    Expression<int>? countLimit,
    Expression<int>? amountMinor,
    Expression<String>? description,
    Expression<String>? categoryId,
    Expression<String>? accountId,
    Expression<int>? type,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rrule != null) 'rrule': rrule,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (frequency != null) 'frequency': frequency,
      if (interval != null) 'interval': interval,
      if (countLimit != null) 'count_limit': countLimit,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (description != null) 'description': description,
      if (categoryId != null) 'category_id': categoryId,
      if (accountId != null) 'account_id': accountId,
      if (type != null) 'type': type,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecurringSeriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? rrule,
      Value<DateTime>? startDate,
      Value<DateTime?>? endDate,
      Value<String>? frequency,
      Value<int?>? interval,
      Value<int?>? countLimit,
      Value<int>? amountMinor,
      Value<String>? description,
      Value<String>? categoryId,
      Value<String>? accountId,
      Value<TransactionKind>? type,
      Value<int>? rowid}) {
    return RecurringSeriesCompanion(
      id: id ?? this.id,
      rrule: rrule ?? this.rrule,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      countLimit: countLimit ?? this.countLimit,
      amountMinor: amountMinor ?? this.amountMinor,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      type: type ?? this.type,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (rrule.present) {
      map['rrule'] = Variable<String>(rrule.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (interval.present) {
      map['interval'] = Variable<int>(interval.value);
    }
    if (countLimit.present) {
      map['count_limit'] = Variable<int>(countLimit.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (type.present) {
      map['type'] =
          Variable<int>($RecurringSeriesTable.$convertertype.toSql(type.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringSeriesCompanion(')
          ..write('id: $id, ')
          ..write('rrule: $rrule, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('frequency: $frequency, ')
          ..write('interval: $interval, ')
          ..write('countLimit: $countLimit, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('description: $description, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('type: $type, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScheduledTransactionsViewTable extends ScheduledTransactionsView
    with
        TableInfo<$ScheduledTransactionsViewTable,
            ScheduledTransactionViewRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduledTransactionsViewTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _seriesIdMeta =
      const VerificationMeta('seriesId');
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
      'series_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES recurring_series (id)'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _amountMinorMeta =
      const VerificationMeta('amountMinor');
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
      'amount_minor', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _transactionIdMeta =
      const VerificationMeta('transactionId');
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
      'transaction_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, seriesId, date, amountMinor, status, transactionId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scheduled_transactions_view';
  @override
  VerificationContext validateIntegrity(
      Insertable<ScheduledTransactionViewRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(_seriesIdMeta,
          seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta));
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
          _amountMinorMeta,
          amountMinor.isAcceptableOrUnknown(
              data['amount_minor']!, _amountMinorMeta));
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
          _transactionIdMeta,
          transactionId.isAcceptableOrUnknown(
              data['transaction_id']!, _transactionIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScheduledTransactionViewRow map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduledTransactionViewRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      seriesId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}series_id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      amountMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_minor'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      transactionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transaction_id']),
    );
  }

  @override
  $ScheduledTransactionsViewTable createAlias(String alias) {
    return $ScheduledTransactionsViewTable(attachedDatabase, alias);
  }
}

class ScheduledTransactionViewRow extends DataClass
    implements Insertable<ScheduledTransactionViewRow> {
  final String id;
  final String seriesId;
  final DateTime date;
  final int amountMinor;
  final String status;
  final String? transactionId;
  const ScheduledTransactionViewRow(
      {required this.id,
      required this.seriesId,
      required this.date,
      required this.amountMinor,
      required this.status,
      this.transactionId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['series_id'] = Variable<String>(seriesId);
    map['date'] = Variable<DateTime>(date);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || transactionId != null) {
      map['transaction_id'] = Variable<String>(transactionId);
    }
    return map;
  }

  ScheduledTransactionsViewCompanion toCompanion(bool nullToAbsent) {
    return ScheduledTransactionsViewCompanion(
      id: Value(id),
      seriesId: Value(seriesId),
      date: Value(date),
      amountMinor: Value(amountMinor),
      status: Value(status),
      transactionId: transactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionId),
    );
  }

  factory ScheduledTransactionViewRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduledTransactionViewRow(
      id: serializer.fromJson<String>(json['id']),
      seriesId: serializer.fromJson<String>(json['seriesId']),
      date: serializer.fromJson<DateTime>(json['date']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      status: serializer.fromJson<String>(json['status']),
      transactionId: serializer.fromJson<String?>(json['transactionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'seriesId': serializer.toJson<String>(seriesId),
      'date': serializer.toJson<DateTime>(date),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'status': serializer.toJson<String>(status),
      'transactionId': serializer.toJson<String?>(transactionId),
    };
  }

  ScheduledTransactionViewRow copyWith(
          {String? id,
          String? seriesId,
          DateTime? date,
          int? amountMinor,
          String? status,
          Value<String?> transactionId = const Value.absent()}) =>
      ScheduledTransactionViewRow(
        id: id ?? this.id,
        seriesId: seriesId ?? this.seriesId,
        date: date ?? this.date,
        amountMinor: amountMinor ?? this.amountMinor,
        status: status ?? this.status,
        transactionId:
            transactionId.present ? transactionId.value : this.transactionId,
      );
  ScheduledTransactionViewRow copyWithCompanion(
      ScheduledTransactionsViewCompanion data) {
    return ScheduledTransactionViewRow(
      id: data.id.present ? data.id.value : this.id,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      date: data.date.present ? data.date.value : this.date,
      amountMinor:
          data.amountMinor.present ? data.amountMinor.value : this.amountMinor,
      status: data.status.present ? data.status.value : this.status,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduledTransactionViewRow(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('date: $date, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('status: $status, ')
          ..write('transactionId: $transactionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, seriesId, date, amountMinor, status, transactionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduledTransactionViewRow &&
          other.id == this.id &&
          other.seriesId == this.seriesId &&
          other.date == this.date &&
          other.amountMinor == this.amountMinor &&
          other.status == this.status &&
          other.transactionId == this.transactionId);
}

class ScheduledTransactionsViewCompanion
    extends UpdateCompanion<ScheduledTransactionViewRow> {
  final Value<String> id;
  final Value<String> seriesId;
  final Value<DateTime> date;
  final Value<int> amountMinor;
  final Value<String> status;
  final Value<String?> transactionId;
  final Value<int> rowid;
  const ScheduledTransactionsViewCompanion({
    this.id = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.date = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.status = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScheduledTransactionsViewCompanion.insert({
    required String id,
    required String seriesId,
    required DateTime date,
    required int amountMinor,
    required String status,
    this.transactionId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        seriesId = Value(seriesId),
        date = Value(date),
        amountMinor = Value(amountMinor),
        status = Value(status);
  static Insertable<ScheduledTransactionViewRow> custom({
    Expression<String>? id,
    Expression<String>? seriesId,
    Expression<DateTime>? date,
    Expression<int>? amountMinor,
    Expression<String>? status,
    Expression<String>? transactionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seriesId != null) 'series_id': seriesId,
      if (date != null) 'date': date,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (status != null) 'status': status,
      if (transactionId != null) 'transaction_id': transactionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScheduledTransactionsViewCompanion copyWith(
      {Value<String>? id,
      Value<String>? seriesId,
      Value<DateTime>? date,
      Value<int>? amountMinor,
      Value<String>? status,
      Value<String?>? transactionId,
      Value<int>? rowid}) {
    return ScheduledTransactionsViewCompanion(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      date: date ?? this.date,
      amountMinor: amountMinor ?? this.amountMinor,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduledTransactionsViewCompanion(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('date: $date, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('status: $status, ')
          ..write('transactionId: $transactionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MonthlyAccountBalanceSnapshotsTable
    extends MonthlyAccountBalanceSnapshots
    with
        TableInfo<$MonthlyAccountBalanceSnapshotsTable,
            MonthlyAccountBalanceSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MonthlyAccountBalanceSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currencyCodeMeta =
      const VerificationMeta('currencyCode');
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
      'currency_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
      'year', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
      'month', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _openingBalanceMinorMeta =
      const VerificationMeta('openingBalanceMinor');
  @override
  late final GeneratedColumn<int> openingBalanceMinor = GeneratedColumn<int>(
      'opening_balance_minor', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _closingBalanceMinorMeta =
      const VerificationMeta('closingBalanceMinor');
  @override
  late final GeneratedColumn<int> closingBalanceMinor = GeneratedColumn<int>(
      'closing_balance_minor', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _incomeMinorMeta =
      const VerificationMeta('incomeMinor');
  @override
  late final GeneratedColumn<int> incomeMinor = GeneratedColumn<int>(
      'income_minor', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _expenseMinorMeta =
      const VerificationMeta('expenseMinor');
  @override
  late final GeneratedColumn<int> expenseMinor = GeneratedColumn<int>(
      'expense_minor', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _transferInMinorMeta =
      const VerificationMeta('transferInMinor');
  @override
  late final GeneratedColumn<int> transferInMinor = GeneratedColumn<int>(
      'transfer_in_minor', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _transferOutMinorMeta =
      const VerificationMeta('transferOutMinor');
  @override
  late final GeneratedColumn<int> transferOutMinor = GeneratedColumn<int>(
      'transfer_out_minor', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _netChangeMinorMeta =
      const VerificationMeta('netChangeMinor');
  @override
  late final GeneratedColumn<int> netChangeMinor = GeneratedColumn<int>(
      'net_change_minor', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _transactionCountMeta =
      const VerificationMeta('transactionCount');
  @override
  late final GeneratedColumn<int> transactionCount = GeneratedColumn<int>(
      'transaction_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _eventSequenceFromMeta =
      const VerificationMeta('eventSequenceFrom');
  @override
  late final GeneratedColumn<int> eventSequenceFrom = GeneratedColumn<int>(
      'event_sequence_from', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _eventSequenceToMeta =
      const VerificationMeta('eventSequenceTo');
  @override
  late final GeneratedColumn<int> eventSequenceTo = GeneratedColumn<int>(
      'event_sequence_to', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _projectionVersionMeta =
      const VerificationMeta('projectionVersion');
  @override
  late final GeneratedColumn<int> projectionVersion = GeneratedColumn<int>(
      'projection_version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _isClosedMeta =
      const VerificationMeta('isClosed');
  @override
  late final GeneratedColumn<bool> isClosed = GeneratedColumn<bool>(
      'is_closed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_closed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      clientDefault: () => DateTime.now());
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      clientDefault: () => DateTime.now());
  static const VerificationMeta _rebuiltAtMeta =
      const VerificationMeta('rebuiltAt');
  @override
  late final GeneratedColumn<DateTime> rebuiltAt = GeneratedColumn<DateTime>(
      'rebuilt_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        accountId,
        currencyCode,
        year,
        month,
        openingBalanceMinor,
        closingBalanceMinor,
        incomeMinor,
        expenseMinor,
        transferInMinor,
        transferOutMinor,
        netChangeMinor,
        transactionCount,
        eventSequenceFrom,
        eventSequenceTo,
        projectionVersion,
        isClosed,
        createdAt,
        updatedAt,
        rebuiltAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'monthly_account_balance_snapshots';
  @override
  VerificationContext validateIntegrity(
      Insertable<MonthlyAccountBalanceSnapshot> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
          _currencyCodeMeta,
          currencyCode.isAcceptableOrUnknown(
              data['currency_code']!, _currencyCodeMeta));
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
          _yearMeta, year.isAcceptableOrUnknown(data['year']!, _yearMeta));
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
          _monthMeta, month.isAcceptableOrUnknown(data['month']!, _monthMeta));
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('opening_balance_minor')) {
      context.handle(
          _openingBalanceMinorMeta,
          openingBalanceMinor.isAcceptableOrUnknown(
              data['opening_balance_minor']!, _openingBalanceMinorMeta));
    } else if (isInserting) {
      context.missing(_openingBalanceMinorMeta);
    }
    if (data.containsKey('closing_balance_minor')) {
      context.handle(
          _closingBalanceMinorMeta,
          closingBalanceMinor.isAcceptableOrUnknown(
              data['closing_balance_minor']!, _closingBalanceMinorMeta));
    } else if (isInserting) {
      context.missing(_closingBalanceMinorMeta);
    }
    if (data.containsKey('income_minor')) {
      context.handle(
          _incomeMinorMeta,
          incomeMinor.isAcceptableOrUnknown(
              data['income_minor']!, _incomeMinorMeta));
    } else if (isInserting) {
      context.missing(_incomeMinorMeta);
    }
    if (data.containsKey('expense_minor')) {
      context.handle(
          _expenseMinorMeta,
          expenseMinor.isAcceptableOrUnknown(
              data['expense_minor']!, _expenseMinorMeta));
    } else if (isInserting) {
      context.missing(_expenseMinorMeta);
    }
    if (data.containsKey('transfer_in_minor')) {
      context.handle(
          _transferInMinorMeta,
          transferInMinor.isAcceptableOrUnknown(
              data['transfer_in_minor']!, _transferInMinorMeta));
    } else if (isInserting) {
      context.missing(_transferInMinorMeta);
    }
    if (data.containsKey('transfer_out_minor')) {
      context.handle(
          _transferOutMinorMeta,
          transferOutMinor.isAcceptableOrUnknown(
              data['transfer_out_minor']!, _transferOutMinorMeta));
    } else if (isInserting) {
      context.missing(_transferOutMinorMeta);
    }
    if (data.containsKey('net_change_minor')) {
      context.handle(
          _netChangeMinorMeta,
          netChangeMinor.isAcceptableOrUnknown(
              data['net_change_minor']!, _netChangeMinorMeta));
    } else if (isInserting) {
      context.missing(_netChangeMinorMeta);
    }
    if (data.containsKey('transaction_count')) {
      context.handle(
          _transactionCountMeta,
          transactionCount.isAcceptableOrUnknown(
              data['transaction_count']!, _transactionCountMeta));
    } else if (isInserting) {
      context.missing(_transactionCountMeta);
    }
    if (data.containsKey('event_sequence_from')) {
      context.handle(
          _eventSequenceFromMeta,
          eventSequenceFrom.isAcceptableOrUnknown(
              data['event_sequence_from']!, _eventSequenceFromMeta));
    } else if (isInserting) {
      context.missing(_eventSequenceFromMeta);
    }
    if (data.containsKey('event_sequence_to')) {
      context.handle(
          _eventSequenceToMeta,
          eventSequenceTo.isAcceptableOrUnknown(
              data['event_sequence_to']!, _eventSequenceToMeta));
    } else if (isInserting) {
      context.missing(_eventSequenceToMeta);
    }
    if (data.containsKey('projection_version')) {
      context.handle(
          _projectionVersionMeta,
          projectionVersion.isAcceptableOrUnknown(
              data['projection_version']!, _projectionVersionMeta));
    }
    if (data.containsKey('is_closed')) {
      context.handle(_isClosedMeta,
          isClosed.isAcceptableOrUnknown(data['is_closed']!, _isClosedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('rebuilt_at')) {
      context.handle(_rebuiltAtMeta,
          rebuiltAt.isAcceptableOrUnknown(data['rebuilt_at']!, _rebuiltAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {accountId, currencyCode, year, month},
      ];
  @override
  MonthlyAccountBalanceSnapshot map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MonthlyAccountBalanceSnapshot(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      currencyCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency_code'])!,
      year: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}year'])!,
      month: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}month'])!,
      openingBalanceMinor: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}opening_balance_minor'])!,
      closingBalanceMinor: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}closing_balance_minor'])!,
      incomeMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}income_minor'])!,
      expenseMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}expense_minor'])!,
      transferInMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}transfer_in_minor'])!,
      transferOutMinor: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}transfer_out_minor'])!,
      netChangeMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}net_change_minor'])!,
      transactionCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}transaction_count'])!,
      eventSequenceFrom: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}event_sequence_from'])!,
      eventSequenceTo: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}event_sequence_to'])!,
      projectionVersion: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}projection_version'])!,
      isClosed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_closed'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      rebuiltAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}rebuilt_at']),
    );
  }

  @override
  $MonthlyAccountBalanceSnapshotsTable createAlias(String alias) {
    return $MonthlyAccountBalanceSnapshotsTable(attachedDatabase, alias);
  }
}

class MonthlyAccountBalanceSnapshot extends DataClass
    implements Insertable<MonthlyAccountBalanceSnapshot> {
  final int id;
  final String accountId;
  final String currencyCode;
  final int year;
  final int month;
  final int openingBalanceMinor;
  final int closingBalanceMinor;
  final int incomeMinor;
  final int expenseMinor;
  final int transferInMinor;
  final int transferOutMinor;
  final int netChangeMinor;
  final int transactionCount;
  final int eventSequenceFrom;
  final int eventSequenceTo;
  final int projectionVersion;
  final bool isClosed;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? rebuiltAt;
  const MonthlyAccountBalanceSnapshot(
      {required this.id,
      required this.accountId,
      required this.currencyCode,
      required this.year,
      required this.month,
      required this.openingBalanceMinor,
      required this.closingBalanceMinor,
      required this.incomeMinor,
      required this.expenseMinor,
      required this.transferInMinor,
      required this.transferOutMinor,
      required this.netChangeMinor,
      required this.transactionCount,
      required this.eventSequenceFrom,
      required this.eventSequenceTo,
      required this.projectionVersion,
      required this.isClosed,
      required this.createdAt,
      required this.updatedAt,
      this.rebuiltAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['account_id'] = Variable<String>(accountId);
    map['currency_code'] = Variable<String>(currencyCode);
    map['year'] = Variable<int>(year);
    map['month'] = Variable<int>(month);
    map['opening_balance_minor'] = Variable<int>(openingBalanceMinor);
    map['closing_balance_minor'] = Variable<int>(closingBalanceMinor);
    map['income_minor'] = Variable<int>(incomeMinor);
    map['expense_minor'] = Variable<int>(expenseMinor);
    map['transfer_in_minor'] = Variable<int>(transferInMinor);
    map['transfer_out_minor'] = Variable<int>(transferOutMinor);
    map['net_change_minor'] = Variable<int>(netChangeMinor);
    map['transaction_count'] = Variable<int>(transactionCount);
    map['event_sequence_from'] = Variable<int>(eventSequenceFrom);
    map['event_sequence_to'] = Variable<int>(eventSequenceTo);
    map['projection_version'] = Variable<int>(projectionVersion);
    map['is_closed'] = Variable<bool>(isClosed);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || rebuiltAt != null) {
      map['rebuilt_at'] = Variable<DateTime>(rebuiltAt);
    }
    return map;
  }

  MonthlyAccountBalanceSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return MonthlyAccountBalanceSnapshotsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      currencyCode: Value(currencyCode),
      year: Value(year),
      month: Value(month),
      openingBalanceMinor: Value(openingBalanceMinor),
      closingBalanceMinor: Value(closingBalanceMinor),
      incomeMinor: Value(incomeMinor),
      expenseMinor: Value(expenseMinor),
      transferInMinor: Value(transferInMinor),
      transferOutMinor: Value(transferOutMinor),
      netChangeMinor: Value(netChangeMinor),
      transactionCount: Value(transactionCount),
      eventSequenceFrom: Value(eventSequenceFrom),
      eventSequenceTo: Value(eventSequenceTo),
      projectionVersion: Value(projectionVersion),
      isClosed: Value(isClosed),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      rebuiltAt: rebuiltAt == null && nullToAbsent
          ? const Value.absent()
          : Value(rebuiltAt),
    );
  }

  factory MonthlyAccountBalanceSnapshot.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MonthlyAccountBalanceSnapshot(
      id: serializer.fromJson<int>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      year: serializer.fromJson<int>(json['year']),
      month: serializer.fromJson<int>(json['month']),
      openingBalanceMinor:
          serializer.fromJson<int>(json['openingBalanceMinor']),
      closingBalanceMinor:
          serializer.fromJson<int>(json['closingBalanceMinor']),
      incomeMinor: serializer.fromJson<int>(json['incomeMinor']),
      expenseMinor: serializer.fromJson<int>(json['expenseMinor']),
      transferInMinor: serializer.fromJson<int>(json['transferInMinor']),
      transferOutMinor: serializer.fromJson<int>(json['transferOutMinor']),
      netChangeMinor: serializer.fromJson<int>(json['netChangeMinor']),
      transactionCount: serializer.fromJson<int>(json['transactionCount']),
      eventSequenceFrom: serializer.fromJson<int>(json['eventSequenceFrom']),
      eventSequenceTo: serializer.fromJson<int>(json['eventSequenceTo']),
      projectionVersion: serializer.fromJson<int>(json['projectionVersion']),
      isClosed: serializer.fromJson<bool>(json['isClosed']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      rebuiltAt: serializer.fromJson<DateTime?>(json['rebuiltAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'accountId': serializer.toJson<String>(accountId),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'year': serializer.toJson<int>(year),
      'month': serializer.toJson<int>(month),
      'openingBalanceMinor': serializer.toJson<int>(openingBalanceMinor),
      'closingBalanceMinor': serializer.toJson<int>(closingBalanceMinor),
      'incomeMinor': serializer.toJson<int>(incomeMinor),
      'expenseMinor': serializer.toJson<int>(expenseMinor),
      'transferInMinor': serializer.toJson<int>(transferInMinor),
      'transferOutMinor': serializer.toJson<int>(transferOutMinor),
      'netChangeMinor': serializer.toJson<int>(netChangeMinor),
      'transactionCount': serializer.toJson<int>(transactionCount),
      'eventSequenceFrom': serializer.toJson<int>(eventSequenceFrom),
      'eventSequenceTo': serializer.toJson<int>(eventSequenceTo),
      'projectionVersion': serializer.toJson<int>(projectionVersion),
      'isClosed': serializer.toJson<bool>(isClosed),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'rebuiltAt': serializer.toJson<DateTime?>(rebuiltAt),
    };
  }

  MonthlyAccountBalanceSnapshot copyWith(
          {int? id,
          String? accountId,
          String? currencyCode,
          int? year,
          int? month,
          int? openingBalanceMinor,
          int? closingBalanceMinor,
          int? incomeMinor,
          int? expenseMinor,
          int? transferInMinor,
          int? transferOutMinor,
          int? netChangeMinor,
          int? transactionCount,
          int? eventSequenceFrom,
          int? eventSequenceTo,
          int? projectionVersion,
          bool? isClosed,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> rebuiltAt = const Value.absent()}) =>
      MonthlyAccountBalanceSnapshot(
        id: id ?? this.id,
        accountId: accountId ?? this.accountId,
        currencyCode: currencyCode ?? this.currencyCode,
        year: year ?? this.year,
        month: month ?? this.month,
        openingBalanceMinor: openingBalanceMinor ?? this.openingBalanceMinor,
        closingBalanceMinor: closingBalanceMinor ?? this.closingBalanceMinor,
        incomeMinor: incomeMinor ?? this.incomeMinor,
        expenseMinor: expenseMinor ?? this.expenseMinor,
        transferInMinor: transferInMinor ?? this.transferInMinor,
        transferOutMinor: transferOutMinor ?? this.transferOutMinor,
        netChangeMinor: netChangeMinor ?? this.netChangeMinor,
        transactionCount: transactionCount ?? this.transactionCount,
        eventSequenceFrom: eventSequenceFrom ?? this.eventSequenceFrom,
        eventSequenceTo: eventSequenceTo ?? this.eventSequenceTo,
        projectionVersion: projectionVersion ?? this.projectionVersion,
        isClosed: isClosed ?? this.isClosed,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        rebuiltAt: rebuiltAt.present ? rebuiltAt.value : this.rebuiltAt,
      );
  MonthlyAccountBalanceSnapshot copyWithCompanion(
      MonthlyAccountBalanceSnapshotsCompanion data) {
    return MonthlyAccountBalanceSnapshot(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      year: data.year.present ? data.year.value : this.year,
      month: data.month.present ? data.month.value : this.month,
      openingBalanceMinor: data.openingBalanceMinor.present
          ? data.openingBalanceMinor.value
          : this.openingBalanceMinor,
      closingBalanceMinor: data.closingBalanceMinor.present
          ? data.closingBalanceMinor.value
          : this.closingBalanceMinor,
      incomeMinor:
          data.incomeMinor.present ? data.incomeMinor.value : this.incomeMinor,
      expenseMinor: data.expenseMinor.present
          ? data.expenseMinor.value
          : this.expenseMinor,
      transferInMinor: data.transferInMinor.present
          ? data.transferInMinor.value
          : this.transferInMinor,
      transferOutMinor: data.transferOutMinor.present
          ? data.transferOutMinor.value
          : this.transferOutMinor,
      netChangeMinor: data.netChangeMinor.present
          ? data.netChangeMinor.value
          : this.netChangeMinor,
      transactionCount: data.transactionCount.present
          ? data.transactionCount.value
          : this.transactionCount,
      eventSequenceFrom: data.eventSequenceFrom.present
          ? data.eventSequenceFrom.value
          : this.eventSequenceFrom,
      eventSequenceTo: data.eventSequenceTo.present
          ? data.eventSequenceTo.value
          : this.eventSequenceTo,
      projectionVersion: data.projectionVersion.present
          ? data.projectionVersion.value
          : this.projectionVersion,
      isClosed: data.isClosed.present ? data.isClosed.value : this.isClosed,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      rebuiltAt: data.rebuiltAt.present ? data.rebuiltAt.value : this.rebuiltAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MonthlyAccountBalanceSnapshot(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('openingBalanceMinor: $openingBalanceMinor, ')
          ..write('closingBalanceMinor: $closingBalanceMinor, ')
          ..write('incomeMinor: $incomeMinor, ')
          ..write('expenseMinor: $expenseMinor, ')
          ..write('transferInMinor: $transferInMinor, ')
          ..write('transferOutMinor: $transferOutMinor, ')
          ..write('netChangeMinor: $netChangeMinor, ')
          ..write('transactionCount: $transactionCount, ')
          ..write('eventSequenceFrom: $eventSequenceFrom, ')
          ..write('eventSequenceTo: $eventSequenceTo, ')
          ..write('projectionVersion: $projectionVersion, ')
          ..write('isClosed: $isClosed, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rebuiltAt: $rebuiltAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      accountId,
      currencyCode,
      year,
      month,
      openingBalanceMinor,
      closingBalanceMinor,
      incomeMinor,
      expenseMinor,
      transferInMinor,
      transferOutMinor,
      netChangeMinor,
      transactionCount,
      eventSequenceFrom,
      eventSequenceTo,
      projectionVersion,
      isClosed,
      createdAt,
      updatedAt,
      rebuiltAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthlyAccountBalanceSnapshot &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.currencyCode == this.currencyCode &&
          other.year == this.year &&
          other.month == this.month &&
          other.openingBalanceMinor == this.openingBalanceMinor &&
          other.closingBalanceMinor == this.closingBalanceMinor &&
          other.incomeMinor == this.incomeMinor &&
          other.expenseMinor == this.expenseMinor &&
          other.transferInMinor == this.transferInMinor &&
          other.transferOutMinor == this.transferOutMinor &&
          other.netChangeMinor == this.netChangeMinor &&
          other.transactionCount == this.transactionCount &&
          other.eventSequenceFrom == this.eventSequenceFrom &&
          other.eventSequenceTo == this.eventSequenceTo &&
          other.projectionVersion == this.projectionVersion &&
          other.isClosed == this.isClosed &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.rebuiltAt == this.rebuiltAt);
}

class MonthlyAccountBalanceSnapshotsCompanion
    extends UpdateCompanion<MonthlyAccountBalanceSnapshot> {
  final Value<int> id;
  final Value<String> accountId;
  final Value<String> currencyCode;
  final Value<int> year;
  final Value<int> month;
  final Value<int> openingBalanceMinor;
  final Value<int> closingBalanceMinor;
  final Value<int> incomeMinor;
  final Value<int> expenseMinor;
  final Value<int> transferInMinor;
  final Value<int> transferOutMinor;
  final Value<int> netChangeMinor;
  final Value<int> transactionCount;
  final Value<int> eventSequenceFrom;
  final Value<int> eventSequenceTo;
  final Value<int> projectionVersion;
  final Value<bool> isClosed;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> rebuiltAt;
  const MonthlyAccountBalanceSnapshotsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.year = const Value.absent(),
    this.month = const Value.absent(),
    this.openingBalanceMinor = const Value.absent(),
    this.closingBalanceMinor = const Value.absent(),
    this.incomeMinor = const Value.absent(),
    this.expenseMinor = const Value.absent(),
    this.transferInMinor = const Value.absent(),
    this.transferOutMinor = const Value.absent(),
    this.netChangeMinor = const Value.absent(),
    this.transactionCount = const Value.absent(),
    this.eventSequenceFrom = const Value.absent(),
    this.eventSequenceTo = const Value.absent(),
    this.projectionVersion = const Value.absent(),
    this.isClosed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rebuiltAt = const Value.absent(),
  });
  MonthlyAccountBalanceSnapshotsCompanion.insert({
    this.id = const Value.absent(),
    required String accountId,
    required String currencyCode,
    required int year,
    required int month,
    required int openingBalanceMinor,
    required int closingBalanceMinor,
    required int incomeMinor,
    required int expenseMinor,
    required int transferInMinor,
    required int transferOutMinor,
    required int netChangeMinor,
    required int transactionCount,
    required int eventSequenceFrom,
    required int eventSequenceTo,
    this.projectionVersion = const Value.absent(),
    this.isClosed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rebuiltAt = const Value.absent(),
  })  : accountId = Value(accountId),
        currencyCode = Value(currencyCode),
        year = Value(year),
        month = Value(month),
        openingBalanceMinor = Value(openingBalanceMinor),
        closingBalanceMinor = Value(closingBalanceMinor),
        incomeMinor = Value(incomeMinor),
        expenseMinor = Value(expenseMinor),
        transferInMinor = Value(transferInMinor),
        transferOutMinor = Value(transferOutMinor),
        netChangeMinor = Value(netChangeMinor),
        transactionCount = Value(transactionCount),
        eventSequenceFrom = Value(eventSequenceFrom),
        eventSequenceTo = Value(eventSequenceTo);
  static Insertable<MonthlyAccountBalanceSnapshot> custom({
    Expression<int>? id,
    Expression<String>? accountId,
    Expression<String>? currencyCode,
    Expression<int>? year,
    Expression<int>? month,
    Expression<int>? openingBalanceMinor,
    Expression<int>? closingBalanceMinor,
    Expression<int>? incomeMinor,
    Expression<int>? expenseMinor,
    Expression<int>? transferInMinor,
    Expression<int>? transferOutMinor,
    Expression<int>? netChangeMinor,
    Expression<int>? transactionCount,
    Expression<int>? eventSequenceFrom,
    Expression<int>? eventSequenceTo,
    Expression<int>? projectionVersion,
    Expression<bool>? isClosed,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? rebuiltAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (year != null) 'year': year,
      if (month != null) 'month': month,
      if (openingBalanceMinor != null)
        'opening_balance_minor': openingBalanceMinor,
      if (closingBalanceMinor != null)
        'closing_balance_minor': closingBalanceMinor,
      if (incomeMinor != null) 'income_minor': incomeMinor,
      if (expenseMinor != null) 'expense_minor': expenseMinor,
      if (transferInMinor != null) 'transfer_in_minor': transferInMinor,
      if (transferOutMinor != null) 'transfer_out_minor': transferOutMinor,
      if (netChangeMinor != null) 'net_change_minor': netChangeMinor,
      if (transactionCount != null) 'transaction_count': transactionCount,
      if (eventSequenceFrom != null) 'event_sequence_from': eventSequenceFrom,
      if (eventSequenceTo != null) 'event_sequence_to': eventSequenceTo,
      if (projectionVersion != null) 'projection_version': projectionVersion,
      if (isClosed != null) 'is_closed': isClosed,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rebuiltAt != null) 'rebuilt_at': rebuiltAt,
    });
  }

  MonthlyAccountBalanceSnapshotsCompanion copyWith(
      {Value<int>? id,
      Value<String>? accountId,
      Value<String>? currencyCode,
      Value<int>? year,
      Value<int>? month,
      Value<int>? openingBalanceMinor,
      Value<int>? closingBalanceMinor,
      Value<int>? incomeMinor,
      Value<int>? expenseMinor,
      Value<int>? transferInMinor,
      Value<int>? transferOutMinor,
      Value<int>? netChangeMinor,
      Value<int>? transactionCount,
      Value<int>? eventSequenceFrom,
      Value<int>? eventSequenceTo,
      Value<int>? projectionVersion,
      Value<bool>? isClosed,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? rebuiltAt}) {
    return MonthlyAccountBalanceSnapshotsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      currencyCode: currencyCode ?? this.currencyCode,
      year: year ?? this.year,
      month: month ?? this.month,
      openingBalanceMinor: openingBalanceMinor ?? this.openingBalanceMinor,
      closingBalanceMinor: closingBalanceMinor ?? this.closingBalanceMinor,
      incomeMinor: incomeMinor ?? this.incomeMinor,
      expenseMinor: expenseMinor ?? this.expenseMinor,
      transferInMinor: transferInMinor ?? this.transferInMinor,
      transferOutMinor: transferOutMinor ?? this.transferOutMinor,
      netChangeMinor: netChangeMinor ?? this.netChangeMinor,
      transactionCount: transactionCount ?? this.transactionCount,
      eventSequenceFrom: eventSequenceFrom ?? this.eventSequenceFrom,
      eventSequenceTo: eventSequenceTo ?? this.eventSequenceTo,
      projectionVersion: projectionVersion ?? this.projectionVersion,
      isClosed: isClosed ?? this.isClosed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rebuiltAt: rebuiltAt ?? this.rebuiltAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (openingBalanceMinor.present) {
      map['opening_balance_minor'] = Variable<int>(openingBalanceMinor.value);
    }
    if (closingBalanceMinor.present) {
      map['closing_balance_minor'] = Variable<int>(closingBalanceMinor.value);
    }
    if (incomeMinor.present) {
      map['income_minor'] = Variable<int>(incomeMinor.value);
    }
    if (expenseMinor.present) {
      map['expense_minor'] = Variable<int>(expenseMinor.value);
    }
    if (transferInMinor.present) {
      map['transfer_in_minor'] = Variable<int>(transferInMinor.value);
    }
    if (transferOutMinor.present) {
      map['transfer_out_minor'] = Variable<int>(transferOutMinor.value);
    }
    if (netChangeMinor.present) {
      map['net_change_minor'] = Variable<int>(netChangeMinor.value);
    }
    if (transactionCount.present) {
      map['transaction_count'] = Variable<int>(transactionCount.value);
    }
    if (eventSequenceFrom.present) {
      map['event_sequence_from'] = Variable<int>(eventSequenceFrom.value);
    }
    if (eventSequenceTo.present) {
      map['event_sequence_to'] = Variable<int>(eventSequenceTo.value);
    }
    if (projectionVersion.present) {
      map['projection_version'] = Variable<int>(projectionVersion.value);
    }
    if (isClosed.present) {
      map['is_closed'] = Variable<bool>(isClosed.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rebuiltAt.present) {
      map['rebuilt_at'] = Variable<DateTime>(rebuiltAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MonthlyAccountBalanceSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('openingBalanceMinor: $openingBalanceMinor, ')
          ..write('closingBalanceMinor: $closingBalanceMinor, ')
          ..write('incomeMinor: $incomeMinor, ')
          ..write('expenseMinor: $expenseMinor, ')
          ..write('transferInMinor: $transferInMinor, ')
          ..write('transferOutMinor: $transferOutMinor, ')
          ..write('netChangeMinor: $netChangeMinor, ')
          ..write('transactionCount: $transactionCount, ')
          ..write('eventSequenceFrom: $eventSequenceFrom, ')
          ..write('eventSequenceTo: $eventSequenceTo, ')
          ..write('projectionVersion: $projectionVersion, ')
          ..write('isClosed: $isClosed, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rebuiltAt: $rebuiltAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LedgerEventsTable ledgerEvents = $LedgerEventsTable(this);
  late final $AccountsViewTable accountsView = $AccountsViewTable(this);
  late final $TransactionsViewTable transactionsView =
      $TransactionsViewTable(this);
  late final $TransactionPostingsViewTable transactionPostingsView =
      $TransactionPostingsViewTable(this);
  late final $CategoriesViewTable categoriesView = $CategoriesViewTable(this);
  late final $RecurringSeriesTable recurringSeries =
      $RecurringSeriesTable(this);
  late final $ScheduledTransactionsViewTable scheduledTransactionsView =
      $ScheduledTransactionsViewTable(this);
  late final $MonthlyAccountBalanceSnapshotsTable
      monthlyAccountBalanceSnapshots =
      $MonthlyAccountBalanceSnapshotsTable(this);
  late final Index idxLedgerEventsCommandId = Index(
      'idx_ledger_events_command_id',
      'CREATE INDEX idx_ledger_events_command_id ON ledger_events (command_id)');
  late final Index idxTransactionsViewOccurredAt = Index(
      'idx_transactions_view_occurred_at',
      'CREATE INDEX idx_transactions_view_occurred_at ON transactions_view (occurred_at)');
  late final Index idxTransactionPostingsTx = Index(
      'idx_transaction_postings_tx',
      'CREATE INDEX idx_transaction_postings_tx ON transaction_postings_view (transaction_id)');
  late final EventsDao eventsDao = EventsDao(this as AppDatabase);
  late final TransactionsDao transactionsDao =
      TransactionsDao(this as AppDatabase);
  late final AccountDao accountDao = AccountDao(this as AppDatabase);
  late final CategoriesDao categoriesDao = CategoriesDao(this as AppDatabase);
  late final RecurringDao recurringDao = RecurringDao(this as AppDatabase);
  late final MonthlySnapshotDao monthlySnapshotDao =
      MonthlySnapshotDao(this as AppDatabase);
  late final ReportsDao reportsDao = ReportsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        ledgerEvents,
        accountsView,
        transactionsView,
        transactionPostingsView,
        categoriesView,
        recurringSeries,
        scheduledTransactionsView,
        monthlyAccountBalanceSnapshots,
        idxLedgerEventsCommandId,
        idxTransactionsViewOccurredAt,
        idxTransactionPostingsTx
      ];
}

typedef $$LedgerEventsTableCreateCompanionBuilder = LedgerEventsCompanion
    Function({
  Value<int> id,
  required String eventId,
  required String streamId,
  required AggregateType aggregateType,
  required String eventType,
  required int streamVersion,
  required DateTime occurredAt,
  required DateTime recordedAt,
  required String commandId,
  required String payload,
});
typedef $$LedgerEventsTableUpdateCompanionBuilder = LedgerEventsCompanion
    Function({
  Value<int> id,
  Value<String> eventId,
  Value<String> streamId,
  Value<AggregateType> aggregateType,
  Value<String> eventType,
  Value<int> streamVersion,
  Value<DateTime> occurredAt,
  Value<DateTime> recordedAt,
  Value<String> commandId,
  Value<String> payload,
});

class $$LedgerEventsTableFilterComposer
    extends Composer<_$AppDatabase, $LedgerEventsTable> {
  $$LedgerEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventId => $composableBuilder(
      column: $table.eventId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get streamId => $composableBuilder(
      column: $table.streamId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<AggregateType, AggregateType, int>
      get aggregateType => $composableBuilder(
          column: $table.aggregateType,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get eventType => $composableBuilder(
      column: $table.eventType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get streamVersion => $composableBuilder(
      column: $table.streamVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get commandId => $composableBuilder(
      column: $table.commandId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));
}

class $$LedgerEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $LedgerEventsTable> {
  $$LedgerEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventId => $composableBuilder(
      column: $table.eventId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get streamId => $composableBuilder(
      column: $table.streamId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get aggregateType => $composableBuilder(
      column: $table.aggregateType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventType => $composableBuilder(
      column: $table.eventType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get streamVersion => $composableBuilder(
      column: $table.streamVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get commandId => $composableBuilder(
      column: $table.commandId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));
}

class $$LedgerEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LedgerEventsTable> {
  $$LedgerEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get streamId =>
      $composableBuilder(column: $table.streamId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AggregateType, int> get aggregateType =>
      $composableBuilder(
          column: $table.aggregateType, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<int> get streamVersion => $composableBuilder(
      column: $table.streamVersion, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => column);

  GeneratedColumn<String> get commandId =>
      $composableBuilder(column: $table.commandId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$LedgerEventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LedgerEventsTable,
    LedgerEventRow,
    $$LedgerEventsTableFilterComposer,
    $$LedgerEventsTableOrderingComposer,
    $$LedgerEventsTableAnnotationComposer,
    $$LedgerEventsTableCreateCompanionBuilder,
    $$LedgerEventsTableUpdateCompanionBuilder,
    (
      LedgerEventRow,
      BaseReferences<_$AppDatabase, $LedgerEventsTable, LedgerEventRow>
    ),
    LedgerEventRow,
    PrefetchHooks Function()> {
  $$LedgerEventsTableTableManager(_$AppDatabase db, $LedgerEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LedgerEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LedgerEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LedgerEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> eventId = const Value.absent(),
            Value<String> streamId = const Value.absent(),
            Value<AggregateType> aggregateType = const Value.absent(),
            Value<String> eventType = const Value.absent(),
            Value<int> streamVersion = const Value.absent(),
            Value<DateTime> occurredAt = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<String> commandId = const Value.absent(),
            Value<String> payload = const Value.absent(),
          }) =>
              LedgerEventsCompanion(
            id: id,
            eventId: eventId,
            streamId: streamId,
            aggregateType: aggregateType,
            eventType: eventType,
            streamVersion: streamVersion,
            occurredAt: occurredAt,
            recordedAt: recordedAt,
            commandId: commandId,
            payload: payload,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String eventId,
            required String streamId,
            required AggregateType aggregateType,
            required String eventType,
            required int streamVersion,
            required DateTime occurredAt,
            required DateTime recordedAt,
            required String commandId,
            required String payload,
          }) =>
              LedgerEventsCompanion.insert(
            id: id,
            eventId: eventId,
            streamId: streamId,
            aggregateType: aggregateType,
            eventType: eventType,
            streamVersion: streamVersion,
            occurredAt: occurredAt,
            recordedAt: recordedAt,
            commandId: commandId,
            payload: payload,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LedgerEventsTable, LedgerEventRow>(table),
                    BaseReferences<_$AppDatabase, $LedgerEventsTable,
                        LedgerEventRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LedgerEventsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LedgerEventsTable,
    LedgerEventRow,
    $$LedgerEventsTableFilterComposer,
    $$LedgerEventsTableOrderingComposer,
    $$LedgerEventsTableAnnotationComposer,
    $$LedgerEventsTableCreateCompanionBuilder,
    $$LedgerEventsTableUpdateCompanionBuilder,
    (
      LedgerEventRow,
      BaseReferences<_$AppDatabase, $LedgerEventsTable, LedgerEventRow>
    ),
    LedgerEventRow,
    PrefetchHooks Function()>;
typedef $$AccountsViewTableCreateCompanionBuilder = AccountsViewCompanion
    Function({
  required String id,
  required String name,
  required AccountType type,
  required String currencyCode,
  required int balanceMinor,
  Value<bool> archived,
  required int lastUpdatedEventId,
  Value<int> projectionVersion,
  Value<int> rowid,
});
typedef $$AccountsViewTableUpdateCompanionBuilder = AccountsViewCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<AccountType> type,
  Value<String> currencyCode,
  Value<int> balanceMinor,
  Value<bool> archived,
  Value<int> lastUpdatedEventId,
  Value<int> projectionVersion,
  Value<int> rowid,
});

class $$AccountsViewTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsViewTable> {
  $$AccountsViewTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<AccountType, AccountType, int> get type =>
      $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get balanceMinor => $composableBuilder(
      column: $table.balanceMinor, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastUpdatedEventId => $composableBuilder(
      column: $table.lastUpdatedEventId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get projectionVersion => $composableBuilder(
      column: $table.projectionVersion,
      builder: (column) => ColumnFilters(column));
}

class $$AccountsViewTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsViewTable> {
  $$AccountsViewTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get balanceMinor => $composableBuilder(
      column: $table.balanceMinor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastUpdatedEventId => $composableBuilder(
      column: $table.lastUpdatedEventId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get projectionVersion => $composableBuilder(
      column: $table.projectionVersion,
      builder: (column) => ColumnOrderings(column));
}

class $$AccountsViewTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsViewTable> {
  $$AccountsViewTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AccountType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode, builder: (column) => column);

  GeneratedColumn<int> get balanceMinor => $composableBuilder(
      column: $table.balanceMinor, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<int> get lastUpdatedEventId => $composableBuilder(
      column: $table.lastUpdatedEventId, builder: (column) => column);

  GeneratedColumn<int> get projectionVersion => $composableBuilder(
      column: $table.projectionVersion, builder: (column) => column);
}

class $$AccountsViewTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AccountsViewTable,
    AccountViewRow,
    $$AccountsViewTableFilterComposer,
    $$AccountsViewTableOrderingComposer,
    $$AccountsViewTableAnnotationComposer,
    $$AccountsViewTableCreateCompanionBuilder,
    $$AccountsViewTableUpdateCompanionBuilder,
    (
      AccountViewRow,
      BaseReferences<_$AppDatabase, $AccountsViewTable, AccountViewRow>
    ),
    AccountViewRow,
    PrefetchHooks Function()> {
  $$AccountsViewTableTableManager(_$AppDatabase db, $AccountsViewTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsViewTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsViewTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsViewTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<AccountType> type = const Value.absent(),
            Value<String> currencyCode = const Value.absent(),
            Value<int> balanceMinor = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<int> lastUpdatedEventId = const Value.absent(),
            Value<int> projectionVersion = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsViewCompanion(
            id: id,
            name: name,
            type: type,
            currencyCode: currencyCode,
            balanceMinor: balanceMinor,
            archived: archived,
            lastUpdatedEventId: lastUpdatedEventId,
            projectionVersion: projectionVersion,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required AccountType type,
            required String currencyCode,
            required int balanceMinor,
            Value<bool> archived = const Value.absent(),
            required int lastUpdatedEventId,
            Value<int> projectionVersion = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsViewCompanion.insert(
            id: id,
            name: name,
            type: type,
            currencyCode: currencyCode,
            balanceMinor: balanceMinor,
            archived: archived,
            lastUpdatedEventId: lastUpdatedEventId,
            projectionVersion: projectionVersion,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$AccountsViewTable, AccountViewRow>(table),
                    BaseReferences<_$AppDatabase, $AccountsViewTable,
                        AccountViewRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AccountsViewTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AccountsViewTable,
    AccountViewRow,
    $$AccountsViewTableFilterComposer,
    $$AccountsViewTableOrderingComposer,
    $$AccountsViewTableAnnotationComposer,
    $$AccountsViewTableCreateCompanionBuilder,
    $$AccountsViewTableUpdateCompanionBuilder,
    (
      AccountViewRow,
      BaseReferences<_$AppDatabase, $AccountsViewTable, AccountViewRow>
    ),
    AccountViewRow,
    PrefetchHooks Function()>;
typedef $$TransactionsViewTableCreateCompanionBuilder
    = TransactionsViewCompanion Function({
  required String transactionId,
  required DateTime occurredAt,
  required TransactionKind kind,
  required String description,
  Value<bool> isReversed,
  Value<String?> categoryName,
  Value<String?> categoryIcon,
  Value<String?> categoryColorInt,
  required int originalEventId,
  Value<int> projectionVersion,
  Value<int> rowid,
});
typedef $$TransactionsViewTableUpdateCompanionBuilder
    = TransactionsViewCompanion Function({
  Value<String> transactionId,
  Value<DateTime> occurredAt,
  Value<TransactionKind> kind,
  Value<String> description,
  Value<bool> isReversed,
  Value<String?> categoryName,
  Value<String?> categoryIcon,
  Value<String?> categoryColorInt,
  Value<int> originalEventId,
  Value<int> projectionVersion,
  Value<int> rowid,
});

class $$TransactionsViewTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsViewTable> {
  $$TransactionsViewTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get transactionId => $composableBuilder(
      column: $table.transactionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<TransactionKind, TransactionKind, int>
      get kind => $composableBuilder(
          column: $table.kind,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isReversed => $composableBuilder(
      column: $table.isReversed, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryName => $composableBuilder(
      column: $table.categoryName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryIcon => $composableBuilder(
      column: $table.categoryIcon, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryColorInt => $composableBuilder(
      column: $table.categoryColorInt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get originalEventId => $composableBuilder(
      column: $table.originalEventId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get projectionVersion => $composableBuilder(
      column: $table.projectionVersion,
      builder: (column) => ColumnFilters(column));
}

class $$TransactionsViewTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsViewTable> {
  $$TransactionsViewTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get transactionId => $composableBuilder(
      column: $table.transactionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isReversed => $composableBuilder(
      column: $table.isReversed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryName => $composableBuilder(
      column: $table.categoryName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryIcon => $composableBuilder(
      column: $table.categoryIcon,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryColorInt => $composableBuilder(
      column: $table.categoryColorInt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get originalEventId => $composableBuilder(
      column: $table.originalEventId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get projectionVersion => $composableBuilder(
      column: $table.projectionVersion,
      builder: (column) => ColumnOrderings(column));
}

class $$TransactionsViewTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsViewTable> {
  $$TransactionsViewTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get transactionId => $composableBuilder(
      column: $table.transactionId, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TransactionKind, int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<bool> get isReversed => $composableBuilder(
      column: $table.isReversed, builder: (column) => column);

  GeneratedColumn<String> get categoryName => $composableBuilder(
      column: $table.categoryName, builder: (column) => column);

  GeneratedColumn<String> get categoryIcon => $composableBuilder(
      column: $table.categoryIcon, builder: (column) => column);

  GeneratedColumn<String> get categoryColorInt => $composableBuilder(
      column: $table.categoryColorInt, builder: (column) => column);

  GeneratedColumn<int> get originalEventId => $composableBuilder(
      column: $table.originalEventId, builder: (column) => column);

  GeneratedColumn<int> get projectionVersion => $composableBuilder(
      column: $table.projectionVersion, builder: (column) => column);
}

class $$TransactionsViewTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransactionsViewTable,
    TransactionViewRow,
    $$TransactionsViewTableFilterComposer,
    $$TransactionsViewTableOrderingComposer,
    $$TransactionsViewTableAnnotationComposer,
    $$TransactionsViewTableCreateCompanionBuilder,
    $$TransactionsViewTableUpdateCompanionBuilder,
    (
      TransactionViewRow,
      BaseReferences<_$AppDatabase, $TransactionsViewTable, TransactionViewRow>
    ),
    TransactionViewRow,
    PrefetchHooks Function()> {
  $$TransactionsViewTableTableManager(
      _$AppDatabase db, $TransactionsViewTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsViewTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsViewTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsViewTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> transactionId = const Value.absent(),
            Value<DateTime> occurredAt = const Value.absent(),
            Value<TransactionKind> kind = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<bool> isReversed = const Value.absent(),
            Value<String?> categoryName = const Value.absent(),
            Value<String?> categoryIcon = const Value.absent(),
            Value<String?> categoryColorInt = const Value.absent(),
            Value<int> originalEventId = const Value.absent(),
            Value<int> projectionVersion = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsViewCompanion(
            transactionId: transactionId,
            occurredAt: occurredAt,
            kind: kind,
            description: description,
            isReversed: isReversed,
            categoryName: categoryName,
            categoryIcon: categoryIcon,
            categoryColorInt: categoryColorInt,
            originalEventId: originalEventId,
            projectionVersion: projectionVersion,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String transactionId,
            required DateTime occurredAt,
            required TransactionKind kind,
            required String description,
            Value<bool> isReversed = const Value.absent(),
            Value<String?> categoryName = const Value.absent(),
            Value<String?> categoryIcon = const Value.absent(),
            Value<String?> categoryColorInt = const Value.absent(),
            required int originalEventId,
            Value<int> projectionVersion = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsViewCompanion.insert(
            transactionId: transactionId,
            occurredAt: occurredAt,
            kind: kind,
            description: description,
            isReversed: isReversed,
            categoryName: categoryName,
            categoryIcon: categoryIcon,
            categoryColorInt: categoryColorInt,
            originalEventId: originalEventId,
            projectionVersion: projectionVersion,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$TransactionsViewTable, TransactionViewRow>(
                        table),
                    BaseReferences<_$AppDatabase, $TransactionsViewTable,
                        TransactionViewRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TransactionsViewTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransactionsViewTable,
    TransactionViewRow,
    $$TransactionsViewTableFilterComposer,
    $$TransactionsViewTableOrderingComposer,
    $$TransactionsViewTableAnnotationComposer,
    $$TransactionsViewTableCreateCompanionBuilder,
    $$TransactionsViewTableUpdateCompanionBuilder,
    (
      TransactionViewRow,
      BaseReferences<_$AppDatabase, $TransactionsViewTable, TransactionViewRow>
    ),
    TransactionViewRow,
    PrefetchHooks Function()>;
typedef $$TransactionPostingsViewTableCreateCompanionBuilder
    = TransactionPostingsViewCompanion Function({
  required String id,
  required String transactionId,
  required String accountId,
  required PostingDirection direction,
  required int amountMinor,
  required String currencyCode,
  Value<String?> categoryId,
  Value<String?> memo,
  Value<int> rowid,
});
typedef $$TransactionPostingsViewTableUpdateCompanionBuilder
    = TransactionPostingsViewCompanion Function({
  Value<String> id,
  Value<String> transactionId,
  Value<String> accountId,
  Value<PostingDirection> direction,
  Value<int> amountMinor,
  Value<String> currencyCode,
  Value<String?> categoryId,
  Value<String?> memo,
  Value<int> rowid,
});

class $$TransactionPostingsViewTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionPostingsViewTable> {
  $$TransactionPostingsViewTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transactionId => $composableBuilder(
      column: $table.transactionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<PostingDirection, PostingDirection, int>
      get direction => $composableBuilder(
          column: $table.direction,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get amountMinor => $composableBuilder(
      column: $table.amountMinor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memo => $composableBuilder(
      column: $table.memo, builder: (column) => ColumnFilters(column));
}

class $$TransactionPostingsViewTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionPostingsViewTable> {
  $$TransactionPostingsViewTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transactionId => $composableBuilder(
      column: $table.transactionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountMinor => $composableBuilder(
      column: $table.amountMinor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memo => $composableBuilder(
      column: $table.memo, builder: (column) => ColumnOrderings(column));
}

class $$TransactionPostingsViewTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionPostingsViewTable> {
  $$TransactionPostingsViewTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get transactionId => $composableBuilder(
      column: $table.transactionId, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PostingDirection, int> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
      column: $table.amountMinor, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);
}

class $$TransactionPostingsViewTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransactionPostingsViewTable,
    TransactionPostingRow,
    $$TransactionPostingsViewTableFilterComposer,
    $$TransactionPostingsViewTableOrderingComposer,
    $$TransactionPostingsViewTableAnnotationComposer,
    $$TransactionPostingsViewTableCreateCompanionBuilder,
    $$TransactionPostingsViewTableUpdateCompanionBuilder,
    (
      TransactionPostingRow,
      BaseReferences<_$AppDatabase, $TransactionPostingsViewTable,
          TransactionPostingRow>
    ),
    TransactionPostingRow,
    PrefetchHooks Function()> {
  $$TransactionPostingsViewTableTableManager(
      _$AppDatabase db, $TransactionPostingsViewTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionPostingsViewTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionPostingsViewTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionPostingsViewTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> transactionId = const Value.absent(),
            Value<String> accountId = const Value.absent(),
            Value<PostingDirection> direction = const Value.absent(),
            Value<int> amountMinor = const Value.absent(),
            Value<String> currencyCode = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<String?> memo = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionPostingsViewCompanion(
            id: id,
            transactionId: transactionId,
            accountId: accountId,
            direction: direction,
            amountMinor: amountMinor,
            currencyCode: currencyCode,
            categoryId: categoryId,
            memo: memo,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String transactionId,
            required String accountId,
            required PostingDirection direction,
            required int amountMinor,
            required String currencyCode,
            Value<String?> categoryId = const Value.absent(),
            Value<String?> memo = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionPostingsViewCompanion.insert(
            id: id,
            transactionId: transactionId,
            accountId: accountId,
            direction: direction,
            amountMinor: amountMinor,
            currencyCode: currencyCode,
            categoryId: categoryId,
            memo: memo,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$TransactionPostingsViewTable,
                        TransactionPostingRow>(table),
                    BaseReferences<_$AppDatabase, $TransactionPostingsViewTable,
                        TransactionPostingRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TransactionPostingsViewTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $TransactionPostingsViewTable,
        TransactionPostingRow,
        $$TransactionPostingsViewTableFilterComposer,
        $$TransactionPostingsViewTableOrderingComposer,
        $$TransactionPostingsViewTableAnnotationComposer,
        $$TransactionPostingsViewTableCreateCompanionBuilder,
        $$TransactionPostingsViewTableUpdateCompanionBuilder,
        (
          TransactionPostingRow,
          BaseReferences<_$AppDatabase, $TransactionPostingsViewTable,
              TransactionPostingRow>
        ),
        TransactionPostingRow,
        PrefetchHooks Function()>;
typedef $$CategoriesViewTableCreateCompanionBuilder = CategoriesViewCompanion
    Function({
  required String id,
  required String name,
  required String iconKey,
  required int colorInt,
  required CategoryType type,
  Value<bool> archived,
  Value<String?> systemCode,
  required int lastUpdatedEventId,
  Value<int> projectionVersion,
  Value<int> rowid,
});
typedef $$CategoriesViewTableUpdateCompanionBuilder = CategoriesViewCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> iconKey,
  Value<int> colorInt,
  Value<CategoryType> type,
  Value<bool> archived,
  Value<String?> systemCode,
  Value<int> lastUpdatedEventId,
  Value<int> projectionVersion,
  Value<int> rowid,
});

class $$CategoriesViewTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesViewTable> {
  $$CategoriesViewTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconKey => $composableBuilder(
      column: $table.iconKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get colorInt => $composableBuilder(
      column: $table.colorInt, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<CategoryType, CategoryType, int> get type =>
      $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get systemCode => $composableBuilder(
      column: $table.systemCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastUpdatedEventId => $composableBuilder(
      column: $table.lastUpdatedEventId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get projectionVersion => $composableBuilder(
      column: $table.projectionVersion,
      builder: (column) => ColumnFilters(column));
}

class $$CategoriesViewTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesViewTable> {
  $$CategoriesViewTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconKey => $composableBuilder(
      column: $table.iconKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get colorInt => $composableBuilder(
      column: $table.colorInt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get systemCode => $composableBuilder(
      column: $table.systemCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastUpdatedEventId => $composableBuilder(
      column: $table.lastUpdatedEventId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get projectionVersion => $composableBuilder(
      column: $table.projectionVersion,
      builder: (column) => ColumnOrderings(column));
}

class $$CategoriesViewTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesViewTable> {
  $$CategoriesViewTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<int> get colorInt =>
      $composableBuilder(column: $table.colorInt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CategoryType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<String> get systemCode => $composableBuilder(
      column: $table.systemCode, builder: (column) => column);

  GeneratedColumn<int> get lastUpdatedEventId => $composableBuilder(
      column: $table.lastUpdatedEventId, builder: (column) => column);

  GeneratedColumn<int> get projectionVersion => $composableBuilder(
      column: $table.projectionVersion, builder: (column) => column);
}

class $$CategoriesViewTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesViewTable,
    CategoryViewRow,
    $$CategoriesViewTableFilterComposer,
    $$CategoriesViewTableOrderingComposer,
    $$CategoriesViewTableAnnotationComposer,
    $$CategoriesViewTableCreateCompanionBuilder,
    $$CategoriesViewTableUpdateCompanionBuilder,
    (
      CategoryViewRow,
      BaseReferences<_$AppDatabase, $CategoriesViewTable, CategoryViewRow>
    ),
    CategoryViewRow,
    PrefetchHooks Function()> {
  $$CategoriesViewTableTableManager(
      _$AppDatabase db, $CategoriesViewTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesViewTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesViewTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesViewTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> iconKey = const Value.absent(),
            Value<int> colorInt = const Value.absent(),
            Value<CategoryType> type = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<String?> systemCode = const Value.absent(),
            Value<int> lastUpdatedEventId = const Value.absent(),
            Value<int> projectionVersion = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesViewCompanion(
            id: id,
            name: name,
            iconKey: iconKey,
            colorInt: colorInt,
            type: type,
            archived: archived,
            systemCode: systemCode,
            lastUpdatedEventId: lastUpdatedEventId,
            projectionVersion: projectionVersion,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String iconKey,
            required int colorInt,
            required CategoryType type,
            Value<bool> archived = const Value.absent(),
            Value<String?> systemCode = const Value.absent(),
            required int lastUpdatedEventId,
            Value<int> projectionVersion = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesViewCompanion.insert(
            id: id,
            name: name,
            iconKey: iconKey,
            colorInt: colorInt,
            type: type,
            archived: archived,
            systemCode: systemCode,
            lastUpdatedEventId: lastUpdatedEventId,
            projectionVersion: projectionVersion,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$CategoriesViewTable, CategoryViewRow>(table),
                    BaseReferences<_$AppDatabase, $CategoriesViewTable,
                        CategoryViewRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoriesViewTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesViewTable,
    CategoryViewRow,
    $$CategoriesViewTableFilterComposer,
    $$CategoriesViewTableOrderingComposer,
    $$CategoriesViewTableAnnotationComposer,
    $$CategoriesViewTableCreateCompanionBuilder,
    $$CategoriesViewTableUpdateCompanionBuilder,
    (
      CategoryViewRow,
      BaseReferences<_$AppDatabase, $CategoriesViewTable, CategoryViewRow>
    ),
    CategoryViewRow,
    PrefetchHooks Function()>;
typedef $$RecurringSeriesTableCreateCompanionBuilder = RecurringSeriesCompanion
    Function({
  required String id,
  required String rrule,
  required DateTime startDate,
  Value<DateTime?> endDate,
  required String frequency,
  Value<int?> interval,
  Value<int?> countLimit,
  required int amountMinor,
  required String description,
  required String categoryId,
  required String accountId,
  required TransactionKind type,
  Value<int> rowid,
});
typedef $$RecurringSeriesTableUpdateCompanionBuilder = RecurringSeriesCompanion
    Function({
  Value<String> id,
  Value<String> rrule,
  Value<DateTime> startDate,
  Value<DateTime?> endDate,
  Value<String> frequency,
  Value<int?> interval,
  Value<int?> countLimit,
  Value<int> amountMinor,
  Value<String> description,
  Value<String> categoryId,
  Value<String> accountId,
  Value<TransactionKind> type,
  Value<int> rowid,
});

final class $$RecurringSeriesTableReferences extends BaseReferences<
    _$AppDatabase, $RecurringSeriesTable, RecurringSeriesRow> {
  $$RecurringSeriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ScheduledTransactionsViewTable,
      List<ScheduledTransactionViewRow>> _scheduledTransactionsViewRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.scheduledTransactionsView,
          aliasName:
              'recurring_series__id__scheduled_transactions_view__series_id');

  $$ScheduledTransactionsViewTableProcessedTableManager
      get scheduledTransactionsViewRefs {
    final manager = $$ScheduledTransactionsViewTableTableManager(
            $_db, $_db.scheduledTransactionsView)
        .filter((f) => f.seriesId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult
        .readTableOrNull(_scheduledTransactionsViewRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$RecurringSeriesTableFilterComposer
    extends Composer<_$AppDatabase, $RecurringSeriesTable> {
  $$RecurringSeriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rrule => $composableBuilder(
      column: $table.rrule, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get frequency => $composableBuilder(
      column: $table.frequency, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get interval => $composableBuilder(
      column: $table.interval, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get countLimit => $composableBuilder(
      column: $table.countLimit, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountMinor => $composableBuilder(
      column: $table.amountMinor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<TransactionKind, TransactionKind, int>
      get type => $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  Expression<bool> scheduledTransactionsViewRefs(
      Expression<bool> Function(
              $$ScheduledTransactionsViewTableFilterComposer f)
          f) {
    final $$ScheduledTransactionsViewTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.scheduledTransactionsView,
            getReferencedColumn: (t) => t.seriesId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ScheduledTransactionsViewTableFilterComposer(
                  $db: $db,
                  $table: $db.scheduledTransactionsView,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$RecurringSeriesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurringSeriesTable> {
  $$RecurringSeriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rrule => $composableBuilder(
      column: $table.rrule, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get frequency => $composableBuilder(
      column: $table.frequency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get interval => $composableBuilder(
      column: $table.interval, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get countLimit => $composableBuilder(
      column: $table.countLimit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountMinor => $composableBuilder(
      column: $table.amountMinor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));
}

class $$RecurringSeriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurringSeriesTable> {
  $$RecurringSeriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rrule =>
      $composableBuilder(column: $table.rrule, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<int> get interval =>
      $composableBuilder(column: $table.interval, builder: (column) => column);

  GeneratedColumn<int> get countLimit => $composableBuilder(
      column: $table.countLimit, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
      column: $table.amountMinor, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TransactionKind, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  Expression<T> scheduledTransactionsViewRefs<T extends Object>(
      Expression<T> Function(
              $$ScheduledTransactionsViewTableAnnotationComposer a)
          f) {
    final $$ScheduledTransactionsViewTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.scheduledTransactionsView,
            getReferencedColumn: (t) => t.seriesId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ScheduledTransactionsViewTableAnnotationComposer(
                  $db: $db,
                  $table: $db.scheduledTransactionsView,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$RecurringSeriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecurringSeriesTable,
    RecurringSeriesRow,
    $$RecurringSeriesTableFilterComposer,
    $$RecurringSeriesTableOrderingComposer,
    $$RecurringSeriesTableAnnotationComposer,
    $$RecurringSeriesTableCreateCompanionBuilder,
    $$RecurringSeriesTableUpdateCompanionBuilder,
    (RecurringSeriesRow, $$RecurringSeriesTableReferences),
    RecurringSeriesRow,
    PrefetchHooks Function({bool scheduledTransactionsViewRefs})> {
  $$RecurringSeriesTableTableManager(
      _$AppDatabase db, $RecurringSeriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringSeriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurringSeriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurringSeriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> rrule = const Value.absent(),
            Value<DateTime> startDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<String> frequency = const Value.absent(),
            Value<int?> interval = const Value.absent(),
            Value<int?> countLimit = const Value.absent(),
            Value<int> amountMinor = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> categoryId = const Value.absent(),
            Value<String> accountId = const Value.absent(),
            Value<TransactionKind> type = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecurringSeriesCompanion(
            id: id,
            rrule: rrule,
            startDate: startDate,
            endDate: endDate,
            frequency: frequency,
            interval: interval,
            countLimit: countLimit,
            amountMinor: amountMinor,
            description: description,
            categoryId: categoryId,
            accountId: accountId,
            type: type,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String rrule,
            required DateTime startDate,
            Value<DateTime?> endDate = const Value.absent(),
            required String frequency,
            Value<int?> interval = const Value.absent(),
            Value<int?> countLimit = const Value.absent(),
            required int amountMinor,
            required String description,
            required String categoryId,
            required String accountId,
            required TransactionKind type,
            Value<int> rowid = const Value.absent(),
          }) =>
              RecurringSeriesCompanion.insert(
            id: id,
            rrule: rrule,
            startDate: startDate,
            endDate: endDate,
            frequency: frequency,
            interval: interval,
            countLimit: countLimit,
            amountMinor: amountMinor,
            description: description,
            categoryId: categoryId,
            accountId: accountId,
            type: type,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$RecurringSeriesTable, RecurringSeriesRow>(
                        table),
                    $$RecurringSeriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({scheduledTransactionsViewRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (scheduledTransactionsViewRefs) db.scheduledTransactionsView
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (scheduledTransactionsViewRefs)
                    await $_getPrefetchedData<RecurringSeriesRow,
                            $RecurringSeriesTable, ScheduledTransactionViewRow>(
                        currentTable: table,
                        referencedTable: $$RecurringSeriesTableReferences
                            ._scheduledTransactionsViewRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RecurringSeriesTableReferences(db, table, p0)
                                .scheduledTransactionsViewRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.seriesId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$RecurringSeriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecurringSeriesTable,
    RecurringSeriesRow,
    $$RecurringSeriesTableFilterComposer,
    $$RecurringSeriesTableOrderingComposer,
    $$RecurringSeriesTableAnnotationComposer,
    $$RecurringSeriesTableCreateCompanionBuilder,
    $$RecurringSeriesTableUpdateCompanionBuilder,
    (RecurringSeriesRow, $$RecurringSeriesTableReferences),
    RecurringSeriesRow,
    PrefetchHooks Function({bool scheduledTransactionsViewRefs})>;
typedef $$ScheduledTransactionsViewTableCreateCompanionBuilder
    = ScheduledTransactionsViewCompanion Function({
  required String id,
  required String seriesId,
  required DateTime date,
  required int amountMinor,
  required String status,
  Value<String?> transactionId,
  Value<int> rowid,
});
typedef $$ScheduledTransactionsViewTableUpdateCompanionBuilder
    = ScheduledTransactionsViewCompanion Function({
  Value<String> id,
  Value<String> seriesId,
  Value<DateTime> date,
  Value<int> amountMinor,
  Value<String> status,
  Value<String?> transactionId,
  Value<int> rowid,
});

final class $$ScheduledTransactionsViewTableReferences extends BaseReferences<
    _$AppDatabase,
    $ScheduledTransactionsViewTable,
    ScheduledTransactionViewRow> {
  $$ScheduledTransactionsViewTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $RecurringSeriesTable _seriesIdTable(_$AppDatabase db) =>
      db.recurringSeries.createAlias(
          'scheduled_transactions_view__series_id__recurring_series__id');

  $$RecurringSeriesTableProcessedTableManager get seriesId {
    final $_column = $_itemColumn<String>('series_id')!;

    final manager =
        $$RecurringSeriesTableTableManager($_db, $_db.recurringSeries)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seriesIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ScheduledTransactionsViewTableFilterComposer
    extends Composer<_$AppDatabase, $ScheduledTransactionsViewTable> {
  $$ScheduledTransactionsViewTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountMinor => $composableBuilder(
      column: $table.amountMinor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transactionId => $composableBuilder(
      column: $table.transactionId, builder: (column) => ColumnFilters(column));

  $$RecurringSeriesTableFilterComposer get seriesId {
    final $$RecurringSeriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.seriesId,
        referencedTable: $db.recurringSeries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecurringSeriesTableFilterComposer(
              $db: $db,
              $table: $db.recurringSeries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ScheduledTransactionsViewTableOrderingComposer
    extends Composer<_$AppDatabase, $ScheduledTransactionsViewTable> {
  $$ScheduledTransactionsViewTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountMinor => $composableBuilder(
      column: $table.amountMinor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transactionId => $composableBuilder(
      column: $table.transactionId,
      builder: (column) => ColumnOrderings(column));

  $$RecurringSeriesTableOrderingComposer get seriesId {
    final $$RecurringSeriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.seriesId,
        referencedTable: $db.recurringSeries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecurringSeriesTableOrderingComposer(
              $db: $db,
              $table: $db.recurringSeries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ScheduledTransactionsViewTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScheduledTransactionsViewTable> {
  $$ScheduledTransactionsViewTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
      column: $table.amountMinor, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get transactionId => $composableBuilder(
      column: $table.transactionId, builder: (column) => column);

  $$RecurringSeriesTableAnnotationComposer get seriesId {
    final $$RecurringSeriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.seriesId,
        referencedTable: $db.recurringSeries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecurringSeriesTableAnnotationComposer(
              $db: $db,
              $table: $db.recurringSeries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ScheduledTransactionsViewTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ScheduledTransactionsViewTable,
    ScheduledTransactionViewRow,
    $$ScheduledTransactionsViewTableFilterComposer,
    $$ScheduledTransactionsViewTableOrderingComposer,
    $$ScheduledTransactionsViewTableAnnotationComposer,
    $$ScheduledTransactionsViewTableCreateCompanionBuilder,
    $$ScheduledTransactionsViewTableUpdateCompanionBuilder,
    (ScheduledTransactionViewRow, $$ScheduledTransactionsViewTableReferences),
    ScheduledTransactionViewRow,
    PrefetchHooks Function({bool seriesId})> {
  $$ScheduledTransactionsViewTableTableManager(
      _$AppDatabase db, $ScheduledTransactionsViewTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScheduledTransactionsViewTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$ScheduledTransactionsViewTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScheduledTransactionsViewTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> seriesId = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<int> amountMinor = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> transactionId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ScheduledTransactionsViewCompanion(
            id: id,
            seriesId: seriesId,
            date: date,
            amountMinor: amountMinor,
            status: status,
            transactionId: transactionId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String seriesId,
            required DateTime date,
            required int amountMinor,
            required String status,
            Value<String?> transactionId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ScheduledTransactionsViewCompanion.insert(
            id: id,
            seriesId: seriesId,
            date: date,
            amountMinor: amountMinor,
            status: status,
            transactionId: transactionId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ScheduledTransactionsViewTable,
                        ScheduledTransactionViewRow>(table),
                    $$ScheduledTransactionsViewTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({seriesId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (seriesId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.seriesId,
                    referencedTable: $$ScheduledTransactionsViewTableReferences
                        ._seriesIdTable(db),
                    referencedColumn: $$ScheduledTransactionsViewTableReferences
                        ._seriesIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ScheduledTransactionsViewTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $ScheduledTransactionsViewTable,
        ScheduledTransactionViewRow,
        $$ScheduledTransactionsViewTableFilterComposer,
        $$ScheduledTransactionsViewTableOrderingComposer,
        $$ScheduledTransactionsViewTableAnnotationComposer,
        $$ScheduledTransactionsViewTableCreateCompanionBuilder,
        $$ScheduledTransactionsViewTableUpdateCompanionBuilder,
        (
          ScheduledTransactionViewRow,
          $$ScheduledTransactionsViewTableReferences
        ),
        ScheduledTransactionViewRow,
        PrefetchHooks Function({bool seriesId})>;
typedef $$MonthlyAccountBalanceSnapshotsTableCreateCompanionBuilder
    = MonthlyAccountBalanceSnapshotsCompanion Function({
  Value<int> id,
  required String accountId,
  required String currencyCode,
  required int year,
  required int month,
  required int openingBalanceMinor,
  required int closingBalanceMinor,
  required int incomeMinor,
  required int expenseMinor,
  required int transferInMinor,
  required int transferOutMinor,
  required int netChangeMinor,
  required int transactionCount,
  required int eventSequenceFrom,
  required int eventSequenceTo,
  Value<int> projectionVersion,
  Value<bool> isClosed,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> rebuiltAt,
});
typedef $$MonthlyAccountBalanceSnapshotsTableUpdateCompanionBuilder
    = MonthlyAccountBalanceSnapshotsCompanion Function({
  Value<int> id,
  Value<String> accountId,
  Value<String> currencyCode,
  Value<int> year,
  Value<int> month,
  Value<int> openingBalanceMinor,
  Value<int> closingBalanceMinor,
  Value<int> incomeMinor,
  Value<int> expenseMinor,
  Value<int> transferInMinor,
  Value<int> transferOutMinor,
  Value<int> netChangeMinor,
  Value<int> transactionCount,
  Value<int> eventSequenceFrom,
  Value<int> eventSequenceTo,
  Value<int> projectionVersion,
  Value<bool> isClosed,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> rebuiltAt,
});

class $$MonthlyAccountBalanceSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $MonthlyAccountBalanceSnapshotsTable> {
  $$MonthlyAccountBalanceSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get month => $composableBuilder(
      column: $table.month, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get openingBalanceMinor => $composableBuilder(
      column: $table.openingBalanceMinor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get closingBalanceMinor => $composableBuilder(
      column: $table.closingBalanceMinor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get incomeMinor => $composableBuilder(
      column: $table.incomeMinor, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get expenseMinor => $composableBuilder(
      column: $table.expenseMinor, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get transferInMinor => $composableBuilder(
      column: $table.transferInMinor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get transferOutMinor => $composableBuilder(
      column: $table.transferOutMinor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get netChangeMinor => $composableBuilder(
      column: $table.netChangeMinor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get transactionCount => $composableBuilder(
      column: $table.transactionCount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get eventSequenceFrom => $composableBuilder(
      column: $table.eventSequenceFrom,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get eventSequenceTo => $composableBuilder(
      column: $table.eventSequenceTo,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get projectionVersion => $composableBuilder(
      column: $table.projectionVersion,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isClosed => $composableBuilder(
      column: $table.isClosed, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get rebuiltAt => $composableBuilder(
      column: $table.rebuiltAt, builder: (column) => ColumnFilters(column));
}

class $$MonthlyAccountBalanceSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $MonthlyAccountBalanceSnapshotsTable> {
  $$MonthlyAccountBalanceSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get month => $composableBuilder(
      column: $table.month, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get openingBalanceMinor => $composableBuilder(
      column: $table.openingBalanceMinor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get closingBalanceMinor => $composableBuilder(
      column: $table.closingBalanceMinor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get incomeMinor => $composableBuilder(
      column: $table.incomeMinor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get expenseMinor => $composableBuilder(
      column: $table.expenseMinor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get transferInMinor => $composableBuilder(
      column: $table.transferInMinor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get transferOutMinor => $composableBuilder(
      column: $table.transferOutMinor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get netChangeMinor => $composableBuilder(
      column: $table.netChangeMinor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get transactionCount => $composableBuilder(
      column: $table.transactionCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get eventSequenceFrom => $composableBuilder(
      column: $table.eventSequenceFrom,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get eventSequenceTo => $composableBuilder(
      column: $table.eventSequenceTo,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get projectionVersion => $composableBuilder(
      column: $table.projectionVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isClosed => $composableBuilder(
      column: $table.isClosed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get rebuiltAt => $composableBuilder(
      column: $table.rebuiltAt, builder: (column) => ColumnOrderings(column));
}

class $$MonthlyAccountBalanceSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MonthlyAccountBalanceSnapshotsTable> {
  $$MonthlyAccountBalanceSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get openingBalanceMinor => $composableBuilder(
      column: $table.openingBalanceMinor, builder: (column) => column);

  GeneratedColumn<int> get closingBalanceMinor => $composableBuilder(
      column: $table.closingBalanceMinor, builder: (column) => column);

  GeneratedColumn<int> get incomeMinor => $composableBuilder(
      column: $table.incomeMinor, builder: (column) => column);

  GeneratedColumn<int> get expenseMinor => $composableBuilder(
      column: $table.expenseMinor, builder: (column) => column);

  GeneratedColumn<int> get transferInMinor => $composableBuilder(
      column: $table.transferInMinor, builder: (column) => column);

  GeneratedColumn<int> get transferOutMinor => $composableBuilder(
      column: $table.transferOutMinor, builder: (column) => column);

  GeneratedColumn<int> get netChangeMinor => $composableBuilder(
      column: $table.netChangeMinor, builder: (column) => column);

  GeneratedColumn<int> get transactionCount => $composableBuilder(
      column: $table.transactionCount, builder: (column) => column);

  GeneratedColumn<int> get eventSequenceFrom => $composableBuilder(
      column: $table.eventSequenceFrom, builder: (column) => column);

  GeneratedColumn<int> get eventSequenceTo => $composableBuilder(
      column: $table.eventSequenceTo, builder: (column) => column);

  GeneratedColumn<int> get projectionVersion => $composableBuilder(
      column: $table.projectionVersion, builder: (column) => column);

  GeneratedColumn<bool> get isClosed =>
      $composableBuilder(column: $table.isClosed, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get rebuiltAt =>
      $composableBuilder(column: $table.rebuiltAt, builder: (column) => column);
}

class $$MonthlyAccountBalanceSnapshotsTableTableManager
    extends RootTableManager<
        _$AppDatabase,
        $MonthlyAccountBalanceSnapshotsTable,
        MonthlyAccountBalanceSnapshot,
        $$MonthlyAccountBalanceSnapshotsTableFilterComposer,
        $$MonthlyAccountBalanceSnapshotsTableOrderingComposer,
        $$MonthlyAccountBalanceSnapshotsTableAnnotationComposer,
        $$MonthlyAccountBalanceSnapshotsTableCreateCompanionBuilder,
        $$MonthlyAccountBalanceSnapshotsTableUpdateCompanionBuilder,
        (
          MonthlyAccountBalanceSnapshot,
          BaseReferences<_$AppDatabase, $MonthlyAccountBalanceSnapshotsTable,
              MonthlyAccountBalanceSnapshot>
        ),
        MonthlyAccountBalanceSnapshot,
        PrefetchHooks Function()> {
  $$MonthlyAccountBalanceSnapshotsTableTableManager(
      _$AppDatabase db, $MonthlyAccountBalanceSnapshotsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MonthlyAccountBalanceSnapshotsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$MonthlyAccountBalanceSnapshotsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MonthlyAccountBalanceSnapshotsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> accountId = const Value.absent(),
            Value<String> currencyCode = const Value.absent(),
            Value<int> year = const Value.absent(),
            Value<int> month = const Value.absent(),
            Value<int> openingBalanceMinor = const Value.absent(),
            Value<int> closingBalanceMinor = const Value.absent(),
            Value<int> incomeMinor = const Value.absent(),
            Value<int> expenseMinor = const Value.absent(),
            Value<int> transferInMinor = const Value.absent(),
            Value<int> transferOutMinor = const Value.absent(),
            Value<int> netChangeMinor = const Value.absent(),
            Value<int> transactionCount = const Value.absent(),
            Value<int> eventSequenceFrom = const Value.absent(),
            Value<int> eventSequenceTo = const Value.absent(),
            Value<int> projectionVersion = const Value.absent(),
            Value<bool> isClosed = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> rebuiltAt = const Value.absent(),
          }) =>
              MonthlyAccountBalanceSnapshotsCompanion(
            id: id,
            accountId: accountId,
            currencyCode: currencyCode,
            year: year,
            month: month,
            openingBalanceMinor: openingBalanceMinor,
            closingBalanceMinor: closingBalanceMinor,
            incomeMinor: incomeMinor,
            expenseMinor: expenseMinor,
            transferInMinor: transferInMinor,
            transferOutMinor: transferOutMinor,
            netChangeMinor: netChangeMinor,
            transactionCount: transactionCount,
            eventSequenceFrom: eventSequenceFrom,
            eventSequenceTo: eventSequenceTo,
            projectionVersion: projectionVersion,
            isClosed: isClosed,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rebuiltAt: rebuiltAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String accountId,
            required String currencyCode,
            required int year,
            required int month,
            required int openingBalanceMinor,
            required int closingBalanceMinor,
            required int incomeMinor,
            required int expenseMinor,
            required int transferInMinor,
            required int transferOutMinor,
            required int netChangeMinor,
            required int transactionCount,
            required int eventSequenceFrom,
            required int eventSequenceTo,
            Value<int> projectionVersion = const Value.absent(),
            Value<bool> isClosed = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> rebuiltAt = const Value.absent(),
          }) =>
              MonthlyAccountBalanceSnapshotsCompanion.insert(
            id: id,
            accountId: accountId,
            currencyCode: currencyCode,
            year: year,
            month: month,
            openingBalanceMinor: openingBalanceMinor,
            closingBalanceMinor: closingBalanceMinor,
            incomeMinor: incomeMinor,
            expenseMinor: expenseMinor,
            transferInMinor: transferInMinor,
            transferOutMinor: transferOutMinor,
            netChangeMinor: netChangeMinor,
            transactionCount: transactionCount,
            eventSequenceFrom: eventSequenceFrom,
            eventSequenceTo: eventSequenceTo,
            projectionVersion: projectionVersion,
            isClosed: isClosed,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rebuiltAt: rebuiltAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$MonthlyAccountBalanceSnapshotsTable,
                        MonthlyAccountBalanceSnapshot>(table),
                    BaseReferences<
                        _$AppDatabase,
                        $MonthlyAccountBalanceSnapshotsTable,
                        MonthlyAccountBalanceSnapshot>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MonthlyAccountBalanceSnapshotsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $MonthlyAccountBalanceSnapshotsTable,
        MonthlyAccountBalanceSnapshot,
        $$MonthlyAccountBalanceSnapshotsTableFilterComposer,
        $$MonthlyAccountBalanceSnapshotsTableOrderingComposer,
        $$MonthlyAccountBalanceSnapshotsTableAnnotationComposer,
        $$MonthlyAccountBalanceSnapshotsTableCreateCompanionBuilder,
        $$MonthlyAccountBalanceSnapshotsTableUpdateCompanionBuilder,
        (
          MonthlyAccountBalanceSnapshot,
          BaseReferences<_$AppDatabase, $MonthlyAccountBalanceSnapshotsTable,
              MonthlyAccountBalanceSnapshot>
        ),
        MonthlyAccountBalanceSnapshot,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LedgerEventsTableTableManager get ledgerEvents =>
      $$LedgerEventsTableTableManager(_db, _db.ledgerEvents);
  $$AccountsViewTableTableManager get accountsView =>
      $$AccountsViewTableTableManager(_db, _db.accountsView);
  $$TransactionsViewTableTableManager get transactionsView =>
      $$TransactionsViewTableTableManager(_db, _db.transactionsView);
  $$TransactionPostingsViewTableTableManager get transactionPostingsView =>
      $$TransactionPostingsViewTableTableManager(
          _db, _db.transactionPostingsView);
  $$CategoriesViewTableTableManager get categoriesView =>
      $$CategoriesViewTableTableManager(_db, _db.categoriesView);
  $$RecurringSeriesTableTableManager get recurringSeries =>
      $$RecurringSeriesTableTableManager(_db, _db.recurringSeries);
  $$ScheduledTransactionsViewTableTableManager get scheduledTransactionsView =>
      $$ScheduledTransactionsViewTableTableManager(
          _db, _db.scheduledTransactionsView);
  $$MonthlyAccountBalanceSnapshotsTableTableManager
      get monthlyAccountBalanceSnapshots =>
          $$MonthlyAccountBalanceSnapshotsTableTableManager(
              _db, _db.monthlyAccountBalanceSnapshots);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  AppDatabaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'appDatabaseProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'8c69eb46d45206533c176c88a926608e79ca927d';
