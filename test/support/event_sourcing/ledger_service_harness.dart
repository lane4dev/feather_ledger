import 'package:drift/drift.dart';

import 'package:feather_ledger/app/bootstrap/register_ledger_events.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/repositories/account_repository.dart';
import 'package:feather_ledger/core/data/repositories/category_repository.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_store.dart';
import 'package:feather_ledger/features/ledger/data/event_sourcing/drift_event_store.dart';
import 'package:feather_ledger/features/ledger/data/projections/ledger_projector.dart';
import 'package:feather_ledger/features/ledger/data/repositories/ledger_repository.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';
import 'package:feather_ledger/features/ledger/domain/commands/convert_scheduled_to_posted_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/correct_transaction_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/record_transaction_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/reverse_transaction_command.dart';
import 'package:feather_ledger/features/ledger/domain/queries/get_account_balance_query.dart';
import 'package:feather_ledger/features/ledger/domain/queries/watch_monthly_snapshot_query.dart';
import 'package:feather_ledger/features/ledger/domain/queries/watch_scheduled_transactions_query.dart';
import 'package:feather_ledger/features/ledger/domain/queries/watch_transactions_query.dart';
import 'package:feather_ledger/features/ledger/domain/services/ledger_service.dart';
import 'package:feather_ledger/features/ledger/domain/projections/ledger_projection.dart';
import 'package:feather_ledger/features/settings/domain/commands/archive_account_command.dart';
import 'package:feather_ledger/features/settings/domain/commands/create_account_command.dart';
import 'package:feather_ledger/features/settings/domain/commands/rename_account_command.dart';
import 'package:feather_ledger/features/settings/domain/commands/archive_category_command.dart';
import 'package:feather_ledger/features/settings/domain/commands/create_category_command.dart';
import 'package:feather_ledger/features/settings/domain/commands/rename_category_command.dart';
import 'package:feather_ledger/features/settings/domain/queries/get_account_by_id_query.dart';
import 'package:feather_ledger/features/settings/domain/queries/watch_all_accounts_query.dart';
import 'package:feather_ledger/features/settings/domain/services/account_service.dart';
import 'package:feather_ledger/features/settings/domain/services/category_service.dart';

import '../fakes/fake_app_database.dart';

/// Shared in-memory Drift harness for the 003 event-sourcing migration
/// (specs/003-event-sourced-ledger/tasks.md T002).
///
/// Migration risk regression tests drive the domain services
/// ([LedgerService] / [AccountService] / [CategoryService]) against this
/// harness and assert on the externally observable outputs only: the event
/// stream (`eventStore`), the projection tables and — once Phase 7 lands —
/// the monthly snapshots. Do not mock commands, the projector or the Event
/// Store; the services are the single test seam.
///
/// ```dart
/// late LedgerServiceHarness harness;
/// setUp(() => harness = LedgerServiceHarness());
/// tearDown(() => harness.close());
/// ```
class LedgerServiceHarness {
  final FakeAppDatabase db;

  /// The spec EventStore (US2/T020) — every command appends through it.
  late final EventStore eventStore;

  /// The synchronous ledger projector (US3/T026).
  late final LedgerProjector projector;
  late final AccountRepository accountRepository;
  late final CategoryRepository categoryRepository;
  late final LedgerRepository ledgerRepository;
  late final RecurringRepository recurringRepository;

  /// The write/read seam every migration logic test goes through.
  late final LedgerService ledgerService;
  late final AccountService accountService;
  late final CategoryService categoryService;

  LedgerServiceHarness() : db = FakeAppDatabase() {
    // Production registration — no test-only factory setup (US2/T021).
    registerLedgerEvents();
    eventStore = DriftEventStore(db, ledgerEventRegistry);
    projector = LedgerProjectorImpl(db);

    accountRepository = AccountRepositoryImpl(db.accountDao);
    categoryRepository = CategoryRepositoryImpl(db.categoriesDao);
    ledgerRepository =
        LedgerRepositoryImpl(db.transactionsDao, db.recurringDao);
    recurringRepository = RecurringRepositoryImpl(db.recurringDao);

    final recordCommand = RecordTransactionCommand(
        eventStore, projector, accountRepository, categoryRepository);
    ledgerService = LedgerService(
      recordCommand,
      ReverseTransactionCommand(eventStore, projector, ledgerRepository),
      CorrectTransactionCommand(eventStore, projector, ledgerRepository,
          accountRepository, categoryRepository),
      ConvertScheduledToPostedCommand(eventStore, projector,
          recurringRepository, accountRepository, categoryRepository),
      WatchTransactionsQuery(ledgerRepository),
      WatchMonthlySnapshotQuery(db.monthlySnapshotDao, db.accountDao),
      GetAccountBalanceQuery(accountRepository),
      WatchScheduledTransactionsQuery(recurringRepository),
    );

    accountService = AccountService(
      CreateAccountCommand(eventStore, projector),
      RenameAccountCommand(eventStore, projector),
      ArchiveAccountCommand(eventStore, projector),
      WatchAllAccountsQuery(accountRepository),
      GetAccountByIdQuery(accountRepository),
      recordCommand,
      categoryRepository,
    );

    categoryService = CategoryService(
      CreateCategoryCommand(eventStore, projector),
      RenameCategoryCommand(eventStore, projector),
      ArchiveCategoryCommand(eventStore, projector, categoryRepository),
      categoryRepository,
    );
  }

  /// Seeds an account through the standard write path (US3/T030-style).
  Future<void> seedAccount({
    required String id,
    required String name,
    AccountType type = AccountType.cash,
    int balanceMinor = 0,
    String currencyCode = 'USD',
  }) =>
      db.into(db.accountsView).insert(
            AccountsViewCompanion.insert(
              id: id,
              name: name,
              type: type,
              currencyCode: currencyCode,
              balanceMinor: balanceMinor,
              lastUpdatedEventId: 0,
            ),
          );

  /// Seeds a category projection row directly (pre-US3 style fixture for
  /// legacy-path tests; writes are event-sourced in production).
  Future<void> seedCategory({
    required String id,
    required String name,
    CategoryType type = CategoryType.expense,
    String? systemCode,
  }) =>
      db.into(db.categoriesView).insert(
            CategoriesViewCompanion.insert(
              id: id,
              name: name,
              iconKey: 'icon_$id',
              colorInt: 0xFF000000,
              type: type,
              systemCode: Value(systemCode),
              lastUpdatedEventId: 0,
            ),
          );

  Future<void> close() => db.close();
}
