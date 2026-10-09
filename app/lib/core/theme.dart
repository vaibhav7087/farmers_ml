import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color primaryLightGreen = Color(0xFF4CAF50);
  static const Color primaryDarkGreen = Color(0xFF1B5E20);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentRed = Color(0xFFE53935);
  static const Color backgroundLight = Color(0xFFF1F8E9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF1B1B1B);
  static const Color surfaceDark = Color(0xFF2C2C2C);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.light,
        primary: primaryGreen,
        secondary: accentOrange,
        error: accentRed,
        surface: surfaceLight,
        background: backgroundLight,
      ),
      textTheme: GoogleFonts.notoSansDevanagariTextTheme().copyWith(
        headlineLarge: GoogleFonts.notoSansDevanagari(fontSize: 32, fontWeight: FontWeight.bold, color: primaryDarkGreen),
        headlineMedium: GoogleFonts.notoSansDevanagari(fontSize: 24, fontWeight: FontWeight.w600, color: primaryGreen),
        headlineSmall: GoogleFonts.notoSansDevanagari(fontSize: 20, fontWeight: FontWeight.w600, color: primaryGreen),
        titleLarge: GoogleFonts.notoSansDevanagari(fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.notoSansDevanagari(fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.notoSansDevanagari(fontSize: 16),
        bodyMedium: GoogleFonts.notoSansDevanagari(fontSize: 14),
        labelLarge: GoogleFonts.notoSansDevanagari(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.notoSansDevanagari(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.notoSansDevanagari(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.notoSansDevanagari(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC8E6C9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        labelStyle: GoogleFonts.notoSansDevanagari(color: Colors.grey[600]),
        hintStyle: GoogleFonts.notoSansDevanagari(color: Colors.grey[400]),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: surfaceLight,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: backgroundLight,
        selectedColor: primaryGreen.withValues(alpha: 0.1),
        labelStyle: GoogleFonts.notoSansDevanagari(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: Color(0xFFC8E6C9)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceLight,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey[500],
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.notoSansDevanagari(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.notoSansDevanagari(fontSize: 12),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryLightGreen,
        brightness: Brightness.dark,
        primary: primaryLightGreen,
        secondary: accentOrange,
        error: accentRed,
        surface: surfaceDark,
        background: backgroundDark,
      ),
      textTheme: GoogleFonts.notoSansDevanagariTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineLarge: GoogleFonts.notoSansDevanagari(fontSize: 32, fontWeight: FontWeight.bold, color: primaryLightGreen),
        headlineMedium: GoogleFonts.notoSansDevanagari(fontSize: 24, fontWeight: FontWeight.w600, color: primaryLightGreen),
        headlineSmall: GoogleFonts.notoSansDevanagari(fontSize: 20, fontWeight: FontWeight.w600, color: primaryLightGreen),
        titleLarge: GoogleFonts.notoSansDevanagari(fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.notoSansDevanagari(fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.notoSansDevanagari(fontSize: 16),
        bodyMedium: GoogleFonts.notoSansDevanagari(fontSize: 14),
        labelLarge: GoogleFonts.notoSansDevanagari(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.notoSansDevanagari(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLightGreen,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.notoSansDevanagari(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF333333),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF444444)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLightGreen, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: surfaceDark,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}