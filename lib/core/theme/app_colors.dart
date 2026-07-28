import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── ACCENT ──────────────────────────────────────────────────────────────────
  static const Color accent = Color(0xFF007AFF);
  static const Color accentDeep = Color(0xFF0A84FF);
  static const Color accentSoft = Color(0xFFE8F0FF);
  static const Color accentMid = Color(0x0F007AFF); // 6% opacity
  static const Color accentGlow = Color(0x1F007AFF); // 12% opacity

  // ── ACCENT GRADIENT ──────────────────────────────────────────────────────────
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A84FF), Color(0xFF007AFF)],
  );

  static const LinearGradient accentGradientSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A91FF), Color(0xFF0070F0)],
  );

  // ── BACKGROUNDS ─────────────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF000000);

  // ── SURFACES ─────────────────────────────────────────────────────────────────
  static const Color surfaceLight = Color(0xFFF2F2F7);
  static const Color surfaceDark = Color(0xFF1C1C1E);

  static const Color elevatedSurfaceLight = Color(0xFFFFFFFF);
  static const Color elevatedSurfaceDark = Color(0xFF2C2C2E);

  // ── GLASS ────────────────────────────────────────────────────────────────────
  static const Color glassLight = Color(0xCCFFFFFF); // 80% white
  static const Color glassDark = Color(0xCC1C1C1E); // 80% dark surface

  // ── TEXT ─────────────────────────────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);

  static const Color textSecondaryLight = Color(0xFF8E8E93);
  static const Color textSecondaryDark = Color(0xFF8E8E93);

  static const Color textTertiaryLight = Color(0xFFAEAEB2);
  static const Color textTertiaryDark = Color(0xFF636366);

  // ── SEPARATORS ───────────────────────────────────────────────────────────────
  static const Color separatorLight = Color(0xFFE5E5EA);
  static const Color separatorDark = Color(0xFF38383A);

  // ── SEMANTIC ─────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF34C759);
  static const Color successSoft = Color(0x1F34C759);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color warningSoft = Color(0x1FFF9F0A);
  static const Color error = Color(0xFFFF3B30);
  static const Color errorSoft = Color(0x1FFF3B30);
  static const Color dotEmpty = Color(0xFFD1D1D6);
  static const Color logDot = Color(0xFF34C759);

  // ── SHADOWS ──────────────────────────────────────────────────────────────────
  static List<BoxShadow> cardShadowLight = [
    BoxShadow(
      color: const Color(0xFF000000).withOpacity(0.05),
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: const Color(0xFF000000).withOpacity(0.04),
      blurRadius: 4,
      spreadRadius: 0,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> elevatedCardShadowLight = [
    BoxShadow(
      color: const Color(0xFF000000).withOpacity(0.08),
      blurRadius: 24,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF000000).withOpacity(0.04),
      blurRadius: 8,
      spreadRadius: 0,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> accentShadow = [
    BoxShadow(
      color: accent.withOpacity(0.3),
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> floatShadow = [
    BoxShadow(
      color: const Color(0xFF000000).withOpacity(0.12),
      blurRadius: 32,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];

  // ── HELPERS ──────────────────────────────────────────────────────────────────
  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? surfaceLight
          : surfaceDark;

  static Color elevated(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? elevatedSurfaceLight
          : elevatedSurfaceDark;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? textPrimaryLight
          : textPrimaryDark;

  static Color textSecondary(BuildContext context) => textSecondaryLight;

  static Color textTertiary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? textTertiaryLight
          : textTertiaryDark;

  static Color separator(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? separatorLight
          : separatorDark;

  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? backgroundLight
          : backgroundDark;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Project color palette — consistent hash-based colors for projects
  static const List<Color> projectColors = [
    Color(0xFF007AFF), // Blue
    Color(0xFF34C759), // Green
    Color(0xFFFF9500), // Orange
    Color(0xFFFF2D55), // Pink
    Color(0xFF5856D6), // Purple
    Color(0xFF32ADE6), // Teal
    Color(0xFFFF6B35), // Coral
    Color(0xFF30B0C7), // Cyan
  ];

  static Color projectColor(String projectId) {
    final index = projectId.hashCode.abs() % projectColors.length;
    return projectColors[index];
  }
}
