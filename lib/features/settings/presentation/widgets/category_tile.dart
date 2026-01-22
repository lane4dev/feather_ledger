import 'package:flutter/material.dart';

import 'package:feather_ledger/core/domain/entities/category.dart';

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
    // fallback icon: 0xe574 is usually an 'add' or generic circle in material icons if not found,
    // but here we just ensure we parse safely.
    final iconData = IconData(
      int.tryParse(category.iconKey) ?? 0xe574,
      fontFamily: 'MaterialIcons',
    );

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
