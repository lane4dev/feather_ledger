// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_manifest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BackupManifest _$BackupManifestFromJson(Map<String, dynamic> json) =>
    BackupManifest(
      format: json['format'] as String? ?? BackupManifest.formatName,
      formatVersion: (json['formatVersion'] as num?)?.toInt() ??
          BackupManifest.currentFormatVersion,
      schemaVersion: (json['schemaVersion'] as num).toInt(),
      appVersion: json['appVersion'] as String,
      exportedAt: DateTime.parse(json['exportedAt'] as String),
      databaseBytes: (json['databaseBytes'] as num).toInt(),
      preferenceKeys: (json['preferenceKeys'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      eventCount: (json['eventCount'] as num).toInt(),
      lastGlobalSequenceNumber:
          (json['lastGlobalSequenceNumber'] as num).toInt(),
      seriesCount: (json['seriesCount'] as num).toInt(),
    );

Map<String, dynamic> _$BackupManifestToJson(BackupManifest instance) =>
    <String, dynamic>{
      'format': instance.format,
      'formatVersion': instance.formatVersion,
      'schemaVersion': instance.schemaVersion,
      'appVersion': instance.appVersion,
      'exportedAt': instance.exportedAt.toIso8601String(),
      'databaseBytes': instance.databaseBytes,
      'preferenceKeys': instance.preferenceKeys,
      'eventCount': instance.eventCount,
      'lastGlobalSequenceNumber': instance.lastGlobalSequenceNumber,
      'seriesCount': instance.seriesCount,
    };
