import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Vibrant modern color palette
  static const Color primaryColor = Color(0xFF5E35B1); // Deep purple
  static const Color secondaryColor = Color(0xFFFF5252); // Vibrant red
  static const Color accentColor = Color(0xFF00BCD4); // Cyan
  static const Color tertiaryColor = Color(0xFFFFB300); // Amber

  // Background colors - modern and clean
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color darkBackground = Color(0xFF121212);

  // Text colors - high contrast for readability
  static const Color lightTextColor = Color(0xFF212121); // Almost black
  static const Color darkTextColor = Color(0xFFF5F5F7); // Almost white
  static const Color subtitleTextColor = Color(0xFF757575); // Medium gray

  // Card colors - subtle elevation with modern feel
  static const Color cardLightColor = Color(0xFFFFFFFF);
  static const Color cardDarkColor = Color(0xFF1E1E1E);
  static const Color cardShadowColor = Color(0xFFEEEEEE);

  // Error and success colors
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF43A047);

  // Light theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      background: lightBackground,
      error: errorColor,
      surface: cardLightColor,
    ),
    scaffoldBackgroundColor: lightBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: lightTextColor,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: lightTextColor,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: lightTextColor,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: lightTextColor,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: lightTextColor,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        color: lightTextColor,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        color: lightTextColor,
      ),
    ),
    cardTheme: CardTheme(
      color: cardLightColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: cardShadowColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: subtitleTextColor.withOpacity(0.3), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: subtitleTextColor.withOpacity(0.3), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      hintStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: subtitleTextColor,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: cardLightColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: subtitleTextColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: primaryColor.withOpacity(0.1),
      selectedColor: primaryColor,
      disabledColor: Colors.grey.withOpacity(0.1),
      labelStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: primaryColor,
      ),
      secondaryLabelStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFEEEEEE),
      thickness: 1,
      space: 1,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: secondaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  // Dark theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      background: darkBackground,
      error: errorColor,
      surface: cardDarkColor,
    ),
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: cardDarkColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: darkTextColor,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: darkTextColor,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: darkTextColor,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: darkTextColor,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: darkTextColor,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        color: darkTextColor,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        color: darkTextColor,
      ),
    ),
    cardTheme: CardTheme(
      color: cardDarkColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.black.withOpacity(0.3),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      hintStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.grey[400],
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: cardDarkColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: primaryColor.withOpacity(0.2),
      selectedColor: primaryColor,
      disabledColor: Colors.grey.withOpacity(0.2),
      labelStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: primaryColor,
      ),
      secondaryLabelStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF333333),
      thickness: 1,
      space: 1,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: secondaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
