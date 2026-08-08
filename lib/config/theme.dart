import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryStart,
        secondary: AppColors.secondary,
        tertiary: AppColors.accent,
        surface: AppColors.white,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.lightGrey,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _headlineStyle(),
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      textTheme: TextTheme(
        displayLarge: _headlineStyle(size: AppTypography.fontSizeXxl),
        displayMedium: _headlineStyle(size: AppTypography.fontSizeXl),
        headlineSmall: _headlineStyle(size: AppTypography.fontSizeLg),
        titleLarge: _titleStyle(),
        bodyLarge: _bodyStyle(),
        bodyMedium: _bodyStyle(size: AppTypography.fontSizeMd),
        bodySmall: _bodyStyle(size: AppTypography.fontSizeSm),
        labelLarge: _labelStyle(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryStart,
          foregroundColor: AppColors.white,
          minimumSize: const Size(AppSizes.minTapTarget, AppSizes.minTapTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          elevation: AppSizes.elevationMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryStart,
          minimumSize: const Size(AppSizes.minTapTarget, AppSizes.minTapTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          side: const BorderSide(color: AppColors.primaryStart),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryStart,
          minimumSize: const Size(AppSizes.minTapTarget, AppSizes.minTapTarget),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.all(AppSizes.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.mediumGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.mediumGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.primaryStart, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        elevation: AppSizes.elevationSmall,
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryStart,
        secondary: AppColors.secondary,
        tertiary: AppColors.accent,
        surface: AppColors.darkSurface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _headlineStyle(isDark: true),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      textTheme: TextTheme(
        displayLarge: _headlineStyle(size: AppTypography.fontSizeXxl, isDark: true),
        displayMedium: _headlineStyle(size: AppTypography.fontSizeXl, isDark: true),
        headlineSmall: _headlineStyle(size: AppTypography.fontSizeLg, isDark: true),
        titleLarge: _titleStyle(isDark: true),
        bodyLarge: _bodyStyle(isDark: true),
        bodyMedium: _bodyStyle(size: AppTypography.fontSizeMd, isDark: true),
        bodySmall: _bodyStyle(size: AppTypography.fontSizeSm, isDark: true),
        labelLarge: _labelStyle(isDark: true),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryStart,
          foregroundColor: AppColors.white,
          minimumSize: const Size(AppSizes.minTapTarget, AppSizes.minTapTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          elevation: AppSizes.elevationMedium,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        elevation: AppSizes.elevationSmall,
      ),
    );
  }

  static TextStyle _headlineStyle({
    double size = AppTypography.fontSizeXl,
    bool isDark = false,
  }) {
    return GoogleFonts.notoSansJp(
      fontSize: size,
      fontWeight: AppTypography.weightBold,
      color: isDark ? AppColors.white : AppColors.black,
    );
  }

  static TextStyle _titleStyle({bool isDark = false}) {
    return GoogleFonts.notoSansJp(
      fontSize: AppTypography.fontSizeLg,
      fontWeight: AppTypography.weightSemibold,
      color: isDark ? AppColors.white : AppColors.black,
    );
  }

  static TextStyle _bodyStyle({
    double size = AppTypography.fontSizeMd,
    bool isDark = false,
  }) {
    return GoogleFonts.notoSansJp(
      fontSize: size,
      fontWeight: AppTypography.weightRegular,
      color: isDark ? AppColors.white : AppColors.black,
    );
  }

  static TextStyle _labelStyle({bool isDark = false}) {
    return GoogleFonts.notoSansJp(
      fontSize: AppTypography.fontSizeSm,
      fontWeight: AppTypography.weightSemibold,
      color: isDark ? AppColors.mediumGrey : AppColors.darkGrey,
    );
  }
}
