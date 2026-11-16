import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/vpn/vpn_engine.dart';
import '../theme/app_colors.dart';

/// A 3D glossy sphere with tilted orbiting rings — the hero connect control.
class ConnectOrb extends StatefulWidget {
  final ConnStatus status;
  final VoidCallback onTap;
  const ConnectOrb({super.key, required this.status, required this.onTap});

  @override
  State<ConnectOrb> createState() => _ConnectOrbState();
}

class _ConnectOrbState extends State<ConnectOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  double _press = 1.0;

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
      onTapDown: (_) => setState(() => _press = 0.95),
      onTapUp: (_) => setState(() => _press = 1.0),
      onTapCancel: () => setState(() => _press = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _press,
        duration: const Duration(milliseconds: 140),
        child: SizedBox(
          width: 280,
          height: 280,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = _c.value;
              final breathe = active ? 1 + math.sin(t * 2 * math.pi) * 0.015 : 1.0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // orbiting tilted rings (3D gyro)
                  CustomPaint(
                    size: const Size(280, 280),
                    painter: _OrbitPainter(
                      t: t,
                      color: c.accent,
                      intensity: active ? 1.0 : 0.5,
                      spin: connecting ? 2.2 : 1.0,
                    ),
                  ),
                  // soft glow when active
                  if (active)
                    Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: c.accent.withValues(alpha: c.isDark ? 0.22 : 0.16),
                            blurRadius: 48,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  // glossy 3D sphere
                  Transform.scale(
                    scale: breathe,
                    child: Container(
                      width: 168,
                      height: 168,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: c.sphere,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: c.isDark ? 0.6 : 0.28),
                            blurRadius: 30,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // top specular highlight
                          Align(
                            alignment: const Alignment(-0.4, -0.55),
                            child: Container(
                              width: 60,
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: c.isDark ? 0.9 : 0.35),
                                    Colors.white.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: connecting ? t : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              connecting ? Icons.sync : Icons.power_settings_new_rounded,
                              size: 64,
                              color: c.onAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
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
      (r: 132.0, tilt: 0.0, flat: 0.34, speed: 1.0, a: 0.5),
      (r: 120.0, tilt: math.pi / 3, flat: 0.30, speed: -1.4, a: 0.38),
      (r: 108.0, tilt: -math.pi / 3, flat: 0.40, speed: 1.8, a: 0.28),
    ];
    for (final ring in rings) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(ring.tilt + t * 2 * math.pi * ring.speed * spin);
      canvas.scale(1.0, ring.flat);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = color.withValues(alpha: ring.a * intensity);
      canvas.drawCircle(Offset.zero, ring.r, paint);
      // a travelling node on the ring for a lively 3D feel
      final double nodeAlpha = (ring.a + 0.3 > 1.0 ? 1.0 : ring.a + 0.3) * intensity;
      final node = Paint()..color = color.withValues(alpha: nodeAlpha);
      canvas.drawCircle(Offset(ring.r, 0), 4.5, node);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) =>
      old.t != t || old.intensity != intensity || old.spin != spin || old.color != color;
}
