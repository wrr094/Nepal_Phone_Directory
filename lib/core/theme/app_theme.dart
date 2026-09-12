import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_text_styles.dart';
import 'app_theme_extension.dart';

class AppTheme {
  const AppTheme._();

  static final lightLiquidGlassTheme = _buildTheme(
    brightness: Brightness.light,
    glass: LiquidGlassTheme(
      backgroundGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.lightBackgroundTop,
          Color(0xFFF5FAFF),
          AppColors.lightBackgroundBottom,
        ],
      ),
      glassSurface: Colors.white.withValues(alpha: 0.58),
      glassSurfaceStrong: Colors.white.withValues(alpha: 0.72),
      glassBorder: const Color(0xFF8EC4FF).withValues(alpha: 0.40),
      primaryAccent: AppColors.lightPrimary,
      emergencyAccent: AppColors.lightEmergency,
      warningAccent: AppColors.lightWarning,
      successAccent: AppColors.lightSuccess,
      textPrimary: AppColors.lightTextPrimary,
      textSecondary: AppColors.lightTextSecondary,
      bottomNavGlass: Colors.white.withValues(alpha: 0.70),
      searchGlass: Colors.white.withValues(alpha: 0.70),
      cardGlass: Colors.white.withValues(alpha: 0.56),
      callButtonColor: AppColors.lightPrimary,
    ),
  );

  static final darkLiquidGlassTheme = _buildTheme(
    brightness: Brightness.dark,
    glass: LiquidGlassTheme(
      backgroundGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF07111E), Color(0xFF0A1E36), Color(0xFF06101D)],
      ),
      glassSurface: const Color(0xFF132A46).withValues(alpha: 0.42),
      glassSurfaceStrong: const Color(0xFF183457).withValues(alpha: 0.54),
      glassBorder: const Color(0xFF8EC4FF).withValues(alpha: 0.20),
      primaryAccent: AppColors.darkPrimary,
      emergencyAccent: AppColors.darkEmergency,
      warningAccent: AppColors.darkWarning,
      successAccent: AppColors.darkSuccess,
      textPrimary: AppColors.darkTextPrimary,
      textSecondary: AppColors.darkTextSecondary,
      bottomNavGlass: const Color(0xFF102641).withValues(alpha: 0.62),
      searchGlass: const Color(0xFF132A46).withValues(alpha: 0.50),
      cardGlass: const Color(0xFF10243D).withValues(alpha: 0.46),
      callButtonColor: AppColors.darkPrimaryStrong,
    ),
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required LiquidGlassTheme glass,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: glass.primaryAccent,
      brightness: brightness,
      primary: glass.primaryAccent,
      error: glass.emergencyAccent,
      surface: glass.glassSurfaceStrong,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      visualDensity: VisualDensity.standard,
      textTheme: AppTextStyles.textTheme(
        glass.textPrimary,
        glass.textSecondary,
      ),
      extensions: [glass],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: glass.textPrimary,
        titleTextStyle: TextStyle(
          color: glass.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: glass.cardGlass,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(color: glass.glassBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glass.searchGlass,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: BorderSide(color: glass.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: BorderSide(color: glass.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: BorderSide(color: glass.primaryAccent, width: 1.5),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(glass.searchGlass),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card),
            side: BorderSide(color: glass.glassBorder),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: glass.glassSurfaceStrong,
        selectedColor: glass.primaryAccent.withValues(alpha: 0.18),
        side: BorderSide(color: glass.glassBorder),
        labelStyle: TextStyle(color: glass.textPrimary),
        secondaryLabelStyle: TextStyle(color: glass.textPrimary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(glass.callButtonColor),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          minimumSize: const WidgetStatePropertyAll(Size(44, 48)),
          elevation: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.pressed) ? 0 : 5;
          }),
          shadowColor: WidgetStatePropertyAll(
            Colors.black.withValues(
              alpha: brightness == Brightness.dark ? 0.45 : 0.22,
            ),
          ),
          overlayColor: WidgetStatePropertyAll(
            Colors.white.withValues(alpha: 0.12),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(glass.primaryAccent),
          minimumSize: const WidgetStatePropertyAll(Size(44, 48)),
          elevation: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.pressed) ? 0 : 2;
          }),
          shadowColor: WidgetStatePropertyAll(
            Colors.black.withValues(alpha: 0.14),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            return BorderSide(
              color:
                  states.contains(WidgetState.pressed)
                      ? glass.primaryAccent
                      : glass.glassBorder,
              width: states.contains(WidgetState.pressed) ? 1.6 : 1,
            );
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.pressed)
                ? glass.primaryAccent.withValues(alpha: 0.12)
                : glass.glassSurfaceStrong;
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return glass.primaryAccent.withValues(alpha: 0.18);
            }
            return Colors.transparent;
          }),
          elevation: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.pressed) ? 0 : 1;
          }),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.transparent,
        indicatorColor: glass.primaryAccent.withValues(alpha: 0.18),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: glass.textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      dividerTheme: DividerThemeData(color: glass.glassBorder),
    );
  }
}
