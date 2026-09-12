import 'package:flutter/material.dart';

class AppShadows {
  const AppShadows._();

  static List<BoxShadow> soft(Color color) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.12),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ];
  }

  static List<BoxShadow> tight(Color color) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.10),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ];
  }

  static List<BoxShadow> bevel({
    required Color highlight,
    required Color lowlight,
    required bool pressed,
    double intensity = 1,
  }) {
    final level = intensity.clamp(0.0, 1.4);
    if (pressed) {
      return [
        BoxShadow(
          color: lowlight.withValues(alpha: 0.18 * level),
          blurRadius: 8,
          offset: const Offset(2, 3),
        ),
        BoxShadow(
          color: highlight.withValues(alpha: 0.08 * level),
          blurRadius: 5,
          offset: const Offset(-1, -1),
        ),
      ];
    }

    return [
      BoxShadow(
        color: highlight.withValues(alpha: 0.18 * level),
        blurRadius: 10,
        offset: const Offset(-3, -3),
      ),
      BoxShadow(
        color: lowlight.withValues(alpha: 0.22 * level),
        blurRadius: 18,
        offset: const Offset(7, 9),
      ),
      BoxShadow(
        color: lowlight.withValues(alpha: 0.06 * level),
        blurRadius: 4,
        offset: const Offset(1, 2),
      ),
    ];
  }
}
