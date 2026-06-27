// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Recurring bills (spec 004, US2).
///
/// Shapes follow [LedgerViewModel]: keep-alive, one subscription per stream,
/// disposed together, and every write routed through the service so the
/// screen never touches a command.

@ProviderFor(RecurringViewModel)
final recurringViewModelProvider = RecurringViewModelProvider._();

/// Recurring bills (spec 004, US2).
///
/// Shapes follow [LedgerViewModel]: keep-alive, one subscription per stream,
/// disposed together, and every write routed through the service so the
/// screen never touches a command.
final class RecurringViewModelProvider
    extends $NotifierProvider<RecurringViewModel, RecurringViewState> {
  /// Recurring bills (spec 004, US2).
  ///
  /// Shapes follow [LedgerViewModel]: keep-alive, one subscription per stream,
  /// disposed together, and every write routed through the service so the
  /// screen never touches a command.
  RecurringViewModelProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'recurringViewModelProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$recurringViewModelHash();

  @$internal
  @override
  RecurringViewModel create() => RecurringViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecurringViewState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecurringViewState>(value),
    );
  }
}

String _$recurringViewModelHash() =>
    r'2e83804df7dfe95781ac945f64e1a3297caf742f';

/// Recurring bills (spec 004, US2).
///
/// Shapes follow [LedgerViewModel]: keep-alive, one subscription per stream,
/// disposed together, and every write routed through the service so the
/// screen never touches a command.

abstract class _$RecurringViewModel extends $Notifier<RecurringViewState> {
  RecurringViewState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RecurringViewState, RecurringViewState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<RecurringViewState, RecurringViewState>,
        RecurringViewState,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
