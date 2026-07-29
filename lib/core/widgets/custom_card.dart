import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class CustomCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final double? radius;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.border,
    this.boxShadow,
    this.radius,
  });

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(widget.radius ?? AppConstants.cardRadius);

    Widget content = Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.surface,
        borderRadius: borderRadius,
        border: widget.border ?? Border.all(color: Colors.grey.withValues(alpha: 0.12), width: 1),
        boxShadow: widget.boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isPressed ? 0.08 : 0.03),
                blurRadius: _isPressed ? 14 : 10,
                offset: _isPressed ? const Offset(0, 6) : const Offset(0, 4),
              ),
            ],
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      content = Listener(
        onPointerDown: (_) => setState(() => _isPressed = true),
        onPointerUp: (_) => setState(() => _isPressed = false),
        onPointerCancel: (_) => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: Material(
            color: Colors.transparent,
            borderRadius: borderRadius,
            child: InkWell(
              borderRadius: borderRadius,
              onTap: widget.onTap,
              child: content,
            ),
          ),
        ),
      );
    }

    return content;
  }
}
