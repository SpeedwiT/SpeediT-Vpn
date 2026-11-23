import 'package:flutter/material.dart';
import 'app_colors.dart';

/// V2hype theme — a clean black & white design system with depth and motion.
class AppTheme {
  static ThemeData dark() => _build(const AppColors(Brightness.dark));
  static ThemeData light() => _build(const AppColors(Brightness.light));

  static ThemeData _build(AppColors c) {
    final scheme = ColorScheme.fromSeed(
      seedColor: c.isDark ? Colors.white : Colors.black,
      brightness: c.brightness,
    ).copyWith(
      surface: c.surface,
      primary: c.accent,
      onPrimary: c.onAccent,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      fontFamily: 'Estedad',
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: c.text,
        titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: c.text, letterSpacing: -0.5),
      ),
      textTheme: Typography.material2021(platform: TargetPlatform.android)
          .black
          .apply(bodyColor: c.text, displayColor: c.text),
      iconTheme: IconThemeData(color: c.text),
      dividerColor: c.line,
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: c.surface,
        elevation: 0,
        indicatorColor: c.accent.withValues(alpha: c.isDark ? 0.16 : 0.10),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: c.text),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? c.accent : c.textDim),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.accent, width: 1.4),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.isDark ? const Color(0xFF1E1E22) : const Color(0xFF111113),
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.onAccent,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
