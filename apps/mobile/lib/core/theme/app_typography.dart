import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextStyle display(bool isDark) => GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02,
        color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
      );

  static TextStyle headlineLg(bool isDark) => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.01,
        color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
      );

  static TextStyle headlineMd(bool isDark) => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
      );

  static TextStyle headlineSm(bool isDark) => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
      );

  static TextStyle bodyLg(bool isDark) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
      );

  static TextStyle bodyMd(bool isDark) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
      );

  static TextStyle labelSm(bool isDark) => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.05,
        color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
      );

  static TextStyle hashMono({Color? color}) => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.primary,
      );
}
