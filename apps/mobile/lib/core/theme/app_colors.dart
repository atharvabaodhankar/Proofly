import 'package:flutter/material.dart';

/// Design tokens derived directly from mock.html
class AppColors {
  // Brand Primaries
  static const Color primary = Color(0xFF3525CD);
  static const Color primaryLight = Color(0xFF4D44E3);
  static const Color primaryContainer = Color(0xFF4F46E5);
  static const Color onPrimary = Colors.white;
  static const Color onPrimaryContainer = Color(0xFFDAD7FF);

  // Secondary & Accents
  static const Color secondary = Color(0xFF4648D4);
  static const Color secondaryLight = Color(0xFF6063EE);
  static const Color cyanAccent = Color(0xFF38BDF8);

  // Success / Verified
  static const Color verifiedGreen = Color(0xFF137333);
  static const Color verifiedGreenBg = Color(0xFFE6F4EA);
  static const Color emerald = Color(0xFF10B981);

  // Warning / Expiring
  static const Color warningOrange = Color(0xFF885500);
  static const Color warningBg = Color(0xFFFFE0B2);
  static const Color tertiary = Color(0xFF684000);
  static const Color tertiaryDim = Color(0xFFFFB95F);

  // Error / Revoked
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);

  // Light Surfaces
  static const Color backgroundLight = Color(0xFFF9F9FF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceLowLight = Color(0xFFF1F3FF);
  static const Color surfaceContainerLight = Color(0xFFE9EDFF);
  static const Color surfaceHighLight = Color(0xFFE1E8FD);
  static const Color outlineLight = Color(0xFF777587);
  static const Color outlineVariantLight = Color(0xFFC7C4D8);
  static const Color textMainLight = Color(0xFF141B2B);
  static const Color textMutedLight = Color(0xFF464555);

  // Dark Surfaces
  static const Color backgroundDark = Color(0xFF0B0F19);
  static const Color surfaceDark = Color(0xFF141B2B);
  static const Color surfaceLowDark = Color(0xFF0F172A);
  static const Color surfaceContainerDark = Color(0xFF1E293B);
  static const Color surfaceHighDark = Color(0xFF334155);
  static const Color outlineDark = Color(0xFF94A3B8);
  static const Color outlineVariantDark = Color(0xFF475569);
  static const Color textMainDark = Color(0xFFF8FAFC);
  static const Color textMutedDark = Color(0xFF94A3B8);
}
