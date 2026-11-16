import 'package:flutter/material.dart';

/// SpeediT brand theme — deep indigo + blue→violet accents. Distinct identity.
class AppTheme {
  static const brandBlue = Color(0xFF5B93FF);
  static const brandViolet = Color(0xFF9A57FF);
  static const brandCyan = Color(0xFF17C0C0);
  static const good = Color(0xFF36C98A);
  static const danger = Color(0xFFF0657A);

  static const _bgDark = Color(0xFF070B1C);
  static const _surfaceDark = Color(0xFF101737);
  static const _bgLight = Color(0xFFF3F5FC);
  static const _surfaceLight = Color(0xFFFFFFFF);

  static const gradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [brandBlue, brandViolet],
  );

  static ThemeData dark() => _base(Brightness.dark, _bgDark, _surfaceDark);
  static ThemeData light() => _base(Brightness.light, _bgLight, _surfaceLight);

  static ThemeData _base(Brightness b, Color bg, Color surface) {
    final scheme = ColorScheme.fromSeed(
      seedColor: brandBlue,
      brightness: b,
    ).copyWith(secondary: brandViolet, surface: surface);
    final onBg = b == Brightness.dark ? Colors.white : const Color(0xFF0C1230);
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      fontFamily: 'Vazirmatn',
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: onBg,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: onBg),
      ),
      cardTheme: CardTheme(
        color: surface.withValues(alpha: b == Brightness.dark ? 0.6 : 1),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: brandBlue.withValues(alpha: 0.16)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: brandBlue.withValues(alpha: 0.22),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: brandBlue.withValues(alpha: 0.2)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
