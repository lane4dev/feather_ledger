import 'package:json_annotation/json_annotation.dart';

part 'backup_manifest.g.dart';

/// Raised when a file is not a backup this app can restore (spec 004, US4).
///
/// Covers three distinct refusals: not our format at all, a container version
/// we are too old to read, and a manifest missing fields it must have.
class BackupFormatException implements Exception {
  final String message;

  const BackupFormatException(this.message);

  @override
  String toString() => 'BackupFormatException: $message';
}

/// What a `.flbackup` archive says about itself.
///
/// [formatVersion] and [schemaVersion] answer different questions and both are
/// checked on restore: the first is the *container's* version (did the archive
/// layout change?), the second is the *database's* (can this build open the
/// database inside?). A v1 app must refuse a v2 container; a future
/// schemaVersion must be refused separately.
///
/// [eventCount] and [lastGlobalSequenceNumber] are not decoration — they are
/// what lets the restore dialog state how much data a replacement discards.
@JsonSerializable()
class BackupManifest {
  /// Identifies the archive as ours; a foreign zip must be refused outright.
  static const formatName = 'feather-ledger-backup';

  /// Bump when the archive *layout* changes, not the database schema.
  static const currentFormatVersion = 1;

  final String format;
  final int formatVersion;
  final int schemaVersion;
  final String appVersion;
  final DateTime exportedAt;
  final int databaseBytes;
  final List<String> preferenceKeys;
  final int eventCount;
  final int lastGlobalSequenceNumber;
  final int seriesCount;

  // Qualified with the class name because json_serializable re-emits these
  // default expressions into the generated file, where a bare `formatName`
  // would not resolve.
  const BackupManifest({
    this.format = BackupManifest.formatName,
    this.formatVersion = BackupManifest.currentFormatVersion,
    required this.schemaVersion,
    required this.appVersion,
    required this.exportedAt,
    required this.databaseBytes,
    required this.preferenceKeys,
    required this.eventCount,
    required this.lastGlobalSequenceNumber,
    required this.seriesCount,
  });

  /// Parses and validates a manifest, refusing anything this build cannot
  /// restore.
  factory BackupManifest.fromJson(Map<String, dynamic> json) {
    final format = json['format'];
    if (format != formatName) {
      throw BackupFormatException(
          'Not a Feather Ledger backup (format: $format)');
    }

    final version = json['formatVersion'];
    if (version is! int) {
      throw const BackupFormatException('Backup has no format version');
    }
    if (version > currentFormatVersion) {
      throw BackupFormatException(
          'Backup format v$version is newer than this app understands '
          '(v$currentFormatVersion). Update the app and try again.');
    }

    try {
      return _$BackupManifestFromJson(json);
    } catch (e) {
      throw BackupFormatException('Backup manifest is incomplete: $e');
    }
  }

  Map<String, dynamic> toJson() => _$BackupManifestToJson(this);
}
