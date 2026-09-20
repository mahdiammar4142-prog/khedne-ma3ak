import 'package:flutter/material.dart';

/// Bright theme colors matching the main home screen.
class AppTheme {
  static const Color primary = Color(0xFF00A651); // Teal / cedar green
  static const Color primaryDark = Color(0xFF008C44);
  static const Color secondary = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFF2196F3);  // Blue
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentCyan = Color(0xFF00BCD4);
  static const Color accentYellow = Color(0xFFFFC107);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: accent,
          surface: Colors.white,
          surfaceContainerHighest: const Color(0xFFF5F5F5),
          onSurface: Colors.black,
          onSurfaceVariant: Colors.black87,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey.shade800,
          iconTheme: IconThemeData(color: Colors.grey.shade800),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade900,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          hintStyle: TextStyle(color: Colors.grey.shade600),
          labelStyle: const TextStyle(color: Colors.black87),
          floatingLabelStyle: const TextStyle(color: Colors.black87),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            elevation: 0,
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: const BorderSide(color: primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: primary.withOpacity(0.12),
          selectedColor: primary.withOpacity(0.25),
          labelStyle: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        listTileTheme: ListTileThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          titleTextStyle: const TextStyle(color: Colors.black87),
          subtitleTextStyle: const TextStyle(color: Colors.black54),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
          titleTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          contentTextStyle: TextStyle(color: Colors.black),
        ),
        textTheme: _textTheme,
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: accent,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        textTheme: _textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
      );

  static TextTheme get _textTheme => const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5, color: Colors.black87),
        headlineSmall: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        titleLarge: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        bodyLarge: TextStyle(height: 1.4, color: Colors.black),
        bodyMedium: TextStyle(color: Colors.black),
        bodySmall: TextStyle(color: Colors.black87),
        labelLarge: TextStyle(color: Colors.black87),
      );
}
