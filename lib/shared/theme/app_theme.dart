// lib/shared/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── Couleurs CATUSNIS ─────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1a56db);
  static const Color success = Color(0xFF057a55);
  static const Color warning = Color(0xFFc27803);
  static const Color danger = Color(0xFFc81e1e);
  static const Color info = Color(0xFF0694a2);
  static const Color dark = Color(0xFF111827);
  static const Color gray = Color(0xFF6b7280);
  static const Color lightBg = Color(0xFFf3f4f6);
  static const Color white = Color(0xFFFFFFFF);

  // ── Police système avec support UTF-8 complet ─────────────────────────────
  static const String _fontFamily = 'Roboto';

  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(fontFamily: _fontFamily),
    displayMedium: TextStyle(fontFamily: _fontFamily),
    displaySmall: TextStyle(fontFamily: _fontFamily),
    headlineLarge: TextStyle(fontFamily: _fontFamily),
    headlineMedium: TextStyle(fontFamily: _fontFamily),
    headlineSmall: TextStyle(fontFamily: _fontFamily),
    titleLarge: TextStyle(fontFamily: _fontFamily),
    titleMedium: TextStyle(fontFamily: _fontFamily),
    titleSmall: TextStyle(fontFamily: _fontFamily),
    bodyLarge: TextStyle(fontFamily: _fontFamily),
    bodyMedium: TextStyle(fontFamily: _fontFamily),
    bodySmall: TextStyle(fontFamily: _fontFamily),
    labelLarge: TextStyle(fontFamily: _fontFamily),
    labelMedium: TextStyle(fontFamily: _fontFamily),
    labelSmall: TextStyle(fontFamily: _fontFamily),
  );

  // ── Thème principal ───────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: _fontFamily,
        textTheme: _textTheme,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: info,
          error: danger,
        ),
        scaffoldBackgroundColor: lightBg,

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: white,
          foregroundColor: dark,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: _fontFamily,
            color: dark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Boutons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontFamily: _fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Champs texte
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFd1d5db)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFd1d5db)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: danger),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          labelStyle: const TextStyle(
            fontFamily: _fontFamily,
            color: gray,
          ),
        ),

        cardTheme: CardThemeData(
          color: white,
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
}
