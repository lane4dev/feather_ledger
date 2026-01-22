import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/preferences_repository.dart';

part 'currency_provider.g.dart';

@riverpod
class CurrencyController extends _$CurrencyController {
  @override
  Future<String> build() async {
    final repo = await ref.watch(preferencesRepositoryProvider.future);
    return repo.getCurrency();
  }

  Future<void> setCurrency(String symbol) async {
    final repo = await ref.read(preferencesRepositoryProvider.future);
    await repo.setCurrency(symbol);
    state = AsyncData(symbol);
  }
}
