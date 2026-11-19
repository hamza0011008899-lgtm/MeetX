import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.lightSurface,
        onPrimary: Colors.white,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryLight,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: StadiumBorder(),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryDark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.darkSurface,
        onPrimary: Colors.white,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: StadiumBorder(),
      ),
    );
  }
}
