import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/data/repositories/account_repository.dart';
import 'package:feather_ledger/core/data/repositories/category_repository.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';

part 'posting_context.g.dart';

/// The facts about other things a posting needs before it can exist
/// (ADR-0002): the account it moves money on, the category it files under,
/// and — for a transfer — the counter-account.
class PostingContext {
  final AccountEntity account;

  /// Credit-side account; set only for a transfer.
  final AccountEntity? counterAccount;

  /// Set for income/expense; null for a transfer, which carries none.
  final CategoryEntity? category;

  const PostingContext({
    required this.account,
    this.counterAccount,
    this.category,
  });
}

/// Resolves that context, rejecting the write with a presentable
/// [LedgerErrorCode] when a referenced account or category is missing,
/// archived, or of a kind that does not match the transaction.
///
/// One seam for all three writers of `TransactionRecorded` (ADR-0002). These
/// checks used to be re-typed in every command, and the third writer had
/// already drifted — it never checked the category kind at all. The rules
/// cannot live in the aggregate, because they need a repository lookup;
/// they cannot live in the event store, because that would turn a deep
/// persistence module into an orchestration point.
///
/// It returns the entities rather than a verdict so the caller does not look
/// them up twice for facts the posting needs anyway (account currency,
/// category id).
class PostingContextResolver {
  final AccountRepository _accounts;
  final CategoryRepository _categories;

  PostingContextResolver(this._accounts, this._categories);

  /// Income or expense: a live account and a live category whose kind
  /// matches [kind].
  Future<PostingContext> resolveForKind({
    required String accountId,
    required String categoryId,
    required TransactionKind kind,
  }) async {
    if (!kind.requiresCategory) {
      throw const CommandRejected(LedgerErrorCode.invalidTransactionShape,
          'only income and expense resolve through resolveForKind');
    }
    final account = await _requireLiveAccount(accountId);
    final category = await _requireLiveCategory(categoryId);

    final expected = kind == TransactionKind.income
        ? CategoryType.income
        : CategoryType.expense;
    if (category.type != expected) {
      throw CommandRejected(
          LedgerErrorCode.categoryTypeMismatch,
          'Category $categoryId is ${category.type.name}, expected '
          '${expected.name}');
    }
    return PostingContext(account: account, category: category);
  }

  /// Transfer: two live accounts. Distinctness and single-currency are
  /// *shape* rules and stay in the aggregate — [Transaction.validate]
  /// rejects them from the built postings.
  Future<PostingContext> resolveForTransfer({
    required String fromAccountId,
    required String toAccountId,
  }) async {
    final from = await _requireLiveAccount(fromAccountId);
    final to = await _requireLiveAccount(toAccountId);
    return PostingContext(account: from, counterAccount: to);
  }

  /// Opening balances and reconciliation adjustments move one live account
  /// and deliberately have neither a category nor a counter-account.
  Future<PostingContext> resolveForBalancePurpose({
    required String accountId,
  }) async =>
      PostingContext(account: await _requireLiveAccount(accountId));

  Future<AccountEntity> _requireLiveAccount(String id) async {
    final account = await _accounts.getAccount(id);
    if (account == null) {
      throw CommandRejected(
          LedgerErrorCode.accountNotFound, 'Account $id not found');
    }
    if (account.archived) {
      throw CommandRejected(
          LedgerErrorCode.accountArchived, 'Account $id is archived');
    }
    return account;
  }

  Future<CategoryEntity> _requireLiveCategory(String id) async {
    final category = await _categories.getCategory(id);
    if (category == null) {
      throw CommandRejected(
          LedgerErrorCode.categoryNotFound, 'Category $id not found');
    }
    if (category.archived) {
      throw CommandRejected(
          LedgerErrorCode.categoryArchived, 'Category $id is archived');
    }
    return category;
  }
}

@riverpod
PostingContextResolver postingContextResolver(Ref ref) {
  return PostingContextResolver(
    ref.watch(accountRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
  );
}
