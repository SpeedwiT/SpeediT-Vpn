import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Frosted-glass, raised 3D panel used across the app.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final VoidCallback? onTap;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.radius = 22,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.glass,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: c.line),
              boxShadow: c.lift,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(radius),
                child: Padding(padding: padding, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Subtle animated monochrome backdrop — slow-drifting blurred blobs + grain.
class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});
  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final blob = c.isDark ? Colors.white : Colors.black;
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: c.bg)),
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            return Stack(children: [
              _blob(blob.withValues(alpha: c.isDark ? 0.06 : 0.05), 360,
                  Alignment(0.9 - t * 0.3, -0.9 + t * 0.2)),
              _blob(blob.withValues(alpha: c.isDark ? 0.05 : 0.04), 300,
                  Alignment(-0.9 + t * 0.4, 0.9 - t * 0.3)),
            ]);
          },
        ),
        Positioned.fill(child: widget.child),
      ],
    );
  }

  Widget _blob(Color color, double size, Alignment align) => Align(
        alignment: align,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
          ),
        ),
      );
}

/// One-shot entrance: fades + slides up, with an optional stagger [delayMs].
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final double offsetY;
  const FadeSlideIn({super.key, required this.child, this.delayMs = 0, this.offsetY = 24});
  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final Animation<double> _a =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (context, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(offset: Offset(0, (1 - _a.value) * widget.offsetY), child: child),
      ),
      child: widget.child,
    );
  }
}

/// Smooth fade+scale route transition for a premium feel.
class FadeScaleRoute<T> extends PageRouteBuilder<T> {
  FadeScaleRoute(Widget page)
      : super(
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, anim, __, child) {
            final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: Transform.scale(
                scale: 0.98 + curved.value * 0.02,
                child: child,
              ),
            );
          },
        );
}
