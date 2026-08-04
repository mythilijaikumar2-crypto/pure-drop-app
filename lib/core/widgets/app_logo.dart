import 'package:flutter/material.dart';

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
    return Image.asset(
      'assets/logo.png',
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.water_drop_rounded,
          size: size * 0.6,
          color: const Color(0xFF1DAEFF),
        );
      },
    );
  }
}
