import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/design_system/app_floating_action_button_location.dart';
import 'package:feather_ledger/app/design_system/app_icon_button.dart';
import 'package:feather_ledger/app/design_system/app_segmented_control.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';

import '../widgets/category_form_sheet.dart';
import '../widgets/category_tile.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen> {
  static const _pageDuration = Duration(milliseconds: 220);

  final _pageController = PageController();
  CategoryType _selected = CategoryType.expense;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _select(CategoryType type) {
    if (type == _selected) return;
    setState(() => _selected = type);
    final page = type == CategoryType.expense ? 0 : 1;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(page);
      return;
    }
    _pageController.animateToPage(
      page,
      duration: _pageDuration,
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    final type = index == 0 ? CategoryType.expense : CategoryType.income;
    if (type == _selected) return;
    setState(() => _selected = type);
  }

  Future<void> _showCategorySheet(CategoryEntity? category, CategoryType type) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      builder: (context) => CategoryFormSheet(category: category, type: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pagePadding = context.pagePadding;

    return Scaffold(
      appBar: AppBar(
        leading: AppIconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        title: Text(l10n.categories),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              pagePadding.left,
              context.spacing.md,
              pagePadding.right,
              0,
            ),
            child: AppSegmentedControl<CategoryType>(
              key: const ValueKey('category-type-segments'),
              widthFactor: 1,
              segments: [
                ButtonSegment(
                  value: CategoryType.expense,
                  label: Text(l10n.expense),
                ),
                ButtonSegment(
                  value: CategoryType.income,
                  label: Text(l10n.income),
                ),
              ],
              selected: _selected,
              onSelected: _select,
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                CategoryList(
                  type: CategoryType.expense,
                  onCreate: () =>
                      _showCategorySheet(null, CategoryType.expense),
                  onEdit: (category) =>
                      _showCategorySheet(category, CategoryType.expense),
                ),
                CategoryList(
                  type: CategoryType.income,
                  onCreate: () => _showCategorySheet(null, CategoryType.income),
                  onEdit: (category) =>
                      _showCategorySheet(category, CategoryType.income),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: AppFloatingActionButtonLocation(context),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => _showCategorySheet(null, _selected),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}

/// The FAB floats a navigation bar and one margin above the bottom edge, so
/// the list must clear both the padding and the 56dp button itself.
double _listBottomPadding(BuildContext context) =>
    context.spacing.xl * 3 + context.metrics.controlHeight + context.spacing.sm;

class CategoryList extends ConsumerWidget {
  final CategoryType type;
  final VoidCallback onCreate;
  final ValueChanged<CategoryEntity> onEdit;

  const CategoryList({
    super.key,
    required this.type,
    required this.onCreate,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoryListProvider(type));

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return _CategoryEmptyState(type: type, onCreate: onCreate);
        }
        final pagePadding = context.pagePadding;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            pagePadding.left,
            context.spacing.md,
            pagePadding.right,
            _listBottomPadding(context),
          ),
          children: [
            AppCard.group(
              child: Column(
                children: [
                  for (var i = 0; i < categories.length; i++) ...[
                    if (i > 0) const FeatherDivider(),
                    CategoryTile(
                      key: ValueKey(categories[i].id),
                      category: categories[i],
                      onTap: () => onEdit(categories[i]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) {
        debugPrint('Category management failed to load $type: $error');
        return _CategoryErrorState(message: l10n.categoriesLoadFailed);
      },
    );
  }
}

class _CategoryEmptyState extends StatelessWidget {
  final CategoryType type;
  final VoidCallback onCreate;

  const _CategoryEmptyState({required this.type, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final pagePadding = context.pagePadding;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          pagePadding.left,
          context.spacing.lg,
          pagePadding.right,
          _listBottomPadding(context),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight -
                    context.spacing.lg -
                    _listBottomPadding(context))
                .clamp(0, double.infinity),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    LucideIcons.tags,
                    size: 28,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: context.spacing.md),
                Text(
                  l10n.categoriesEmptyTitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.sectionTitle(context),
                ),
                SizedBox(height: context.spacing.xs),
                Text(
                  l10n.categoriesEmptyHint,
                  textAlign: TextAlign.center,
                  style: AppTypography.meta(context),
                ),
                SizedBox(height: context.spacing.lg),
                AppButton(
                  onPressed: onCreate,
                  icon: const Icon(LucideIcons.plus),
                  child: Text(l10n.addCategory),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryErrorState extends StatelessWidget {
  final String message;

  const _CategoryErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: context.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.circleAlert,
                size: 28, color: scheme.onSurfaceVariant),
            SizedBox(height: context.spacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.meta(context),
            ),
          ],
        ),
      ),
    );
  }
}
