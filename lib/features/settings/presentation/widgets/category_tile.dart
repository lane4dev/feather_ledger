import 'package:flutter/material.dart';

import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/app/theme/category_tokens.dart';

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
    final iconData = CategoryTokens.iconFor(category.iconKey);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.2),
        foregroundColor: color,
        child: Icon(iconData, size: 20),
      ),
      title: Text(category.name),
      onTap: onTap,
    );
  }
}
