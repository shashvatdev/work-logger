import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  // ── LIGHT THEME ──────────────────────────────────────────────────────────────
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.light(
        primary: AppColors.accent,
        onPrimary: Colors.white,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimaryLight,
        surfaceContainerHighest: AppColors.elevatedSurfaceLight,
        outline: AppColors.separatorLight,
        secondary: AppColors.accentSoft,
        onSecondary: AppColors.accent,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: _buildTextTheme(isLight: true),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundLight.withOpacity(0.9),
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
          letterSpacing: -0.4,
        ),
      ),
      dividerColor: AppColors.separatorLight,
      dividerTheme: const DividerThemeData(
        color: AppColors.separatorLight,
        thickness: 0.5,
        space: 0,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      inputDecorationTheme: _buildInputDecoration(isLight: true),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _buildPrimaryButtonStyle(),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.elevatedSurfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.elevatedSurfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        dragHandleColor: AppColors.separatorLight,
        dragHandleSize: const Size(36, 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.elevatedSurfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryLight,
          letterSpacing: -0.3,
        ),
        contentTextStyle: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondaryLight,
          height: 1.55,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1C1C1E),
        contentTextStyle: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return AppColors.separatorLight;
        }),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ── DARK THEME ──────────────────────────────────────────────────────────────
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.dark(
        primary: AppColors.accent,
        onPrimary: Colors.white,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        surfaceContainerHighest: AppColors.elevatedSurfaceDark,
        outline: AppColors.separatorDark,
        secondary: AppColors.accentSoft,
        onSecondary: AppColors.accent,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: _buildTextTheme(isLight: false),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundDark.withOpacity(0.9),
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
          letterSpacing: -0.4,
        ),
      ),
      dividerColor: AppColors.separatorDark,
      dividerTheme: const DividerThemeData(
        color: AppColors.separatorDark,
        thickness: 0.5,
        space: 0,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      inputDecorationTheme: _buildInputDecoration(isLight: false),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _buildPrimaryButtonStyle(),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.elevatedSurfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.elevatedSurfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        dragHandleColor: AppColors.separatorDark,
        dragHandleSize: const Size(36, 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.elevatedSurfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
          letterSpacing: -0.3,
        ),
        contentTextStyle: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondaryDark,
          height: 1.55,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2C2C2E),
        contentTextStyle: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return AppColors.separatorDark;
        }),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _buildTextTheme({required bool isLight}) {
    final textColor =
        isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark;
    final secondaryColor =
        isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark;

    return GoogleFonts.outfitTextTheme().copyWith(
      // ── Display ────────────────────────────────────────────────────────────
      displayLarge: GoogleFonts.outfit(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: textColor,
        height: 1.1,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: textColor,
        height: 1.15,
      ),
      displaySmall: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        color: textColor,
        height: 1.2,
      ),
      // ── Headline ───────────────────────────────────────────────────────────
      headlineLarge: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: textColor,
        height: 1.2,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: textColor,
        height: 1.25,
      ),
      headlineSmall: GoogleFonts.outfit(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: textColor,
        height: 1.3,
      ),
      // ── Title ──────────────────────────────────────────────────────────────
      titleLarge: GoogleFonts.outfit(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: textColor,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: textColor,
      ),
      titleSmall: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: textColor,
      ),
      // ── Body ───────────────────────────────────────────────────────────────
      bodyLarge: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        color: textColor,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        color: textColor,
        height: 1.55,
      ),
      bodySmall: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: secondaryColor,
        height: 1.5,
      ),
      // ── Label ──────────────────────────────────────────────────────────────
      labelLarge: GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: textColor,
      ),
      labelMedium: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: secondaryColor,
      ),
      labelSmall: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: secondaryColor,
      ),
    );
  }

  static InputDecorationTheme _buildInputDecoration({required bool isLight}) {
    final fillColor = isLight
        ? AppColors.surfaceLight
        : AppColors.elevatedSurfaceDark;
    final hintColor =
        isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark;
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      hintStyle: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: hintColor,
        letterSpacing: -0.1,
      ),
      labelStyle: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: hintColor,
      ),
      floatingLabelStyle: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.accent,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(
          color: isLight ? AppColors.separatorLight : AppColors.separatorDark,
          width: 0.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.error, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      prefixIconColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.focused)) return AppColors.accent;
        return hintColor;
      }),
    );
  }

  static ButtonStyle _buildPrimaryButtonStyle() {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppColors.accent.withOpacity(0.4);
        }
        return AppColors.accent;
      }),
      foregroundColor: WidgetStateProperty.all(Colors.white),
      minimumSize: WidgetStateProperty.all(
          const Size(double.infinity, AppSpacing.buttonHeightLg)),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      elevation: WidgetStateProperty.all(0),
      overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.1)),
      textStyle: WidgetStateProperty.all(
        GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
