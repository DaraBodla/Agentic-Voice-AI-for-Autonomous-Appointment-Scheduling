import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Core
  static const bg = Color(0xFFF7F6F3);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF0EFEB);
  static const border = Color(0xFFE6E3DD);
  static const borderActive = Color(0xFFD1CEC7);

  // Text
  static const text = Color(0xFF1B1916);
  static const textDim = Color(0xFF6D6862);
  static const textMuted = Color(0xFFA09A93);

  // Accent
  static const accent = Color(0xFF6C5CFC);
  static const accentLight = Color(0xFFA29BFE);
  static const accentDim = Color(0xFFEFECFF);

  // Semantic
  static const coral = Color(0xFFFF6B6B);
  static const coralDim = Color(0xFFFFF0F0);
  static const teal = Color(0xFF2EC4B6);
  static const tealDim = Color(0xFFE6FAF7);
  static const green = Color(0xFF06D6A0);
  static const greenDim = Color(0xFFE4FBF3);
  static const red = Color(0xFFEF476F);
  static const redDim = Color(0xFFFDE8ED);
  static const orange = Color(0xFFFFB800);
  static const orangeDim = Color(0xFFFFF7E0);
  static const blue = Color(0xFF3A86FF);
  static const blueDim = Color(0xFFEBF2FF);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bg,
      primaryColor: AppColors.accent,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accent,
        secondary: AppColors.teal,
        surface: AppColors.surface,
        error: AppColors.red,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.text),
        titleTextStyle: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
        hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMuted,
      ),
      dividerColor: AppColors.border,
      useMaterial3: true,
    );
  }
}