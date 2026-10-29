import 'package:flutter/material.dart';

/// Design system and theme tokens for Chess App.
/// Tournament-grade dark palette inspired by international chess platforms (Lichess & Chess.com).
class AppTheme {
  // Backgrounds & Surfaces
  static const Color background = Color(0xFF161512);
  static const Color surface = Color(0xFF21201D);
  static const Color surfaceVariant = Color(0xFF2A2824);
  static const Color surfaceCard = Color(0xFF262421);
  static const Color border = Color(0xFF383531);

  // Accents
  static const Color primaryGreen = Color(0xFF81B64C);
  static const Color primaryGreenDark = Color(0xFF629924);
  static const Color primaryGreenLight = Color(0xFFA3D169);
  static const Color accentAmber = Color(0xFFF0C15A);
  static const Color accentAmberDark = Color(0xFFE69D24);
  static const Color accentBlue = Color(0xFF4A90E2);
  static const Color accentPurple = Color(0xFF9B51E0);
  static const Color errorRed = Color(0xFFE05252);

  // Gradients for Hero Cards & Buttons
  static const LinearGradient greenGradient = LinearGradient(
    colors: [primaryGreen, primaryGreenDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [accentAmber, accentAmberDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF2C2A26), Color(0xFF21201D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Typography Colors
  static const Color textPrimary = Color(0xFFEDECE6);
  static const Color textSecondary = Color(0xFFB5B3A8);
  static const Color textMuted = Color(0xFF7C7971);

  // Chess Board Palette
  static const Color boardLight = Color(0xFFEEEED2);
  static const Color boardDark = Color(0xFF769656);
  static const Color boardSelected = Color(0xFFBBCB43);
  static const Color boardLastMove = Color(0xFFAAB838);
  static const Color boardInCheck = Color(0xFFEB6161);
  static const Color boardLegalDot = Color(0x3D000000);
  static const Color boardLegalRing = Color(0x40000000);

  // Piece Colors
  static const Color whitePieceFill = Color(0xFFFFFFFF);
  static const Color whitePieceGradient = Color(0xFFE8E7DF);
  static const Color whitePieceBorder = Color(0xFF4A4944);

  static const Color blackPieceFill = Color(0xFF2B2824);
  static const Color blackPieceGradient = Color(0xFF181715);
  static const Color blackPieceBorder = Color(0xFFE0DCD3);

  // Main Dark Theme Data
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        onPrimary: Colors.white,
        secondary: accentAmber,
        onSecondary: Colors.black,
        surface: surface,
        onSurface: textPrimary,
        error: errorRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 11,
        ),
      ),
    );
  }
}
