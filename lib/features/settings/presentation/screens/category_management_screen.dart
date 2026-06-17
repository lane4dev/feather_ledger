import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';

import '../widgets/category_form_sheet.dart';
import '../widgets/category_tile.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categories), // Ensure l10n has this key or fallback
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.expense), // Ensure l10n key
            Tab(text: l10n.income), // Ensure l10n key
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CategoryList(type: CategoryType.expense), // Removed prefix
          CategoryList(type: CategoryType.income), // Removed prefix
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final type = _tabController.index == 0
              ? CategoryType.expense // Removed prefix
              : CategoryType.income; // Removed prefix
          _showCategorySheet(context, null, type);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCategorySheet(
      BuildContext context, CategoryEntity? category, CategoryType type) {
    // Removed prefix
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      builder: (context) => CategoryFormSheet(category: category, type: type),
    );
  }
}

class CategoryList extends ConsumerWidget {
  final CategoryType type; // Removed prefix

  const CategoryList({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoryListProvider(type));

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return Center(child: Text(l10n.noCategoriesFound));
        }
        return ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return CategoryTile(
              category: category,
              onTap: () => _showCategorySheet(context, category, type),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text(l10n.errorPrefix(e.toString()))),
    );
  }

  void _showCategorySheet(
      BuildContext context, CategoryEntity? category, CategoryType type) {
    // Removed prefix
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      builder: (context) => CategoryFormSheet(category: category, type: type),
    );
  }
}
