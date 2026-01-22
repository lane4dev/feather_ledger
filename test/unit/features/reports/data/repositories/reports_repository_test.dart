import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/database/daos/transaction_dao.dart';
import 'package:feather_ledger/core/domain/entities/enums.dart';

import 'package:feather_ledger/features/reports/data/repositories/reports_repository.dart';
import 'package:feather_ledger/features/reports/domain/reports_entities.dart';

import '../../../../../support/mocks/mock_transaction_dao.dart';

void main() {
  late MockTransactionDao mockDao;
  late ReportsRepository repository;

  setUp(() {
    mockDao = MockTransactionDao();
    repository = ReportsRepositoryImpl(mockDao);
  });

  tearDown(() {
    mockDao.dispose();
  });

  group('ReportsRepositoryImpl', () {
    group('instantiation', () {
      test('should create instance with dao', () {
        expect(repository, isNotNull);
        expect(repository, isA<ReportsRepository>());
      });
    });

    group('watchHeatmapData', () {
      test('should return stream from dao', () {
        // Arrange
        final month = DateTime(2024, 1);

        // Act
        final stream = repository.watchHeatmapData(month);

        // Assert
        expect(stream, isA<Stream<Map<DateTime, int>>>());
      });

      test('should emit heatmap data from dao', () async {
        // Arrange
        final month = DateTime(2024, 1);
        final date1 = DateTime(2024, 1, 15);
        final date2 = DateTime(2024, 1, 20);
        final heatmapData = {
          date1: 5,
          date2: 3,
        };

        // Act
        final streamFuture = repository.watchHeatmapData(month).first;
        await Future.delayed(Duration.zero);
        mockDao.emitHeatmapData(heatmapData);

        final result = await streamFuture;

        // Assert
        expect(result, equals(heatmapData));
        expect(result[date1], equals(5));
        expect(result[date2], equals(3));
      });
    });

    group('watchCategoryBreakdown', () {
      test('should return stream of ReportCategoryTotal', () {
        // Arrange
        final month = DateTime(2024, 1);

        const type = TransactionType.expense;

        // Act
        final stream = repository.watchCategoryBreakdown(month, type);

        // Assert
        expect(stream, isA<Stream<List<ReportCategoryTotal>>>());
      });

      test('should transform CategoryTotal to ReportCategoryTotal', () async {
        // Arrange
        final month = DateTime(2024, 1);

        const type = TransactionType.expense;

        const category = Category(
          id: 1,
          name: 'Food',
          iconKey: 'restaurant',
          colorInt: 0xFFFF0000,
          type: TransactionType.expense,
          isDefault: false,
        );

        final categoryTotals = [
          CategoryTotal(category: category, total: 500.0),
        ];

        // Subscribe to stream first, then emit
        final streamFuture =
            repository.watchCategoryBreakdown(month, type).first;
        await Future.delayed(Duration.zero); // Give stream time to subscribe
        mockDao.emitCategoryTotals(categoryTotals);

        final result = await streamFuture;

        // Assert
        expect(result.length, 1);
        expect(result[0], isA<ReportCategoryTotal>());
        expect(result[0].category.id, 1);
        expect(result[0].category.name, 'Food');
        expect(result[0].category.iconKey, 'restaurant');
        expect(result[0].category.colorInt, 0xFFFF0000);
        expect(result[0].category.type, TransactionType.expense);
        expect(result[0].category.isDefault, false);
        expect(result[0].total, 500.0);
      });

      test('should handle multiple categories', () async {
        // Arrange
        final month = DateTime(2024, 1);

        const type = TransactionType.expense;

        const foodCategory = Category(
          id: 1,
          name: 'Food',
          iconKey: 'restaurant',
          colorInt: 0xFFFF0000,
          type: TransactionType.expense,
          isDefault: false,
        );

        const transportCategory = Category(
          id: 2,
          name: 'Transport',
          iconKey: 'directions_car',
          colorInt: 0xFF0000FF,
          type: TransactionType.expense,
          isDefault: false,
        );

        final categoryTotals = [
          CategoryTotal(category: foodCategory, total: 500.0),
          CategoryTotal(category: transportCategory, total: 300.0),
        ];

        // Subscribe to stream first, then emit
        final streamFuture =
            repository.watchCategoryBreakdown(month, type).first;
        await Future.delayed(Duration.zero);
        mockDao.emitCategoryTotals(categoryTotals);

        final result = await streamFuture;

        // Assert
        expect(result.length, 2);
        expect(result[0].category.name, 'Food');
        expect(result[0].total, 500.0);
        expect(result[1].category.name, 'Transport');
        expect(result[1].total, 300.0);
      });
    });
  });
}
