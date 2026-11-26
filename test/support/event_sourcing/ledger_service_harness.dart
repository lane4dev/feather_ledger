import 'package:drift/drift.dart';

import 'package:feather_ledger/app/bootstrap/register_ledger_events.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/repositories/account_repository.dart';
import 'package:feather_ledger/core/data/repositories/category_repository.dart';
import 'package:feather_ledger/core/domain/repositories/preferences_repository.dart'
    as prefs_api;
import 'package:feather_ledger/app/theme/category_tokens.dart';
import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/constants/category_constants.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_store.dart';
import 'package:feather_ledger/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:feather_ledger/features/budget/domain/commands/clear_category_budget_command.dart';
import 'package:feather_ledger/features/budget/domain/commands/save_review_note_command.dart';
import 'package:feather_ledger/features/budget/domain/commands/set_category_budget_command.dart';
import 'package:feather_ledger/features/budget/domain/queries/watch_month_budget_query.dart';
import 'package:feather_ledger/features/budget/domain/queries/watch_transaction_budget_hint_query.dart';
import 'package:feather_ledger/features/budget/domain/services/budget_service.dart';
import 'package:feather_ledger/features/ledger/data/event_sourcing/drift_event_store.dart';
import 'package:feather_ledger/features/ledger/data/projections/ledger_projector.dart';
import 'package:feather_ledger/features/ledger/data/repositories/ledger_repository.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';
import 'package:feather_ledger/features/ledger/domain/commands/convert_scheduled_to_posted_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/correct_transaction_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/create_recurring_series_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/delete_recurring_bill_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/project_recurring_events_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/record_transaction_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/restore_skipped_bill_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/update_recurring_bill_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/reverse_transaction_command.dart';
import 'package:feather_ledger/features/ledger/domain/queries/get_account_balance_query.dart';
import 'package:feather_ledger/features/ledger/domain/queries/get_scheduled_transaction_query.dart';
import 'package:feather_ledger/features/ledger/domain/queries/watch_monthly_snapshot_query.dart';
import 'package:feather_ledger/features/ledger/domain/queries/watch_scheduled_transactions_query.dart';
import 'package:feather_ledger/features/ledger/domain/queries/watch_transactions_query.dart';
import 'package:feather_ledger/features/ledger/domain/services/ledger_service.dart';
import 'package:feather_ledger/features/ledger/domain/services/posting_context.dart';
import 'package:feather_ledger/features/ledger/domain/services/recurring_service.dart';
import 'package:feather_ledger/features/ledger/domain/projections/ledger_projection.dart';
import 'package:feather_ledger/features/settings/domain/commands/account_lifecycle_command.dart';
import 'package:feather_ledger/features/settings/domain/commands/set_account_totals_inclusion_command.dart';
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
  final DomainClock clock;

  /// The spec EventStore (US2/T020) — every command appends through it.
  late final EventStore eventStore;

  /// The synchronous ledger projector (US3/T026).
  late final LedgerProjector projector;
  late final AccountRepository accountRepository;
  late final CategoryRepository categoryRepository;
  late final LedgerRepository ledgerRepository;
  late final RecurringRepository recurringRepository;
  late final BudgetRepository budgetRepository;

  /// The write/read seam every migration logic test goes through.
  late final LedgerService ledgerService;

  /// Recurring bills live here (spec 004, US2) — `recurring_series` and
  /// `scheduled_transactions_view` are CRUD-exempt, and this is the only
  /// service that reaches them and the event store in one action.
  late final RecurringService recurringService;

  /// Real budget service backed by the same in-memory [db] and [clock].
  late final BudgetService budgetService;

  late final AccountService accountService;
  late final CategoryService categoryService;

  /// Ticket 28 safety gate: auto-posting is disabled by default and only
  /// opened under a controlled test configuration.
  final bool autoPostEnabled;

  /// The per-mode auto-post switches and eligibility boundaries (ticket 31).
  /// Null means every switch is off, which is what most tests want.
  final prefs_api.PreferencesRepository? preferences;

  LedgerServiceHarness({
    this.autoPostEnabled = false,
    this.preferences,
    DomainClock? clock,
  })  : clock = clock ?? const SystemClock(),
        db = FakeAppDatabase() {
    // Production registration — no test-only factory setup (US2/T021).
    registerLedgerEvents();
    eventStore = DriftEventStore(db, ledgerEventRegistry);
    projector = LedgerProjectorImpl(db);

    accountRepository = AccountRepositoryImpl(db.accountDao);
    categoryRepository = CategoryRepositoryImpl(db.categoriesDao);
    ledgerRepository =
        LedgerRepositoryImpl(db.transactionsDao, db.recurringDao);
    recurringRepository = RecurringRepositoryImpl(
        db.recurringDao, db.categoriesDao, db.accountDao);
    budgetRepository = BudgetRepositoryImpl(db.budgetDao, db.categoriesDao);

    final contextResolver =
        PostingContextResolver(accountRepository, categoryRepository);
    final recordCommand =
        RecordTransactionCommand(eventStore, projector, contextResolver);
    recurringService = RecurringService(
      CreateRecurringSeriesCommand(recurringRepository, contextResolver),
      DeleteRecurringBillCommand(recurringRepository),
      UpdateRecurringBillCommand(
        recurringRepository,
        contextResolver,
        clock: this.clock,
      ),
      ConvertScheduledToPostedCommand(
          eventStore, projector, recurringRepository, contextResolver),
      ProjectRecurringEventsCommand(
        recurringRepository,
        clock: this.clock,
      ),
      WatchScheduledTransactionsQuery(recurringRepository),
      GetScheduledTransactionQuery(recurringRepository),
      recurringRepository,
      restoreSkipped: RestoreSkippedBillCommand(
        recurringRepository,
        clock: this.clock,
      ),
      preferences: preferences,
      clock: this.clock,
    );
    budgetService = BudgetService(
      SetCategoryBudgetCommand(budgetRepository, clock: this.clock),
      ClearCategoryBudgetCommand(budgetRepository, clock: this.clock),
      SaveReviewNoteCommand(budgetRepository, clock: this.clock),
      WatchMonthBudgetQuery(budgetRepository, clock: this.clock),
      WatchTransactionBudgetHintQuery(budgetRepository, clock: this.clock),
      budgetRepository,
    );
    ledgerService = LedgerService(
      recordCommand,
      ReverseTransactionCommand(eventStore, projector, ledgerRepository),
      CorrectTransactionCommand(
          eventStore, projector, ledgerRepository, contextResolver),
      recurringService,
      WatchTransactionsQuery(ledgerRepository),
      WatchMonthlySnapshotQuery(db.monthlySnapshotDao, db.accountDao),
      GetAccountBalanceQuery(accountRepository),
    );

    accountService = AccountService(
      CreateAccountCommand(eventStore, projector),
      RenameAccountCommand(eventStore, projector),
      AccountLifecycleCommand(db, eventStore, projector, clock: this.clock),
      WatchAllAccountsQuery(accountRepository),
      GetAccountByIdQuery(accountRepository),
      recordCommand,
      SetAccountTotalsInclusionCommand(eventStore, projector),
      recurringService,
    );

    categoryService = CategoryService(
      CreateCategoryCommand(eventStore, projector),
      RenameCategoryCommand(eventStore, projector),
      ArchiveCategoryCommand(eventStore, projector, categoryRepository),
      categoryRepository,
    );
  }

  /// Seeds the two system categories a balance correction is filed under.
  ///
  /// Production gets them from `seedDatabase` at bootstrap; a harness-built
  /// ledger starts empty, so a test that opens an account with a starting
  /// balance — or adjusts one afterwards — asks for them here. Appearance
  /// mirrors the seed so a rendered fixture looks like production.
  Future<void> seedSystemCategories() async {
    await categoryService.createCategory(
      commandId: 'seed-category-reversal-expense',
      categoryId: CategoryConstants.reversalExpenseId,
      name: 'Balance correction',
      iconKey: '${CategoryTokens.defaultIcons[30]}',
      colorInt: CategoryTokens.defaultColors[16].toARGB32(),
      type: CategoryType.expense,
      systemCode: CategoryConstants.reversalExpenseCode,
    );
    await categoryService.createCategory(
      commandId: 'seed-category-reversal-income',
      categoryId: CategoryConstants.reversalIncomeId,
      name: 'Balance correction',
      iconKey: '${CategoryTokens.defaultIcons[31]}',
      colorInt: CategoryTokens.defaultColors[17].toARGB32(),
      type: CategoryType.income,
      systemCode: CategoryConstants.reversalIncomeCode,
    );
  }

  /// The category a fixture created — the system categories
  /// [seedSystemCategories] adds are not it, so this stays the obvious
  /// `.single` even now that the table is never otherwise empty.
  Future<String> userCategoryId() async =>
      (await db.categoriesDao.getAllCategories())
          .firstWhere((c) => c.systemCode == null)
          .id;

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
