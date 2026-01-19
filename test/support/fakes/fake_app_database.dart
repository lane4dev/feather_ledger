import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:feather_ledger/core/database/app_database.dart';

/// A fake AppDatabase for testing purposes that uses an in-memory database.
/// This allows tests to run without affecting the real database and without
/// requiring any test-specific code in the production AppDatabase class.
class FakeAppDatabase extends AppDatabase {
  FakeAppDatabase() : super.internal(NativeDatabase.memory());

  /// Creates a fake database with a custom executor.
  /// Useful for more advanced testing scenarios.
  FakeAppDatabase.withExecutor(QueryExecutor executor)
      : super.internal(executor);
}
