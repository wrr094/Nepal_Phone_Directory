import 'package:flutter/material.dart';

class AppTextStyles {
  const AppTextStyles._();

  static TextTheme textTheme(Color primary, Color secondary) {
    return TextTheme(
      headlineSmall: TextStyle(
        color: primary,
        fontWeight: FontWeight.w800,
        height: 1.15,
      ),
      titleLarge: TextStyle(
        color: primary,
        fontWeight: FontWeight.w800,
        height: 1.2,
      ),
      titleMedium: TextStyle(
        color: primary,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      titleSmall: TextStyle(
        color: primary,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      bodyLarge: TextStyle(color: primary, height: 1.4),
      bodyMedium: TextStyle(color: primary, height: 1.35),
      bodySmall: TextStyle(color: secondary, height: 1.35),
      labelLarge: TextStyle(color: primary, fontWeight: FontWeight.w700),
      labelMedium: TextStyle(color: secondary, fontWeight: FontWeight.w600),
    );
  }
}
