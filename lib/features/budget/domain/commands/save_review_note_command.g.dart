// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_review_note_command.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(saveReviewNoteCommand)
final saveReviewNoteCommandProvider = SaveReviewNoteCommandProvider._();

final class SaveReviewNoteCommandProvider extends $FunctionalProvider<
    SaveReviewNoteCommand,
    SaveReviewNoteCommand,
    SaveReviewNoteCommand> with $Provider<SaveReviewNoteCommand> {
  SaveReviewNoteCommandProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'saveReviewNoteCommandProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$saveReviewNoteCommandHash();

  @$internal
  @override
  $ProviderElement<SaveReviewNoteCommand> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SaveReviewNoteCommand create(Ref ref) {
    return saveReviewNoteCommand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SaveReviewNoteCommand value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SaveReviewNoteCommand>(value),
    );
  }
}

String _$saveReviewNoteCommandHash() =>
    r'fa4dba801a95a6656daa26a4d3a3e931dec6f772';
