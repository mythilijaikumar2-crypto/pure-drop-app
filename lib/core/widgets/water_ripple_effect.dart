import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class WaterRippleEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const WaterRippleEffect({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<WaterRippleEffect> createState() => _WaterRippleEffectState();
}

class _WaterRippleEffectState extends State<WaterRippleEffect> with TickerProviderStateMixin {
  final List<_RippleAnimation> _ripples = [];

  void _addRipple(TapDownDetails details) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final ripple = _RippleAnimation(
      position: details.localPosition,
      controller: controller,
    );

    setState(() {
      _ripples.add(ripple);
    });

    controller.forward().then((_) {
      if (mounted) {
        setState(() {
          _ripples.remove(ripple);
        });
      }
      controller.dispose();
    });
  }

  @override
  void dispose() {
    for (var r in _ripples) {
      r.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: _addRipple,
      onTap: widget.onTap,
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _WaterPainter(ripples: _ripples),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RippleAnimation {
  final Offset position;
  final AnimationController controller;

  _RippleAnimation({
    required this.position,
    required this.controller,
  });
}

class _WaterPainter extends CustomPainter {
  final List<_RippleAnimation> ripples;

  _WaterPainter({required this.ripples})
      : super(repaint: Listenable.merge(ripples.map((r) => r.controller).toList()));

  @override
  void paint(Canvas canvas, Size size) {
    for (var ripple in ripples) {
      final value = ripple.controller.value;
      final radius = value * 90.0;
      final opacity = (1.0 - value).clamp(0.0, 1.0);

      // Outer water ripple wave ring
      final ringPaint = Paint()
        ..color = AppColors.primary.withValues(alpha: opacity * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * (1.0 - value);

      // Inner water drop glow fill
      final fillPaint = Paint()
        ..color = AppColors.primaryLight.withValues(alpha: opacity * 0.25)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(ripple.position, radius, fillPaint);
      canvas.drawCircle(ripple.position, radius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaterPainter oldDelegate) => true;
}
