import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final BoxFit fit;

  const AppLogo({
    super.key,
    this.size = 120,
    this.showText = false,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/logo.png',
          width: size,
          height: size,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: size,
              height: size,
              padding: EdgeInsets.all(size * 0.2),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F7FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1DAEFF), width: 2),
              ),
              child: Icon(
                Icons.water_drop_rounded,
                size: size * 0.5,
                color: const Color(0xFF1DAEFF),
              ),
            );
          },
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
              begin: const Offset(0.97, 0.97),
              end: const Offset(1.03, 1.03),
              duration: 2000.ms,
              curve: Curves.easeInOut,
            ),
      ],
    );
  }
}
