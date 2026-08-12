import 'package:flutter/material.dart';
import 'package:feather_ledger/app/design_system/app_badge.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';

import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/shared/presentation/widgets/category_icon.dart';

class CategoryTile extends StatelessWidget {
  final CategoryEntity category;
  final VoidCallback? onTap;

  const CategoryTile({
    super.key,
    required this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorInt);

    return ListTile(
      leading: AppIconBadge(
          color: color,
          child: CategoryIcon(
              iconKey: category.iconKey,
              size: context.metrics.iconSize,
              color: color)),
      title: Text(category.name),
      onTap: onTap,
    );
  }
}
