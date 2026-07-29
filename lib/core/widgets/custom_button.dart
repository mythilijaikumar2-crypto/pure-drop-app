import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.width,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final childWidget = widget.isLoading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    final style = widget.isOutlined
        ? OutlinedButton.styleFrom(
            side: BorderSide(color: widget.backgroundColor ?? AppColors.primary, width: 1.5),
            foregroundColor: widget.textColor ?? AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: widget.backgroundColor ?? AppColors.primary,
            foregroundColor: widget.textColor ?? Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          );

    final buttonWidget = widget.isOutlined
        ? OutlinedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: style,
            child: childWidget,
          )
        : ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: style,
            child: childWidget,
          );

    final content = AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      child: buttonWidget,
    );

    return Listener(
      onPointerDown: (_) => setState(() => _isPressed = true),
      onPointerUp: (_) => setState(() => _isPressed = false),
      onPointerCancel: (_) => setState(() => _isPressed = false),
      child: SizedBox(
        width: widget.width ?? double.infinity,
        height: 48,
        child: content,
      ),
    );
  }
}
