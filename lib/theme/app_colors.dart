import 'package:flutter/material.dart';

/// Monochrome (black & white) palette resolved from the current brightness.
/// Pure, high-contrast, premium — no coloured accents.
class AppColors {
  final Brightness brightness;
  const AppColors(this.brightness);

  static AppColors of(BuildContext context) =>
      AppColors(Theme.of(context).brightness);

  bool get isDark => brightness == Brightness.dark;

  // backgrounds
  Color get bg => isDark ? const Color(0xFF060606) : const Color(0xFFF4F4F5);
  Color get bg2 => isDark ? const Color(0xFF101011) : const Color(0xFFFFFFFF);
  Color get surface => isDark ? const Color(0xFF161618) : const Color(0xFFFFFFFF);
  Color get surfaceHi => isDark ? const Color(0xFF1F1F22) : const Color(0xFFFFFFFF);

  // ink
  Color get text => isDark ? const Color(0xFFF7F7F8) : const Color(0xFF0A0A0B);
  Color get textDim => isDark ? const Color(0xFF9A9AA2) : const Color(0xFF6A6A72);
  Color get accent => isDark ? Colors.white : Colors.black; // monochrome accent
  Color get onAccent => isDark ? Colors.black : Colors.white;

  Color get line => isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08);

  /// Glassy fill for cards / panels.
  Color get glass => isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.72);

  /// Soft 3D shadow stack for raised surfaces (neumorphic depth).
  List<BoxShadow> get lift => isDark
      ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 26, offset: const Offset(0, 14)),
          BoxShadow(color: Colors.white.withValues(alpha: 0.04), blurRadius: 1, offset: const Offset(0, -1)),
        ]
      : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 26, offset: const Offset(0, 16)),
          BoxShadow(color: Colors.white.withValues(alpha: 0.9), blurRadius: 10, offset: const Offset(0, -6)),
        ];

  /// Gradient used for the 3D orb / brand marks (monochrome sphere highlight).
  LinearGradient get orbGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [const Color(0xFFFFFFFF), const Color(0xFFBFBFC6), const Color(0xFF6E6E77)]
            : [const Color(0xFF2A2A2E), const Color(0xFF0C0C0E), const Color(0xFF000000)],
      );

  RadialGradient get sphere => RadialGradient(
        center: const Alignment(-0.35, -0.4),
        radius: 1.1,
        colors: isDark
            ? [const Color(0xFFFFFFFF), const Color(0xFFCDCDD4), const Color(0xFF55555E)]
            : [const Color(0xFF3A3A40), const Color(0xFF131316), const Color(0xFF000000)],
        stops: const [0.0, 0.45, 1.0],
      );
}
