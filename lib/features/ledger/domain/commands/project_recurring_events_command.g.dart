// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_recurring_events_command.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(projectRecurringEventsCommand)
final projectRecurringEventsCommandProvider =
    ProjectRecurringEventsCommandProvider._();

final class ProjectRecurringEventsCommandProvider extends $FunctionalProvider<
        ProjectRecurringEventsCommand,
        ProjectRecurringEventsCommand,
        ProjectRecurringEventsCommand>
    with $Provider<ProjectRecurringEventsCommand> {
  ProjectRecurringEventsCommandProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'projectRecurringEventsCommandProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$projectRecurringEventsCommandHash();

  @$internal
  @override
  $ProviderElement<ProjectRecurringEventsCommand> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ProjectRecurringEventsCommand create(Ref ref) {
    return projectRecurringEventsCommand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProjectRecurringEventsCommand value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<ProjectRecurringEventsCommand>(value),
    );
  }
}

String _$projectRecurringEventsCommandHash() =>
    r'1fd85de7daaa2e9bd3740de5d904a2c86adda6be';
