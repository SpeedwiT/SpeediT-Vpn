import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/vpn/vpn_engine.dart';
import '../theme/app_colors.dart';

/// A 3D glossy sphere with tilted orbiting rings — the hero connect control.
/// Optimised for smoothness: the heavy sphere/shadow/glow are static; only the
/// light-weight ring layer repaints (inside its own RepaintBoundary).
class ConnectOrb extends StatefulWidget {
  final ConnStatus status;
  final VoidCallback onTap;
  const ConnectOrb({super.key, required this.status, required this.onTap});

  @override
  State<ConnectOrb> createState() => _ConnectOrbState();
}

class _ConnectOrbState extends State<ConnectOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 10));
  double _press = 1.0;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant ConnectOrb old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) _sync();
  }

  // Animate only while active; stay perfectly still (no repaints) when idle.
  void _sync() {
    if (widget.status == ConnStatus.disconnected) {
      if (_c.isAnimating) _c.stop();
    } else {
      if (!_c.isAnimating) _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final active = widget.status != ConnStatus.disconnected;
    final connecting = widget.status == ConnStatus.connecting;

    return GestureDetector(
      onTapDown: (_) => setState(() => _press = 0.96),
      onTapUp: (_) => setState(() => _press = 1.0),
      onTapCancel: () => setState(() => _press = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _press,
        duration: const Duration(milliseconds: 140),
        child: RepaintBoundary(
          child: SizedBox(
            width: 272,
            height: 272,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // soft glow (fades on state change only — not per frame)
                AnimatedOpacity(
                  opacity: active ? 1 : 0,
                  duration: const Duration(milliseconds: 350),
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: c.accent.withValues(alpha: c.isDark ? 0.20 : 0.14),
                          blurRadius: 44,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
                // orbiting rings — the only continuously-animating layer
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (context, _) => CustomPaint(
                      size: const Size(272, 272),
                      painter: _OrbitPainter(
                        t: _c.value,
                        color: c.accent,
                        intensity: active ? 1.0 : 0.5,
                        spin: connecting ? 2.2 : 1.0,
                      ),
                    ),
                  ),
                ),
                // static glossy 3D sphere
                _Sphere(c: c, connecting: connecting, controller: _c),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Sphere extends StatelessWidget {
  final AppColors c;
  final bool connecting;
  final AnimationController controller;
  const _Sphere({required this.c, required this.connecting, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 166,
      height: 166,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: c.sphere,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.isDark ? 0.55 : 0.26),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: const Alignment(-0.4, -0.55),
            child: Container(
              width: 58,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: LinearGradient(colors: [
                  Colors.white.withValues(alpha: c.isDark ? 0.85 : 0.33),
                  Colors.white.withValues(alpha: 0),
                ]),
              ),
            ),
          ),
          connecting
              ? RotationTransition(
                  turns: controller,
                  child: Icon(Icons.sync_rounded, size: 62, color: c.onAccent),
                )
              : Icon(Icons.power_settings_new_rounded, size: 62, color: c.onAccent),
        ],
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  final double t;
  final Color color;
  final double intensity;
  final double spin;
  _OrbitPainter({required this.t, required this.color, required this.intensity, required this.spin});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rings = [
      (r: 128.0, tilt: 0.0, flat: 0.34, speed: 1.0, a: 0.5),
      (r: 116.0, tilt: math.pi / 3, flat: 0.30, speed: -1.4, a: 0.38),
      (r: 104.0, tilt: -math.pi / 3, flat: 0.40, speed: 1.8, a: 0.28),
    ];
    for (final ring in rings) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(ring.tilt + t * 2 * math.pi * ring.speed * spin);
      canvas.scale(1.0, ring.flat);
      canvas.drawCircle(
        Offset.zero,
        ring.r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = color.withValues(alpha: ring.a * intensity),
      );
      final double nodeAlpha = (ring.a + 0.3 > 1.0 ? 1.0 : ring.a + 0.3) * intensity;
      canvas.drawCircle(Offset(ring.r, 0), 4.5, Paint()..color = color.withValues(alpha: nodeAlpha));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) =>
      old.t != t || old.intensity != intensity || old.spin != spin || old.color != color;
}
