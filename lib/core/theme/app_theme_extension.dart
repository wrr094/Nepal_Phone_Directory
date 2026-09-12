import 'package:flutter/material.dart';

@immutable
class LiquidGlassTheme extends ThemeExtension<LiquidGlassTheme> {
  const LiquidGlassTheme({
    required this.backgroundGradient,
    required this.glassSurface,
    required this.glassSurfaceStrong,
    required this.glassBorder,
    required this.primaryAccent,
    required this.emergencyAccent,
    required this.warningAccent,
    required this.successAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.bottomNavGlass,
    required this.searchGlass,
    required this.cardGlass,
    required this.callButtonColor,
  });

  final LinearGradient backgroundGradient;
  final Color glassSurface;
  final Color glassSurfaceStrong;
  final Color glassBorder;
  final Color primaryAccent;
  final Color emergencyAccent;
  final Color warningAccent;
  final Color successAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color bottomNavGlass;
  final Color searchGlass;
  final Color cardGlass;
  final Color callButtonColor;

  static LiquidGlassTheme of(BuildContext context) {
    return Theme.of(context).extension<LiquidGlassTheme>()!;
  }

  @override
  LiquidGlassTheme copyWith({
    LinearGradient? backgroundGradient,
    Color? glassSurface,
    Color? glassSurfaceStrong,
    Color? glassBorder,
    Color? primaryAccent,
    Color? emergencyAccent,
    Color? warningAccent,
    Color? successAccent,
    Color? textPrimary,
    Color? textSecondary,
    Color? bottomNavGlass,
    Color? searchGlass,
    Color? cardGlass,
    Color? callButtonColor,
  }) {
    return LiquidGlassTheme(
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      glassSurface: glassSurface ?? this.glassSurface,
      glassSurfaceStrong: glassSurfaceStrong ?? this.glassSurfaceStrong,
      glassBorder: glassBorder ?? this.glassBorder,
      primaryAccent: primaryAccent ?? this.primaryAccent,
      emergencyAccent: emergencyAccent ?? this.emergencyAccent,
      warningAccent: warningAccent ?? this.warningAccent,
      successAccent: successAccent ?? this.successAccent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      bottomNavGlass: bottomNavGlass ?? this.bottomNavGlass,
      searchGlass: searchGlass ?? this.searchGlass,
      cardGlass: cardGlass ?? this.cardGlass,
      callButtonColor: callButtonColor ?? this.callButtonColor,
    );
  }

  @override
  LiquidGlassTheme lerp(ThemeExtension<LiquidGlassTheme>? other, double t) {
    if (other is! LiquidGlassTheme) return this;
    return LiquidGlassTheme(
      backgroundGradient:
          Gradient.lerp(backgroundGradient, other.backgroundGradient, t)!
              as LinearGradient,
      glassSurface: Color.lerp(glassSurface, other.glassSurface, t)!,
      glassSurfaceStrong:
          Color.lerp(glassSurfaceStrong, other.glassSurfaceStrong, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      primaryAccent: Color.lerp(primaryAccent, other.primaryAccent, t)!,
      emergencyAccent: Color.lerp(emergencyAccent, other.emergencyAccent, t)!,
      warningAccent: Color.lerp(warningAccent, other.warningAccent, t)!,
      successAccent: Color.lerp(successAccent, other.successAccent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      bottomNavGlass: Color.lerp(bottomNavGlass, other.bottomNavGlass, t)!,
      searchGlass: Color.lerp(searchGlass, other.searchGlass, t)!,
      cardGlass: Color.lerp(cardGlass, other.cardGlass, t)!,
      callButtonColor: Color.lerp(callButtonColor, other.callButtonColor, t)!,
    );
  }
}
