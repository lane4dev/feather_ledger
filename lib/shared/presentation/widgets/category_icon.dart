import 'dart:convert';

import 'package:feather_ledger/app/theme/category_tokens.dart';
import 'package:flutter/material.dart';

/// Custom icons are embedded in the event so snapshots and backups remain portable.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon(
      {super.key, required this.iconKey, this.size = 24, this.color});

  static const imagePrefix = 'image/png;base64,';
  final String iconKey;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (iconKey.startsWith(imagePrefix)) {
      try {
        final bytes = base64Decode(iconKey.substring(imagePrefix.length));
        return ClipRRect(
          borderRadius: BorderRadius.circular(size / 5),
          child: Image.memory(bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(CategoryTokens.iconFor(''), size: size, color: color)),
        );
      } on FormatException {
        return Icon(CategoryTokens.iconFor(''), size: size, color: color);
      }
    }
    return Icon(CategoryTokens.iconFor(iconKey), size: size, color: color);
  }
}
