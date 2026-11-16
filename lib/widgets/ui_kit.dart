import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Raised 3D panel with a translucent "glass" look — WITHOUT a runtime blur.
/// (BackdropFilter blur is very GPU-heavy, especially in lists; a translucent
/// fill + border + soft shadow gives the same look while staying perfectly smooth.)
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
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: c.line),
              boxShadow: c.lift,
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// Static, cheap monochrome backdrop — two soft radial blobs, no animation,
/// so every screen stays smooth. (Repainting a full-screen gradient each frame
/// was the main source of jank.)
class AnimatedBackground extends StatelessWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final blob = (c.isDark ? Colors.white : Colors.black);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.85, -0.85),
          radius: 1.2,
          colors: [blob.withValues(alpha: c.isDark ? 0.05 : 0.04), c.bg],
          stops: const [0.0, 0.7],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.9, 0.9),
            radius: 1.1,
            colors: [blob.withValues(alpha: c.isDark ? 0.04 : 0.03), Colors.transparent],
            stops: const [0.0, 0.6],
          ),
        ),
        child: child,
      ),
    );
  }
}

/// One-shot entrance: fades + slides up, with an optional stagger [delayMs].
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final double offsetY;
  const FadeSlideIn({super.key, required this.child, this.delayMs = 0, this.offsetY = 20});
  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

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
    return FadeTransition(
      opacity: _a,
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset(0, widget.offsetY / 100), end: Offset.zero).animate(_a),
        child: widget.child,
      ),
    );
  }
}

/// Smooth fade+scale route transition for a premium feel.
class FadeScaleRoute<T> extends PageRouteBuilder<T> {
  FadeScaleRoute(Widget page)
      : super(
          transitionDuration: const Duration(milliseconds: 360),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, anim, __, child) {
            final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: Transform.scale(scale: 0.98 + curved.value * 0.02, child: child),
            );
          },
        );
}
