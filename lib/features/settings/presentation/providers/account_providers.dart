import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:feather_ledger/features/settings/data/repositories/account_repository.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';

part 'account_providers.g.dart';

@riverpod
Stream<List<AccountEntity>> accountList(Ref ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.watchAccounts();
}
