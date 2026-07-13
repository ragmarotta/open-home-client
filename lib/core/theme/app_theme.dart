import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors
  static const Color darkBg = Color(0xFF0A0C14);      // Slate Black (OLED-friendly)
  static const Color darkSurface = Color(0xFF141824); // Charcoal Surface
  static const Color accentIndigo = Color(0xFF6366F1); // Indigo active accent
  static const Color accentCyan = Color(0xFF22D3EE);   // Cyan accent
  static const Color warningAmber = Color(0xFFF59E0B); // Amber warning accent
  
  static const Color textPrimary = Color(0xFFF8FAFC);  // High contrast white
  static const Color textSecondary = Color(0xFF94A3B8); // Slate grey

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: accentIndigo,
      colorScheme: const ColorScheme.dark(
        primary: accentIndigo,
        secondary: accentCyan,
        surface: darkSurface,
        background: darkBg,
        error: warningAmber,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF202638), width: 1),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textSecondary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondary,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return accentIndigo;
            }
            return darkSurface;
          }),
          foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.white;
            }
            return textSecondary;
          }),
          side: MaterialStateProperty.all(
            const BorderSide(color: Color(0xFF202638), width: 1),
          ),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: accentCyan,
        inactiveTrackColor: Color(0xFF202638),
        thumbColor: accentCyan,
        overlayColor: Color(0x2922D3EE),
        trackHeight: 6,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return accentCyan;
          }
          return textSecondary;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return accentCyan.withOpacity(0.4);
          }
          return const Color(0xFF202638);
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: accentCyan,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
