import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── ACCENT ──────────────────────────────────────────────────────────────────
  static const Color accent = Color(0xFF007AFF);
  static const Color accentSoft = Color(0xFFE8F0FF);

  // ── BACKGROUNDS ─────────────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF000000);

  // ── SURFACES ─────────────────────────────────────────────────────────────────
  static const Color surfaceLight = Color(0xFFF2F2F7);
  static const Color surfaceDark = Color(0xFF1C1C1E);

  static const Color elevatedSurfaceLight = Color(0xFFFFFFFF);
  static const Color elevatedSurfaceDark = Color(0xFF2C2C2E);

  // ── TEXT ─────────────────────────────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);

  static const Color textSecondaryLight = Color(0xFF8E8E93);
  static const Color textSecondaryDark = Color(0xFF8E8E93);

  // ── SEPARATORS ───────────────────────────────────────────────────────────────
  static const Color separatorLight = Color(0xFFE5E5EA);
  static const Color separatorDark = Color(0xFF38383A);

  // ── SEMANTIC ─────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color error = Color(0xFFFF3B30);
  static const Color dotEmpty = Color(0xFFD1D1D6);
  static const Color logDot = Color(0xFF34C759);

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

  static Color separator(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? separatorLight
          : separatorDark;

  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? backgroundLight
          : backgroundDark;
}
