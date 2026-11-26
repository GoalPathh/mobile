import 'package:flutter/material.dart';

class AppTheme {
  static const _violet = Color(0xFF6335D8);
  static const _darkViolet = Color(0xFF7350FF);

  static ThemeData get light => _build(
    brightness: Brightness.light,
    primary: _violet,
    background: const Color(0xFFF8F6FF),
    surface: Colors.white,
    foreground: const Color(0xFF141224),
    border: const Color(0xFFDCD5EB),
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    primary: _darkViolet,
    background: const Color(0xFF0A0A0E),
    surface: const Color(0xFF12121A),
    foreground: const Color(0xFFF8F5FF),
    border: const Color(0xFF34344A),
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required Color background,
    required Color surface,
    required Color foreground,
    required Color border,
  }) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: brightness,
        ).copyWith(
          primary: primary,
          onPrimary: Colors.white,
          surface: surface,
          onSurface: foreground,
          outline: border,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        centerTitle: false,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      dividerColor: border,
    );
  }
}
