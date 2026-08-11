import 'package:feather_ledger/app/design_system/app_sheet_handle.dart';
import 'package:feather_ledger/app/design_system/app_text_field.dart';
import 'package:feather_ledger/app/design_system/app_icon_button.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/theme/category_tokens.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/settings/domain/services/category_service.dart';
import 'package:feather_ledger/shared/presentation/ledger_error_localizer.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CategoryFormSheet extends ConsumerStatefulWidget {
  final CategoryEntity? category;
  final CategoryType type; // Removed prefix

  const CategoryFormSheet({super.key, this.category, required this.type});

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late int _colorInt;
  late String _iconKey;

  @override
  void initState() {
    super.initState();
    _name = widget.category?.name ?? '';
    _colorInt =
        widget.category?.colorInt ?? CategoryTokens.defaultColor.toARGB32();
    _iconKey = widget.category?.iconKey ??
        CategoryTokens.defaultIcons.first.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.category != null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        context.spacing.lg,
        context.spacing.sm,
        context.spacing.lg,
        context.spacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle Bar
          const AppSheetHandle(),

          // Action Bar
          Row(
            children: [
              AppIconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => context.pop(),
                tooltip: l10n.cancel,
              ),
              const Spacer(),
              if (isEditing)
                AppIconButton.destructive(
                  icon: const Icon(LucideIcons.trash2),
                  onPressed: _deleteCategory,
                  tooltip: l10n.delete,
                ),
            ],
          ),
          SizedBox(height: context.spacing.sm),

          Flexible(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon Preview (Hero-ish)
                    Center(
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor:
                            Color(_colorInt).withValues(alpha: 0.2),
                        foregroundColor: Color(_colorInt),
                        // Through the one place that knows the icon font: a
                        // stored key is a Lucide code point since the
                        // migration, and naming MaterialIcons here drew the
                        // wrong glyph (or threw on an unparseable key).
                        child: Icon(
                          CategoryTokens.iconFor(_iconKey),
                          size: 32,
                        ),
                      ),
                    ),
                    SizedBox(height: context.spacing.lg),

                    // Name Input
                    AppTextField(
                      initialValue: _name,
                      textAlign: TextAlign.start,
                      variant: AppFieldVariant.inline,
                      hintText: l10n.categoryNameHint,
                      labelText: l10n.name,
                      floatingLabel: true,
                      style: Theme.of(context).textTheme.headlineSmall,
                      validator: (value) => (value == null || value.isEmpty)
                          ? l10n.required
                          : null,
                      onSaved: (value) => _name = value!,
                    ),
                    SizedBox(height: context.spacing.lg),

                    const FeatherDivider(),
                    SizedBox(height: context.spacing.md),

                    // Color Picker — creation only (spec 003 has no recolor
                    // event; edits rename only)
                    if (!isEditing) ...[
                      Text(l10n.color, style: theme.textTheme.titleMedium),
                      SizedBox(height: context.spacing.sm),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: CategoryTokens.defaultColors.map((color) {
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _colorInt = color.toARGB32()),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: _colorInt == color.toARGB32()
                                    ? Border.all(
                                        color: colorScheme.primary, width: 2)
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: context.spacing.lg),

                      // Icon Picker
                      Text(l10n.icon, style: theme.textTheme.titleMedium),
                      SizedBox(height: context.spacing.sm),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: CategoryTokens.defaultIcons.map((iconCode) {
                          final isSelected = _iconKey == iconCode.toString();
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _iconKey = iconCode.toString()),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorScheme.primaryContainer
                                    : null,
                                borderRadius: context.metrics.chipBorderRadius,
                              ),
                              child: Icon(
                                CategoryTokens.iconFor('$iconCode'),
                                color: isSelected
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurface,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    SizedBox(height: context.spacing.xl),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        onPressed: _save,
                        child: Text(l10n.save),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCategoryConfirmationTitle),
        content: Text(l10n.deleteCategoryConfirmationMessage),
        actions: [
          AppButton.text(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          AppButton.text(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.delete,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge!
                  .copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final result = await ref.read(categoryServiceProvider).archiveCategory(
            commandId: const Uuid().v4(),
            categoryId: widget.category!.id,
          );
      if (!mounted) return;
      if (result case Failure(:final code)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(code.message(AppLocalizations.of(context)!))),
        );
        return;
      }
      context.pop();
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final service = ref.read(categoryServiceProvider);

      Result<void> result;
      if (widget.category != null) {
        // Only the name is editable after creation (spec 003: no
        // icon/color events exist).
        result = await service.renameCategory(
          commandId: const Uuid().v4(),
          categoryId: widget.category!.id,
          name: _name,
        );
      } else {
        result = await service.createCategory(
          commandId: const Uuid().v4(),
          name: _name,
          iconKey: _iconKey,
          colorInt: _colorInt,
          type: widget.type,
        );
      }

      if (!mounted) return;
      if (result case Failure(:final code)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(code.message(AppLocalizations.of(context)!))),
        );
        return;
      }
      context.pop();
    }
  }
}
