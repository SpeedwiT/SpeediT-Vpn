import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Small brand mark matching the app icon: a dark rounded tile with a white
/// lightning bolt and a slow diagonal shimmer sweep (alive, but understated).
class BrandMark extends StatefulWidget {
  final double size;
  const BrandMark({super.key, this.size = 42});
  @override
  State<BrandMark> createState() => _BrandMarkState();
}

class _BrandMarkState extends State<BrandMark> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final s = widget.size;
    // tile background: near-black in both themes (matches the launcher icon)
    final tile = c.isDark ? const Color(0xFF151517) : const Color(0xFF0E0E10);
    return RepaintBoundary(
      child: Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          color: tile,
          borderRadius: BorderRadius.circular(s * 0.3),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.bolt, color: Colors.white, size: s * 0.6),
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final x = (_c.value * 2 - 1) * s; // sweep from left to right
                return Transform.translate(
                  offset: Offset(x, 0),
                  child: Transform.rotate(
                    angle: 0.5,
                    child: Container(
                      width: s * 0.3,
                      height: s * 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0),
                            Colors.white.withValues(alpha: 0.18),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
