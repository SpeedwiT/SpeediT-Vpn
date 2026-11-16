import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A small, "live" brand mark: a glossy rounded tile with a lightning bolt and a
/// thin orbiting arc that rotates continuously. Cheap (RepaintBoundary + one arc).
class BrandMark extends StatefulWidget {
  final double size;
  const BrandMark({super.key, this.size = 40});
  @override
  State<BrandMark> createState() => _BrandMarkState();
}

class _BrandMarkState extends State<BrandMark> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final s = widget.size;
    return RepaintBoundary(
      child: SizedBox(
        width: s,
        height: s,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // glossy tile
            Container(
              width: s * 0.82,
              height: s * 0.82,
              decoration: BoxDecoration(
                gradient: c.orbGradient,
                borderRadius: BorderRadius.circular(s * 0.28),
                boxShadow: [
                  BoxShadow(color: c.accent.withValues(alpha: c.isDark ? 0.25 : 0.18), blurRadius: 12),
                ],
              ),
              child: Icon(Icons.bolt, color: c.onAccent, size: s * 0.5),
            ),
            // orbiting arc
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) => CustomPaint(
                size: Size(s, s),
                painter: _ArcPainter(_c.value, c.accent.withValues(alpha: c.isDark ? 0.9 : 0.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double t;
  final Color color;
  _ArcPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2 - 1.5,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4
      ..color = color;
    final start = t * 2 * math.pi;
    canvas.drawArc(rect, start, math.pi * 0.5, false, paint);
    canvas.drawArc(rect, start + math.pi, math.pi * 0.3, false, paint);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.t != t || old.color != color;
}
