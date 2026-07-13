import 'package:flutter/material.dart';

/// Configuração do Tema Visual Premium do aplicativo Open Home.
/// 
/// Baseia-se no Material 3 com estilo Dark OLED-friendly, cantos arredondados
/// acentuados, sliders espessos modernos (estilo iOS/Apple HomeKit) e
/// gradientes vibrantes para estados ativos.
class AppTheme {
  // Cores de Fundo e Superfícies
  static const Color darkBg = Color(0xFF08080C);           // Preto profundo (OLED)
  static const Color darkSurface = Color(0xFF14141A);      // Superfície Charcoal sutil
  static const Color inactiveCard = Color(0xFF1C1C24);     // Cartão inativo (Grafite sofisticado)
  
  // Destaques e Alertas
  static const Color accentIndigo = Color(0xFF6366F1);     // Indigo ativo
  static const Color accentCyan = Color(0xFF22D3EE);       // Cyan ativo
  static const Color warningAmber = Color(0xFFF59E0B);     // Alerta Amber
  
  // Cores de Texto
  static const Color textPrimary = Color(0xFFF8FAFC);      // Branco contraste total
  static const Color textSecondary = Color(0x99FFFFFF);    // Branco translúcido (Opacidade sutil)
  static const Color textMuted = Color(0x66FFFFFF);        // Texto muito sutil

  /// Gradiente premium utilizado para representar dispositivos ligados.
  static const LinearGradient activeGradient = LinearGradient(
    colors: [accentIndigo, Color(0xFF4F46E5), accentCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Retorna o ThemeData configurado para o estilo escuro premium.
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
        color: inactiveCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.white10, width: 0.5),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: textPrimary,
          letterSpacing: -0.8,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.4,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.2,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          color: textSecondary,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: textMuted,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return accentIndigo.withOpacity(0.2);
            }
            return darkSurface;
          }),
          foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return accentCyan;
            }
            return textSecondary;
          }),
          side: MaterialStateProperty.all(
            const BorderSide(color: Colors.white10, width: 0.5),
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
      ),
      // Slider Estilo iOS/HomeKit (Trilho espesso, controle redondo branco e sem divisores pesados)
      sliderTheme: const SliderThemeData(
        activeTrackColor: Colors.white,
        inactiveTrackColor: Colors.white12,
        thumbColor: Colors.white,
        trackHeight: 14,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 9, elevation: 2),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
        trackShape: RoundedRectSliderTrackShape(),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.white;
          }
          return textSecondary;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return accentCyan.withOpacity(0.8);
          }
          return Colors.white12;
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0C0C12),
        selectedItemColor: accentCyan,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
