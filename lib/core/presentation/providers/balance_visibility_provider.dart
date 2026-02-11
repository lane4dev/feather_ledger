import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/preferences_repository.dart';

part 'balance_visibility_provider.g.dart';

@riverpod
class BalanceVisibilityController extends _$BalanceVisibilityController {
  @override
  Future<bool> build() async {
    final repo = await ref.watch(preferencesRepositoryProvider.future);
    return repo.getShowBalance();
  }

  Future<void> setVisibility(bool show) async {
    final repo = await ref.read(preferencesRepositoryProvider.future);
    await repo.setShowBalance(show);
    state = AsyncData(show);
  }

  Future<void> toggle() async {
    final current = state.valueOrNull ?? true;
    await setVisibility(!current);
  }
}
