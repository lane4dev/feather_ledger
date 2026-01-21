import 'package:flutter/material.dart';

class ReportTheme {
  /// Color configuration for the activity heatmap (Orange Red).
  static Map<int, Color> get heatmapColors => {
        1: Colors.deepOrange.shade100,
        3: Colors.deepOrange.shade200,
        5: Colors.deepOrange.shade300,
        10: Colors.deepOrange.shade500,
        20: Colors.deepOrange.shade700,
        30: Colors.deepOrange.shade900,
      };
}
