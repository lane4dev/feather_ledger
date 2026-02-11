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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
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
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _correlationIdMeta =
      const VerificationMeta('correlationId');
  @override
  late final GeneratedColumn<String> correlationId = GeneratedColumn<String>(
      'correlation_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _metadataMeta =
      const VerificationMeta('metadata');
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
      'metadata', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        eventId,
        type,
        occurredAt,
        recordedAt,
        payload,
        correlationId,
        metadata
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
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
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
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('correlation_id')) {
      context.handle(
          _correlationIdMeta,
          correlationId.isAcceptableOrUnknown(
              data['correlation_id']!, _correlationIdMeta));
    }
    if (data.containsKey('metadata')) {
      context.handle(_metadataMeta,
          metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LedgerEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerEventRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      occurredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}occurred_at'])!,
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      correlationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}correlation_id']),
      metadata: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata']),
    );
  }

  @override
  $LedgerEventsTable createAlias(String alias) {
    return $LedgerEventsTable(attachedDatabase, alias);
  }
}

class LedgerEventRow extends DataClass implements Insertable<LedgerEventRow> {
  final int id;
  final String eventId;
  final String type;
  final DateTime occurredAt;
  final DateTime recordedAt;
  final String payload;
  final String? correlationId;
  final String? metadata;
  const LedgerEventRow(
      {required this.id,
      required this.eventId,
      required this.type,
      required this.occurredAt,
      required this.recordedAt,
      required this.payload,
      this.correlationId,
      this.metadata});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['event_id'] = Variable<String>(eventId);
    map['type'] = Variable<String>(type);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || correlationId != null) {
      map['correlation_id'] = Variable<String>(correlationId);
    }
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    return map;
  }

  LedgerEventsCompanion toCompanion(bool nullToAbsent) {
    return LedgerEventsCompanion(
      id: Value(id),
      eventId: Value(eventId),
      type: Value(type),
      occurredAt: Value(occurredAt),
      recordedAt: Value(recordedAt),
      payload: Value(payload),
      correlationId: correlationId == null && nullToAbsent
          ? const Value.absent()
          : Value(correlationId),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
    );
  }

  factory LedgerEventRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerEventRow(
      id: serializer.fromJson<int>(json['id']),
      eventId: serializer.fromJson<String>(json['eventId']),
      type: serializer.fromJson<String>(json['type']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      payload: serializer.fromJson<String>(json['payload']),
      correlationId: serializer.fromJson<String?>(json['correlationId']),
      metadata: serializer.fromJson<String?>(json['metadata']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'eventId': serializer.toJson<String>(eventId),
      'type': serializer.toJson<String>(type),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'payload': serializer.toJson<String>(payload),
      'correlationId': serializer.toJson<String?>(correlationId),
      'metadata': serializer.toJson<String?>(metadata),
    };
  }

  LedgerEventRow copyWith(
          {int? id,
          String? eventId,
          String? type,
          DateTime? occurredAt,
          DateTime? recordedAt,
          String? payload,
          Value<String?> correlationId = const Value.absent(),
          Value<String?> metadata = const Value.absent()}) =>
      LedgerEventRow(
        id: id ?? this.id,
        eventId: eventId ?? this.eventId,
        type: type ?? this.type,
        occurredAt: occurredAt ?? this.occurredAt,
        recordedAt: recordedAt ?? this.recordedAt,
        payload: payload ?? this.payload,
        correlationId:
            correlationId.present ? correlationId.value : this.correlationId,
        metadata: metadata.present ? metadata.value : this.metadata,
      );
  LedgerEventRow copyWithCompanion(LedgerEventsCompanion data) {
    return LedgerEventRow(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      type: data.type.present ? data.type.value : this.type,
      occurredAt:
          data.occurredAt.present ? data.occurredAt.value : this.occurredAt,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
      payload: data.payload.present ? data.payload.value : this.payload,
      correlationId: data.correlationId.present
          ? data.correlationId.value
          : this.correlationId,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEventRow(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('type: $type, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('payload: $payload, ')
          ..write('correlationId: $correlationId, ')
          ..write('metadata: $metadata')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, eventId, type, occurredAt, recordedAt,
      payload, correlationId, metadata);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerEventRow &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.type == this.type &&
          other.occurredAt == this.occurredAt &&
          other.recordedAt == this.recordedAt &&
          other.payload == this.payload &&
          other.correlationId == this.correlationId &&
          other.metadata == this.metadata);
}

class LedgerEventsCompanion extends UpdateCompanion<LedgerEventRow> {
  final Value<int> id;
  final Value<String> eventId;
  final Value<String> type;
  final Value<DateTime> occurredAt;
  final Value<DateTime> recordedAt;
  final Value<String> payload;
  final Value<String?> correlationId;
  final Value<String?> metadata;
  const LedgerEventsCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.type = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.payload = const Value.absent(),
    this.correlationId = const Value.absent(),
    this.metadata = const Value.absent(),
  });
  LedgerEventsCompanion.insert({
    this.id = const Value.absent(),
    required String eventId,
    required String type,
    required DateTime occurredAt,
    required DateTime recordedAt,
    required String payload,
    this.correlationId = const Value.absent(),
    this.metadata = const Value.absent(),
  })  : eventId = Value(eventId),
        type = Value(type),
        occurredAt = Value(occurredAt),
        recordedAt = Value(recordedAt),
        payload = Value(payload);
  static Insertable<LedgerEventRow> custom({
    Expression<int>? id,
    Expression<String>? eventId,
    Expression<String>? type,
    Expression<DateTime>? occurredAt,
    Expression<DateTime>? recordedAt,
    Expression<String>? payload,
    Expression<String>? correlationId,
    Expression<String>? metadata,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (type != null) 'type': type,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (payload != null) 'payload': payload,
      if (correlationId != null) 'correlation_id': correlationId,
      if (metadata != null) 'metadata': metadata,
    });
  }

  LedgerEventsCompanion copyWith(
      {Value<int>? id,
      Value<String>? eventId,
      Value<String>? type,
      Value<DateTime>? occurredAt,
      Value<DateTime>? recordedAt,
      Value<String>? payload,
      Value<String?>? correlationId,
      Value<String?>? metadata}) {
    return LedgerEventsCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      type: type ?? this.type,
      occurredAt: occurredAt ?? this.occurredAt,
      recordedAt: recordedAt ?? this.recordedAt,
      payload: payload ?? this.payload,
      correlationId: correlationId ?? this.correlationId,
      metadata: metadata ?? this.metadata,
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (correlationId.present) {
      map['correlation_id'] = Variable<String>(correlationId.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEventsCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('type: $type, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('payload: $payload, ')
          ..write('correlationId: $correlationId, ')
          ..write('metadata: $metadata')
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
  static const VerificationMeta _postedBalanceMeta =
      const VerificationMeta('postedBalance');
  @override
  late final GeneratedColumn<int> postedBalance = GeneratedColumn<int>(
      'posted_balance', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _availableBalanceMeta =
      const VerificationMeta('availableBalance');
  @override
  late final GeneratedColumn<int> availableBalance = GeneratedColumn<int>(
      'available_balance', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastUpdatedEventIdMeta =
      const VerificationMeta('lastUpdatedEventId');
  @override
  late final GeneratedColumn<int> lastUpdatedEventId = GeneratedColumn<int>(
      'last_updated_event_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, type, postedBalance, availableBalance, lastUpdatedEventId];
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
    if (data.containsKey('posted_balance')) {
      context.handle(
          _postedBalanceMeta,
          postedBalance.isAcceptableOrUnknown(
              data['posted_balance']!, _postedBalanceMeta));
    } else if (isInserting) {
      context.missing(_postedBalanceMeta);
    }
    if (data.containsKey('available_balance')) {
      context.handle(
          _availableBalanceMeta,
          availableBalance.isAcceptableOrUnknown(
              data['available_balance']!, _availableBalanceMeta));
    } else if (isInserting) {
      context.missing(_availableBalanceMeta);
    }
    if (data.containsKey('last_updated_event_id')) {
      context.handle(
          _lastUpdatedEventIdMeta,
          lastUpdatedEventId.isAcceptableOrUnknown(
              data['last_updated_event_id']!, _lastUpdatedEventIdMeta));
    } else if (isInserting) {
      context.missing(_lastUpdatedEventIdMeta);
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
      postedBalance: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}posted_balance'])!,
      availableBalance: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}available_balance'])!,
      lastUpdatedEventId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}last_updated_event_id'])!,
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
  final int postedBalance;
  final int availableBalance;
  final int lastUpdatedEventId;
  const AccountViewRow(
      {required this.id,
      required this.name,
      required this.type,
      required this.postedBalance,
      required this.availableBalance,
      required this.lastUpdatedEventId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['type'] =
          Variable<int>($AccountsViewTable.$convertertype.toSql(type));
    }
    map['posted_balance'] = Variable<int>(postedBalance);
    map['available_balance'] = Variable<int>(availableBalance);
    map['last_updated_event_id'] = Variable<int>(lastUpdatedEventId);
    return map;
  }

  AccountsViewCompanion toCompanion(bool nullToAbsent) {
    return AccountsViewCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      postedBalance: Value(postedBalance),
      availableBalance: Value(availableBalance),
      lastUpdatedEventId: Value(lastUpdatedEventId),
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
      postedBalance: serializer.fromJson<int>(json['postedBalance']),
      availableBalance: serializer.fromJson<int>(json['availableBalance']),
      lastUpdatedEventId: serializer.fromJson<int>(json['lastUpdatedEventId']),
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
      'postedBalance': serializer.toJson<int>(postedBalance),
      'availableBalance': serializer.toJson<int>(availableBalance),
      'lastUpdatedEventId': serializer.toJson<int>(lastUpdatedEventId),
    };
  }

  AccountViewRow copyWith(
          {String? id,
          String? name,
          AccountType? type,
          int? postedBalance,
          int? availableBalance,
          int? lastUpdatedEventId}) =>
      AccountViewRow(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        postedBalance: postedBalance ?? this.postedBalance,
        availableBalance: availableBalance ?? this.availableBalance,
        lastUpdatedEventId: lastUpdatedEventId ?? this.lastUpdatedEventId,
      );
  AccountViewRow copyWithCompanion(AccountsViewCompanion data) {
    return AccountViewRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      postedBalance: data.postedBalance.present
          ? data.postedBalance.value
          : this.postedBalance,
      availableBalance: data.availableBalance.present
          ? data.availableBalance.value
          : this.availableBalance,
      lastUpdatedEventId: data.lastUpdatedEventId.present
          ? data.lastUpdatedEventId.value
          : this.lastUpdatedEventId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountViewRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('postedBalance: $postedBalance, ')
          ..write('availableBalance: $availableBalance, ')
          ..write('lastUpdatedEventId: $lastUpdatedEventId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, type, postedBalance, availableBalance, lastUpdatedEventId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountViewRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.postedBalance == this.postedBalance &&
          other.availableBalance == this.availableBalance &&
          other.lastUpdatedEventId == this.lastUpdatedEventId);
}

class AccountsViewCompanion extends UpdateCompanion<AccountViewRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<AccountType> type;
  final Value<int> postedBalance;
  final Value<int> availableBalance;
  final Value<int> lastUpdatedEventId;
  final Value<int> rowid;
  const AccountsViewCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.postedBalance = const Value.absent(),
    this.availableBalance = const Value.absent(),
    this.lastUpdatedEventId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsViewCompanion.insert({
    required String id,
    required String name,
    required AccountType type,
    required int postedBalance,
    required int availableBalance,
    required int lastUpdatedEventId,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        type = Value(type),
        postedBalance = Value(postedBalance),
        availableBalance = Value(availableBalance),
        lastUpdatedEventId = Value(lastUpdatedEventId);
  static Insertable<AccountViewRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? type,
    Expression<int>? postedBalance,
    Expression<int>? availableBalance,
    Expression<int>? lastUpdatedEventId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (postedBalance != null) 'posted_balance': postedBalance,
      if (availableBalance != null) 'available_balance': availableBalance,
      if (lastUpdatedEventId != null)
        'last_updated_event_id': lastUpdatedEventId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsViewCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<AccountType>? type,
      Value<int>? postedBalance,
      Value<int>? availableBalance,
      Value<int>? lastUpdatedEventId,
      Value<int>? rowid}) {
    return AccountsViewCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      postedBalance: postedBalance ?? this.postedBalance,
      availableBalance: availableBalance ?? this.availableBalance,
      lastUpdatedEventId: lastUpdatedEventId ?? this.lastUpdatedEventId,
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
    if (postedBalance.present) {
      map['posted_balance'] = Variable<int>(postedBalance.value);
    }
    if (availableBalance.present) {
      map['available_balance'] = Variable<int>(availableBalance.value);
    }
    if (lastUpdatedEventId.present) {
      map['last_updated_event_id'] = Variable<int>(lastUpdatedEventId.value);
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
          ..write('postedBalance: $postedBalance, ')
          ..write('availableBalance: $availableBalance, ')
          ..write('lastUpdatedEventId: $lastUpdatedEventId, ')
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
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts_view (id)'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, false,
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
  static const VerificationMeta _originalEventIdMeta =
      const VerificationMeta('originalEventId');
  @override
  late final GeneratedColumn<int> originalEventId = GeneratedColumn<int>(
      'original_event_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        transactionId,
        accountId,
        date,
        amount,
        description,
        categoryId,
        isReversed,
        originalEventId
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
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
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
    if (data.containsKey('is_reversed')) {
      context.handle(
          _isReversedMeta,
          isReversed.isAcceptableOrUnknown(
              data['is_reversed']!, _isReversedMeta));
    }
    if (data.containsKey('original_event_id')) {
      context.handle(
          _originalEventIdMeta,
          originalEventId.isAcceptableOrUnknown(
              data['original_event_id']!, _originalEventIdMeta));
    } else if (isInserting) {
      context.missing(_originalEventIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionViewRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionViewRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      transactionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transaction_id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id'])!,
      isReversed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_reversed'])!,
      originalEventId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}original_event_id'])!,
    );
  }

  @override
  $TransactionsViewTable createAlias(String alias) {
    return $TransactionsViewTable(attachedDatabase, alias);
  }
}

class TransactionViewRow extends DataClass
    implements Insertable<TransactionViewRow> {
  final String id;
  final String transactionId;
  final String accountId;
  final DateTime date;
  final int amount;
  final String description;
  final String categoryId;
  final bool isReversed;
  final int originalEventId;
  const TransactionViewRow(
      {required this.id,
      required this.transactionId,
      required this.accountId,
      required this.date,
      required this.amount,
      required this.description,
      required this.categoryId,
      required this.isReversed,
      required this.originalEventId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['transaction_id'] = Variable<String>(transactionId);
    map['account_id'] = Variable<String>(accountId);
    map['date'] = Variable<DateTime>(date);
    map['amount'] = Variable<int>(amount);
    map['description'] = Variable<String>(description);
    map['category_id'] = Variable<String>(categoryId);
    map['is_reversed'] = Variable<bool>(isReversed);
    map['original_event_id'] = Variable<int>(originalEventId);
    return map;
  }

  TransactionsViewCompanion toCompanion(bool nullToAbsent) {
    return TransactionsViewCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      accountId: Value(accountId),
      date: Value(date),
      amount: Value(amount),
      description: Value(description),
      categoryId: Value(categoryId),
      isReversed: Value(isReversed),
      originalEventId: Value(originalEventId),
    );
  }

  factory TransactionViewRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionViewRow(
      id: serializer.fromJson<String>(json['id']),
      transactionId: serializer.fromJson<String>(json['transactionId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      date: serializer.fromJson<DateTime>(json['date']),
      amount: serializer.fromJson<int>(json['amount']),
      description: serializer.fromJson<String>(json['description']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      isReversed: serializer.fromJson<bool>(json['isReversed']),
      originalEventId: serializer.fromJson<int>(json['originalEventId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transactionId': serializer.toJson<String>(transactionId),
      'accountId': serializer.toJson<String>(accountId),
      'date': serializer.toJson<DateTime>(date),
      'amount': serializer.toJson<int>(amount),
      'description': serializer.toJson<String>(description),
      'categoryId': serializer.toJson<String>(categoryId),
      'isReversed': serializer.toJson<bool>(isReversed),
      'originalEventId': serializer.toJson<int>(originalEventId),
    };
  }

  TransactionViewRow copyWith(
          {String? id,
          String? transactionId,
          String? accountId,
          DateTime? date,
          int? amount,
          String? description,
          String? categoryId,
          bool? isReversed,
          int? originalEventId}) =>
      TransactionViewRow(
        id: id ?? this.id,
        transactionId: transactionId ?? this.transactionId,
        accountId: accountId ?? this.accountId,
        date: date ?? this.date,
        amount: amount ?? this.amount,
        description: description ?? this.description,
        categoryId: categoryId ?? this.categoryId,
        isReversed: isReversed ?? this.isReversed,
        originalEventId: originalEventId ?? this.originalEventId,
      );
  TransactionViewRow copyWithCompanion(TransactionsViewCompanion data) {
    return TransactionViewRow(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      date: data.date.present ? data.date.value : this.date,
      amount: data.amount.present ? data.amount.value : this.amount,
      description:
          data.description.present ? data.description.value : this.description,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      isReversed:
          data.isReversed.present ? data.isReversed.value : this.isReversed,
      originalEventId: data.originalEventId.present
          ? data.originalEventId.value
          : this.originalEventId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionViewRow(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('accountId: $accountId, ')
          ..write('date: $date, ')
          ..write('amount: $amount, ')
          ..write('description: $description, ')
          ..write('categoryId: $categoryId, ')
          ..write('isReversed: $isReversed, ')
          ..write('originalEventId: $originalEventId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, transactionId, accountId, date, amount,
      description, categoryId, isReversed, originalEventId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionViewRow &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.accountId == this.accountId &&
          other.date == this.date &&
          other.amount == this.amount &&
          other.description == this.description &&
          other.categoryId == this.categoryId &&
          other.isReversed == this.isReversed &&
          other.originalEventId == this.originalEventId);
}

class TransactionsViewCompanion extends UpdateCompanion<TransactionViewRow> {
  final Value<String> id;
  final Value<String> transactionId;
  final Value<String> accountId;
  final Value<DateTime> date;
  final Value<int> amount;
  final Value<String> description;
  final Value<String> categoryId;
  final Value<bool> isReversed;
  final Value<int> originalEventId;
  final Value<int> rowid;
  const TransactionsViewCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.date = const Value.absent(),
    this.amount = const Value.absent(),
    this.description = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.isReversed = const Value.absent(),
    this.originalEventId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsViewCompanion.insert({
    required String id,
    required String transactionId,
    required String accountId,
    required DateTime date,
    required int amount,
    required String description,
    required String categoryId,
    this.isReversed = const Value.absent(),
    required int originalEventId,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        transactionId = Value(transactionId),
        accountId = Value(accountId),
        date = Value(date),
        amount = Value(amount),
        description = Value(description),
        categoryId = Value(categoryId),
        originalEventId = Value(originalEventId);
  static Insertable<TransactionViewRow> custom({
    Expression<String>? id,
    Expression<String>? transactionId,
    Expression<String>? accountId,
    Expression<DateTime>? date,
    Expression<int>? amount,
    Expression<String>? description,
    Expression<String>? categoryId,
    Expression<bool>? isReversed,
    Expression<int>? originalEventId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (accountId != null) 'account_id': accountId,
      if (date != null) 'date': date,
      if (amount != null) 'amount': amount,
      if (description != null) 'description': description,
      if (categoryId != null) 'category_id': categoryId,
      if (isReversed != null) 'is_reversed': isReversed,
      if (originalEventId != null) 'original_event_id': originalEventId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsViewCompanion copyWith(
      {Value<String>? id,
      Value<String>? transactionId,
      Value<String>? accountId,
      Value<DateTime>? date,
      Value<int>? amount,
      Value<String>? description,
      Value<String>? categoryId,
      Value<bool>? isReversed,
      Value<int>? originalEventId,
      Value<int>? rowid}) {
    return TransactionsViewCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      accountId: accountId ?? this.accountId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      isReversed: isReversed ?? this.isReversed,
      originalEventId: originalEventId ?? this.originalEventId,
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
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (isReversed.present) {
      map['is_reversed'] = Variable<bool>(isReversed.value);
    }
    if (originalEventId.present) {
      map['original_event_id'] = Variable<int>(originalEventId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsViewCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('accountId: $accountId, ')
          ..write('date: $date, ')
          ..write('amount: $amount, ')
          ..write('description: $description, ')
          ..write('categoryId: $categoryId, ')
          ..write('isReversed: $isReversed, ')
          ..write('originalEventId: $originalEventId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
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
  late final GeneratedColumnWithTypeConverter<TransactionType, int> type =
      GeneratedColumn<int>('type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<TransactionType>($CategoriesTable.$convertertype);
  static const VerificationMeta _isDefaultMeta =
      const VerificationMeta('isDefault');
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
      'is_default', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_default" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _archivedAtMeta =
      const VerificationMeta('archivedAt');
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
      'archived_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isBuildInMeta =
      const VerificationMeta('isBuildIn');
  @override
  late final GeneratedColumn<bool> isBuildIn = GeneratedColumn<bool>(
      'is_build_in', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_build_in" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _systemCodeMeta =
      const VerificationMeta('systemCode');
  @override
  late final GeneratedColumn<String> systemCode = GeneratedColumn<String>(
      'system_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        iconKey,
        colorInt,
        type,
        isDefault,
        isArchived,
        archivedAt,
        isBuildIn,
        systemCode
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<CategoryRow> instance,
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
    if (data.containsKey('is_default')) {
      context.handle(_isDefaultMeta,
          isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('archived_at')) {
      context.handle(
          _archivedAtMeta,
          archivedAt.isAcceptableOrUnknown(
              data['archived_at']!, _archivedAtMeta));
    }
    if (data.containsKey('is_build_in')) {
      context.handle(
          _isBuildInMeta,
          isBuildIn.isAcceptableOrUnknown(
              data['is_build_in']!, _isBuildInMeta));
    }
    if (data.containsKey('system_code')) {
      context.handle(
          _systemCodeMeta,
          systemCode.isAcceptableOrUnknown(
              data['system_code']!, _systemCodeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      iconKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_key'])!,
      colorInt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color_int'])!,
      type: $CategoriesTable.$convertertype.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!),
      isDefault: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_default'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
      archivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}archived_at']),
      isBuildIn: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_build_in'])!,
      systemCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}system_code']),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TransactionType, int, int> $convertertype =
      const EnumIndexConverter<TransactionType>(TransactionType.values);
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final String name;
  final String iconKey;
  final int colorInt;
  final TransactionType type;
  final bool isDefault;
  final bool isArchived;
  final DateTime? archivedAt;
  final bool isBuildIn;
  final String? systemCode;
  const CategoryRow(
      {required this.id,
      required this.name,
      required this.iconKey,
      required this.colorInt,
      required this.type,
      required this.isDefault,
      required this.isArchived,
      this.archivedAt,
      required this.isBuildIn,
      this.systemCode});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['icon_key'] = Variable<String>(iconKey);
    map['color_int'] = Variable<int>(colorInt);
    {
      map['type'] = Variable<int>($CategoriesTable.$convertertype.toSql(type));
    }
    map['is_default'] = Variable<bool>(isDefault);
    map['is_archived'] = Variable<bool>(isArchived);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    map['is_build_in'] = Variable<bool>(isBuildIn);
    if (!nullToAbsent || systemCode != null) {
      map['system_code'] = Variable<String>(systemCode);
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      iconKey: Value(iconKey),
      colorInt: Value(colorInt),
      type: Value(type),
      isDefault: Value(isDefault),
      isArchived: Value(isArchived),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      isBuildIn: Value(isBuildIn),
      systemCode: systemCode == null && nullToAbsent
          ? const Value.absent()
          : Value(systemCode),
    );
  }

  factory CategoryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      iconKey: serializer.fromJson<String>(json['iconKey']),
      colorInt: serializer.fromJson<int>(json['colorInt']),
      type: $CategoriesTable.$convertertype
          .fromJson(serializer.fromJson<int>(json['type'])),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      isBuildIn: serializer.fromJson<bool>(json['isBuildIn']),
      systemCode: serializer.fromJson<String?>(json['systemCode']),
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
      'type':
          serializer.toJson<int>($CategoriesTable.$convertertype.toJson(type)),
      'isDefault': serializer.toJson<bool>(isDefault),
      'isArchived': serializer.toJson<bool>(isArchived),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'isBuildIn': serializer.toJson<bool>(isBuildIn),
      'systemCode': serializer.toJson<String?>(systemCode),
    };
  }

  CategoryRow copyWith(
          {String? id,
          String? name,
          String? iconKey,
          int? colorInt,
          TransactionType? type,
          bool? isDefault,
          bool? isArchived,
          Value<DateTime?> archivedAt = const Value.absent(),
          bool? isBuildIn,
          Value<String?> systemCode = const Value.absent()}) =>
      CategoryRow(
        id: id ?? this.id,
        name: name ?? this.name,
        iconKey: iconKey ?? this.iconKey,
        colorInt: colorInt ?? this.colorInt,
        type: type ?? this.type,
        isDefault: isDefault ?? this.isDefault,
        isArchived: isArchived ?? this.isArchived,
        archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
        isBuildIn: isBuildIn ?? this.isBuildIn,
        systemCode: systemCode.present ? systemCode.value : this.systemCode,
      );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      colorInt: data.colorInt.present ? data.colorInt.value : this.colorInt,
      type: data.type.present ? data.type.value : this.type,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      archivedAt:
          data.archivedAt.present ? data.archivedAt.value : this.archivedAt,
      isBuildIn: data.isBuildIn.present ? data.isBuildIn.value : this.isBuildIn,
      systemCode:
          data.systemCode.present ? data.systemCode.value : this.systemCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorInt: $colorInt, ')
          ..write('type: $type, ')
          ..write('isDefault: $isDefault, ')
          ..write('isArchived: $isArchived, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('isBuildIn: $isBuildIn, ')
          ..write('systemCode: $systemCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, iconKey, colorInt, type, isDefault,
      isArchived, archivedAt, isBuildIn, systemCode);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.iconKey == this.iconKey &&
          other.colorInt == this.colorInt &&
          other.type == this.type &&
          other.isDefault == this.isDefault &&
          other.isArchived == this.isArchived &&
          other.archivedAt == this.archivedAt &&
          other.isBuildIn == this.isBuildIn &&
          other.systemCode == this.systemCode);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> iconKey;
  final Value<int> colorInt;
  final Value<TransactionType> type;
  final Value<bool> isDefault;
  final Value<bool> isArchived;
  final Value<DateTime?> archivedAt;
  final Value<bool> isBuildIn;
  final Value<String?> systemCode;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.colorInt = const Value.absent(),
    this.type = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.isBuildIn = const Value.absent(),
    this.systemCode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    required String iconKey,
    required int colorInt,
    required TransactionType type,
    this.isDefault = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.isBuildIn = const Value.absent(),
    this.systemCode = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        iconKey = Value(iconKey),
        colorInt = Value(colorInt),
        type = Value(type);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? iconKey,
    Expression<int>? colorInt,
    Expression<int>? type,
    Expression<bool>? isDefault,
    Expression<bool>? isArchived,
    Expression<DateTime>? archivedAt,
    Expression<bool>? isBuildIn,
    Expression<String>? systemCode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (iconKey != null) 'icon_key': iconKey,
      if (colorInt != null) 'color_int': colorInt,
      if (type != null) 'type': type,
      if (isDefault != null) 'is_default': isDefault,
      if (isArchived != null) 'is_archived': isArchived,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (isBuildIn != null) 'is_build_in': isBuildIn,
      if (systemCode != null) 'system_code': systemCode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? iconKey,
      Value<int>? colorInt,
      Value<TransactionType>? type,
      Value<bool>? isDefault,
      Value<bool>? isArchived,
      Value<DateTime?>? archivedAt,
      Value<bool>? isBuildIn,
      Value<String?>? systemCode,
      Value<int>? rowid}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorInt: colorInt ?? this.colorInt,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      isBuildIn: isBuildIn ?? this.isBuildIn,
      systemCode: systemCode ?? this.systemCode,
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
          Variable<int>($CategoriesTable.$convertertype.toSql(type.value));
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (isBuildIn.present) {
      map['is_build_in'] = Variable<bool>(isBuildIn.value);
    }
    if (systemCode.present) {
      map['system_code'] = Variable<String>(systemCode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorInt: $colorInt, ')
          ..write('type: $type, ')
          ..write('isDefault: $isDefault, ')
          ..write('isArchived: $isArchived, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('isBuildIn: $isBuildIn, ')
          ..write('systemCode: $systemCode, ')
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
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, false,
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
  late final GeneratedColumnWithTypeConverter<TransactionType, int> type =
      GeneratedColumn<int>('type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<TransactionType>($RecurringSeriesTable.$convertertype);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        rrule,
        startDate,
        endDate,
        frequency,
        interval,
        countLimit,
        amount,
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
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
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
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
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

  static JsonTypeConverter2<TransactionType, int, int> $convertertype =
      const EnumIndexConverter<TransactionType>(TransactionType.values);
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
  final int amount;
  final String description;
  final String categoryId;
  final String accountId;
  final TransactionType type;
  const RecurringSeriesRow(
      {required this.id,
      required this.rrule,
      required this.startDate,
      this.endDate,
      required this.frequency,
      this.interval,
      this.countLimit,
      required this.amount,
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
    map['amount'] = Variable<int>(amount);
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
      amount: Value(amount),
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
      amount: serializer.fromJson<int>(json['amount']),
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
      'amount': serializer.toJson<int>(amount),
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
          int? amount,
          String? description,
          String? categoryId,
          String? accountId,
          TransactionType? type}) =>
      RecurringSeriesRow(
        id: id ?? this.id,
        rrule: rrule ?? this.rrule,
        startDate: startDate ?? this.startDate,
        endDate: endDate.present ? endDate.value : this.endDate,
        frequency: frequency ?? this.frequency,
        interval: interval.present ? interval.value : this.interval,
        countLimit: countLimit.present ? countLimit.value : this.countLimit,
        amount: amount ?? this.amount,
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
      amount: data.amount.present ? data.amount.value : this.amount,
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
          ..write('amount: $amount, ')
          ..write('description: $description, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, rrule, startDate, endDate, frequency,
      interval, countLimit, amount, description, categoryId, accountId, type);
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
          other.amount == this.amount &&
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
  final Value<int> amount;
  final Value<String> description;
  final Value<String> categoryId;
  final Value<String> accountId;
  final Value<TransactionType> type;
  final Value<int> rowid;
  const RecurringSeriesCompanion({
    this.id = const Value.absent(),
    this.rrule = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.frequency = const Value.absent(),
    this.interval = const Value.absent(),
    this.countLimit = const Value.absent(),
    this.amount = const Value.absent(),
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
    required int amount,
    required String description,
    required String categoryId,
    required String accountId,
    required TransactionType type,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        rrule = Value(rrule),
        startDate = Value(startDate),
        frequency = Value(frequency),
        amount = Value(amount),
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
    Expression<int>? amount,
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
      if (amount != null) 'amount': amount,
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
      Value<int>? amount,
      Value<String>? description,
      Value<String>? categoryId,
      Value<String>? accountId,
      Value<TransactionType>? type,
      Value<int>? rowid}) {
    return RecurringSeriesCompanion(
      id: id ?? this.id,
      rrule: rrule ?? this.rrule,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      countLimit: countLimit ?? this.countLimit,
      amount: amount ?? this.amount,
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
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
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
          ..write('amount: $amount, ')
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
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, false,
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
      [id, seriesId, date, amount, status, transactionId];
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
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
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
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
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
  final int amount;
  final String status;
  final String? transactionId;
  const ScheduledTransactionViewRow(
      {required this.id,
      required this.seriesId,
      required this.date,
      required this.amount,
      required this.status,
      this.transactionId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['series_id'] = Variable<String>(seriesId);
    map['date'] = Variable<DateTime>(date);
    map['amount'] = Variable<int>(amount);
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
      amount: Value(amount),
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
      amount: serializer.fromJson<int>(json['amount']),
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
      'amount': serializer.toJson<int>(amount),
      'status': serializer.toJson<String>(status),
      'transactionId': serializer.toJson<String?>(transactionId),
    };
  }

  ScheduledTransactionViewRow copyWith(
          {String? id,
          String? seriesId,
          DateTime? date,
          int? amount,
          String? status,
          Value<String?> transactionId = const Value.absent()}) =>
      ScheduledTransactionViewRow(
        id: id ?? this.id,
        seriesId: seriesId ?? this.seriesId,
        date: date ?? this.date,
        amount: amount ?? this.amount,
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
      amount: data.amount.present ? data.amount.value : this.amount,
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
          ..write('amount: $amount, ')
          ..write('status: $status, ')
          ..write('transactionId: $transactionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, seriesId, date, amount, status, transactionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduledTransactionViewRow &&
          other.id == this.id &&
          other.seriesId == this.seriesId &&
          other.date == this.date &&
          other.amount == this.amount &&
          other.status == this.status &&
          other.transactionId == this.transactionId);
}

class ScheduledTransactionsViewCompanion
    extends UpdateCompanion<ScheduledTransactionViewRow> {
  final Value<String> id;
  final Value<String> seriesId;
  final Value<DateTime> date;
  final Value<int> amount;
  final Value<String> status;
  final Value<String?> transactionId;
  final Value<int> rowid;
  const ScheduledTransactionsViewCompanion({
    this.id = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.date = const Value.absent(),
    this.amount = const Value.absent(),
    this.status = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScheduledTransactionsViewCompanion.insert({
    required String id,
    required String seriesId,
    required DateTime date,
    required int amount,
    required String status,
    this.transactionId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        seriesId = Value(seriesId),
        date = Value(date),
        amount = Value(amount),
        status = Value(status);
  static Insertable<ScheduledTransactionViewRow> custom({
    Expression<String>? id,
    Expression<String>? seriesId,
    Expression<DateTime>? date,
    Expression<int>? amount,
    Expression<String>? status,
    Expression<String>? transactionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seriesId != null) 'series_id': seriesId,
      if (date != null) 'date': date,
      if (amount != null) 'amount': amount,
      if (status != null) 'status': status,
      if (transactionId != null) 'transaction_id': transactionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScheduledTransactionsViewCompanion copyWith(
      {Value<String>? id,
      Value<String>? seriesId,
      Value<DateTime>? date,
      Value<int>? amount,
      Value<String>? status,
      Value<String?>? transactionId,
      Value<int>? rowid}) {
    return ScheduledTransactionsViewCompanion(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
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
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
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
          ..write('amount: $amount, ')
          ..write('status: $status, ')
          ..write('transactionId: $transactionId, ')
          ..write('rowid: $rowid')
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
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $RecurringSeriesTable recurringSeries =
      $RecurringSeriesTable(this);
  late final $ScheduledTransactionsViewTable scheduledTransactionsView =
      $ScheduledTransactionsViewTable(this);
  late final EventsDao eventsDao = EventsDao(this as AppDatabase);
  late final TransactionsDao transactionsDao =
      TransactionsDao(this as AppDatabase);
  late final AccountDao accountDao = AccountDao(this as AppDatabase);
  late final RecurringDao recurringDao = RecurringDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        ledgerEvents,
        accountsView,
        transactionsView,
        categories,
        recurringSeries,
        scheduledTransactionsView
      ];
}

typedef $$LedgerEventsTableCreateCompanionBuilder = LedgerEventsCompanion
    Function({
  Value<int> id,
  required String eventId,
  required String type,
  required DateTime occurredAt,
  required DateTime recordedAt,
  required String payload,
  Value<String?> correlationId,
  Value<String?> metadata,
});
typedef $$LedgerEventsTableUpdateCompanionBuilder = LedgerEventsCompanion
    Function({
  Value<int> id,
  Value<String> eventId,
  Value<String> type,
  Value<DateTime> occurredAt,
  Value<DateTime> recordedAt,
  Value<String> payload,
  Value<String?> correlationId,
  Value<String?> metadata,
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

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get correlationId => $composableBuilder(
      column: $table.correlationId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnFilters(column));
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

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get correlationId => $composableBuilder(
      column: $table.correlationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get correlationId => $composableBuilder(
      column: $table.correlationId, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);
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
            Value<String> type = const Value.absent(),
            Value<DateTime> occurredAt = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<String?> correlationId = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
          }) =>
              LedgerEventsCompanion(
            id: id,
            eventId: eventId,
            type: type,
            occurredAt: occurredAt,
            recordedAt: recordedAt,
            payload: payload,
            correlationId: correlationId,
            metadata: metadata,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String eventId,
            required String type,
            required DateTime occurredAt,
            required DateTime recordedAt,
            required String payload,
            Value<String?> correlationId = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
          }) =>
              LedgerEventsCompanion.insert(
            id: id,
            eventId: eventId,
            type: type,
            occurredAt: occurredAt,
            recordedAt: recordedAt,
            payload: payload,
            correlationId: correlationId,
            metadata: metadata,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
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
  required int postedBalance,
  required int availableBalance,
  required int lastUpdatedEventId,
  Value<int> rowid,
});
typedef $$AccountsViewTableUpdateCompanionBuilder = AccountsViewCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<AccountType> type,
  Value<int> postedBalance,
  Value<int> availableBalance,
  Value<int> lastUpdatedEventId,
  Value<int> rowid,
});

final class $$AccountsViewTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsViewTable, AccountViewRow> {
  $$AccountsViewTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsViewTable, List<TransactionViewRow>>
      _transactionsViewRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactionsView,
              aliasName: $_aliasNameGenerator(
                  db.accountsView.id, db.transactionsView.accountId));

  $$TransactionsViewTableProcessedTableManager get transactionsViewRefs {
    final manager = $$TransactionsViewTableTableManager(
            $_db, $_db.transactionsView)
        .filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_transactionsViewRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

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

  ColumnFilters<int> get postedBalance => $composableBuilder(
      column: $table.postedBalance, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get availableBalance => $composableBuilder(
      column: $table.availableBalance,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastUpdatedEventId => $composableBuilder(
      column: $table.lastUpdatedEventId,
      builder: (column) => ColumnFilters(column));

  Expression<bool> transactionsViewRefs(
      Expression<bool> Function($$TransactionsViewTableFilterComposer f) f) {
    final $$TransactionsViewTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactionsView,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsViewTableFilterComposer(
              $db: $db,
              $table: $db.transactionsView,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
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

  ColumnOrderings<int> get postedBalance => $composableBuilder(
      column: $table.postedBalance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get availableBalance => $composableBuilder(
      column: $table.availableBalance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastUpdatedEventId => $composableBuilder(
      column: $table.lastUpdatedEventId,
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

  GeneratedColumn<int> get postedBalance => $composableBuilder(
      column: $table.postedBalance, builder: (column) => column);

  GeneratedColumn<int> get availableBalance => $composableBuilder(
      column: $table.availableBalance, builder: (column) => column);

  GeneratedColumn<int> get lastUpdatedEventId => $composableBuilder(
      column: $table.lastUpdatedEventId, builder: (column) => column);

  Expression<T> transactionsViewRefs<T extends Object>(
      Expression<T> Function($$TransactionsViewTableAnnotationComposer a) f) {
    final $$TransactionsViewTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactionsView,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsViewTableAnnotationComposer(
              $db: $db,
              $table: $db.transactionsView,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
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
    (AccountViewRow, $$AccountsViewTableReferences),
    AccountViewRow,
    PrefetchHooks Function({bool transactionsViewRefs})> {
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
            Value<int> postedBalance = const Value.absent(),
            Value<int> availableBalance = const Value.absent(),
            Value<int> lastUpdatedEventId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsViewCompanion(
            id: id,
            name: name,
            type: type,
            postedBalance: postedBalance,
            availableBalance: availableBalance,
            lastUpdatedEventId: lastUpdatedEventId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required AccountType type,
            required int postedBalance,
            required int availableBalance,
            required int lastUpdatedEventId,
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsViewCompanion.insert(
            id: id,
            name: name,
            type: type,
            postedBalance: postedBalance,
            availableBalance: availableBalance,
            lastUpdatedEventId: lastUpdatedEventId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AccountsViewTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({transactionsViewRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (transactionsViewRefs) db.transactionsView
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsViewRefs)
                    await $_getPrefetchedData<AccountViewRow,
                            $AccountsViewTable, TransactionViewRow>(
                        currentTable: table,
                        referencedTable: $$AccountsViewTableReferences
                            ._transactionsViewRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsViewTableReferences(db, table, p0)
                                .transactionsViewRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.accountId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
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
    (AccountViewRow, $$AccountsViewTableReferences),
    AccountViewRow,
    PrefetchHooks Function({bool transactionsViewRefs})>;
typedef $$TransactionsViewTableCreateCompanionBuilder
    = TransactionsViewCompanion Function({
  required String id,
  required String transactionId,
  required String accountId,
  required DateTime date,
  required int amount,
  required String description,
  required String categoryId,
  Value<bool> isReversed,
  required int originalEventId,
  Value<int> rowid,
});
typedef $$TransactionsViewTableUpdateCompanionBuilder
    = TransactionsViewCompanion Function({
  Value<String> id,
  Value<String> transactionId,
  Value<String> accountId,
  Value<DateTime> date,
  Value<int> amount,
  Value<String> description,
  Value<String> categoryId,
  Value<bool> isReversed,
  Value<int> originalEventId,
  Value<int> rowid,
});

final class $$TransactionsViewTableReferences extends BaseReferences<
    _$AppDatabase, $TransactionsViewTable, TransactionViewRow> {
  $$TransactionsViewTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $AccountsViewTable _accountIdTable(_$AppDatabase db) =>
      db.accountsView.createAlias($_aliasNameGenerator(
          db.transactionsView.accountId, db.accountsView.id));

  $$AccountsViewTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsViewTableTableManager($_db, $_db.accountsView)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TransactionsViewTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsViewTable> {
  $$TransactionsViewTableFilterComposer({
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

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isReversed => $composableBuilder(
      column: $table.isReversed, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get originalEventId => $composableBuilder(
      column: $table.originalEventId,
      builder: (column) => ColumnFilters(column));

  $$AccountsViewTableFilterComposer get accountId {
    final $$AccountsViewTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accountsView,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsViewTableFilterComposer(
              $db: $db,
              $table: $db.accountsView,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
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
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transactionId => $composableBuilder(
      column: $table.transactionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isReversed => $composableBuilder(
      column: $table.isReversed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get originalEventId => $composableBuilder(
      column: $table.originalEventId,
      builder: (column) => ColumnOrderings(column));

  $$AccountsViewTableOrderingComposer get accountId {
    final $$AccountsViewTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accountsView,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsViewTableOrderingComposer(
              $db: $db,
              $table: $db.accountsView,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
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
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get transactionId => $composableBuilder(
      column: $table.transactionId, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<bool> get isReversed => $composableBuilder(
      column: $table.isReversed, builder: (column) => column);

  GeneratedColumn<int> get originalEventId => $composableBuilder(
      column: $table.originalEventId, builder: (column) => column);

  $$AccountsViewTableAnnotationComposer get accountId {
    final $$AccountsViewTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accountsView,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsViewTableAnnotationComposer(
              $db: $db,
              $table: $db.accountsView,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
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
    (TransactionViewRow, $$TransactionsViewTableReferences),
    TransactionViewRow,
    PrefetchHooks Function({bool accountId})> {
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
            Value<String> id = const Value.absent(),
            Value<String> transactionId = const Value.absent(),
            Value<String> accountId = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<int> amount = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> categoryId = const Value.absent(),
            Value<bool> isReversed = const Value.absent(),
            Value<int> originalEventId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsViewCompanion(
            id: id,
            transactionId: transactionId,
            accountId: accountId,
            date: date,
            amount: amount,
            description: description,
            categoryId: categoryId,
            isReversed: isReversed,
            originalEventId: originalEventId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String transactionId,
            required String accountId,
            required DateTime date,
            required int amount,
            required String description,
            required String categoryId,
            Value<bool> isReversed = const Value.absent(),
            required int originalEventId,
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsViewCompanion.insert(
            id: id,
            transactionId: transactionId,
            accountId: accountId,
            date: date,
            amount: amount,
            description: description,
            categoryId: categoryId,
            isReversed: isReversed,
            originalEventId: originalEventId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TransactionsViewTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
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
                if (accountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.accountId,
                    referencedTable:
                        $$TransactionsViewTableReferences._accountIdTable(db),
                    referencedColumn: $$TransactionsViewTableReferences
                        ._accountIdTable(db)
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

typedef $$TransactionsViewTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransactionsViewTable,
    TransactionViewRow,
    $$TransactionsViewTableFilterComposer,
    $$TransactionsViewTableOrderingComposer,
    $$TransactionsViewTableAnnotationComposer,
    $$TransactionsViewTableCreateCompanionBuilder,
    $$TransactionsViewTableUpdateCompanionBuilder,
    (TransactionViewRow, $$TransactionsViewTableReferences),
    TransactionViewRow,
    PrefetchHooks Function({bool accountId})>;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  required String name,
  required String iconKey,
  required int colorInt,
  required TransactionType type,
  Value<bool> isDefault,
  Value<bool> isArchived,
  Value<DateTime?> archivedAt,
  Value<bool> isBuildIn,
  Value<String?> systemCode,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> iconKey,
  Value<int> colorInt,
  Value<TransactionType> type,
  Value<bool> isDefault,
  Value<bool> isArchived,
  Value<DateTime?> archivedAt,
  Value<bool> isBuildIn,
  Value<String?> systemCode,
  Value<int> rowid,
});

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
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

  ColumnWithTypeConverterFilters<TransactionType, TransactionType, int>
      get type => $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isBuildIn => $composableBuilder(
      column: $table.isBuildIn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get systemCode => $composableBuilder(
      column: $table.systemCode, builder: (column) => ColumnFilters(column));
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
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

  ColumnOrderings<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isBuildIn => $composableBuilder(
      column: $table.isBuildIn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get systemCode => $composableBuilder(
      column: $table.systemCode, builder: (column) => ColumnOrderings(column));
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
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

  GeneratedColumnWithTypeConverter<TransactionType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => column);

  GeneratedColumn<bool> get isBuildIn =>
      $composableBuilder(column: $table.isBuildIn, builder: (column) => column);

  GeneratedColumn<String> get systemCode => $composableBuilder(
      column: $table.systemCode, builder: (column) => column);
}

class $$CategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTable,
    CategoryRow,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (CategoryRow, BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>),
    CategoryRow,
    PrefetchHooks Function()> {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> iconKey = const Value.absent(),
            Value<int> colorInt = const Value.absent(),
            Value<TransactionType> type = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<DateTime?> archivedAt = const Value.absent(),
            Value<bool> isBuildIn = const Value.absent(),
            Value<String?> systemCode = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion(
            id: id,
            name: name,
            iconKey: iconKey,
            colorInt: colorInt,
            type: type,
            isDefault: isDefault,
            isArchived: isArchived,
            archivedAt: archivedAt,
            isBuildIn: isBuildIn,
            systemCode: systemCode,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String iconKey,
            required int colorInt,
            required TransactionType type,
            Value<bool> isDefault = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<DateTime?> archivedAt = const Value.absent(),
            Value<bool> isBuildIn = const Value.absent(),
            Value<String?> systemCode = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            id: id,
            name: name,
            iconKey: iconKey,
            colorInt: colorInt,
            type: type,
            isDefault: isDefault,
            isArchived: isArchived,
            archivedAt: archivedAt,
            isBuildIn: isBuildIn,
            systemCode: systemCode,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesTable,
    CategoryRow,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (CategoryRow, BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>),
    CategoryRow,
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
  required int amount,
  required String description,
  required String categoryId,
  required String accountId,
  required TransactionType type,
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
  Value<int> amount,
  Value<String> description,
  Value<String> categoryId,
  Value<String> accountId,
  Value<TransactionType> type,
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
          aliasName: $_aliasNameGenerator(
              db.recurringSeries.id, db.scheduledTransactionsView.seriesId));

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

  ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<TransactionType, TransactionType, int>
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

  ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TransactionType, int> get type =>
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
            Value<int> amount = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> categoryId = const Value.absent(),
            Value<String> accountId = const Value.absent(),
            Value<TransactionType> type = const Value.absent(),
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
            amount: amount,
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
            required int amount,
            required String description,
            required String categoryId,
            required String accountId,
            required TransactionType type,
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
            amount: amount,
            description: description,
            categoryId: categoryId,
            accountId: accountId,
            type: type,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
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
  required int amount,
  required String status,
  Value<String?> transactionId,
  Value<int> rowid,
});
typedef $$ScheduledTransactionsViewTableUpdateCompanionBuilder
    = ScheduledTransactionsViewCompanion Function({
  Value<String> id,
  Value<String> seriesId,
  Value<DateTime> date,
  Value<int> amount,
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
      db.recurringSeries.createAlias($_aliasNameGenerator(
          db.scheduledTransactionsView.seriesId, db.recurringSeries.id));

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

  ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

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
            Value<int> amount = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> transactionId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ScheduledTransactionsViewCompanion(
            id: id,
            seriesId: seriesId,
            date: date,
            amount: amount,
            status: status,
            transactionId: transactionId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String seriesId,
            required DateTime date,
            required int amount,
            required String status,
            Value<String?> transactionId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ScheduledTransactionsViewCompanion.insert(
            id: id,
            seriesId: seriesId,
            date: date,
            amount: amount,
            status: status,
            transactionId: transactionId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LedgerEventsTableTableManager get ledgerEvents =>
      $$LedgerEventsTableTableManager(_db, _db.ledgerEvents);
  $$AccountsViewTableTableManager get accountsView =>
      $$AccountsViewTableTableManager(_db, _db.accountsView);
  $$TransactionsViewTableTableManager get transactionsView =>
      $$TransactionsViewTableTableManager(_db, _db.transactionsView);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$RecurringSeriesTableTableManager get recurringSeries =>
      $$RecurringSeriesTableTableManager(_db, _db.recurringSeries);
  $$ScheduledTransactionsViewTableTableManager get scheduledTransactionsView =>
      $$ScheduledTransactionsViewTableTableManager(
          _db, _db.scheduledTransactionsView);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appDatabaseHash() => r'8c69eb46d45206533c176c88a926608e79ca927d';

/// See also [appDatabase].
@ProviderFor(appDatabase)
final appDatabaseProvider = Provider<AppDatabase>.internal(
  appDatabase,
  name: r'appDatabaseProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appDatabaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppDatabaseRef = ProviderRef<AppDatabase>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
