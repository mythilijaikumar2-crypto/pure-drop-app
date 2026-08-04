import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class AnimatedCounterText extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final bool isCurrency;
  final Duration duration;

  const AnimatedCounterText({
    super.key,
    required this.value,
    this.style,
    this.isCurrency = false,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        final displayText = isCurrency
            ? AppFormatters.formatCompactCurrency(val)
            : val.toInt().toString();

        return Text(
          displayText,
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
