import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../constants/app_enums.dart';

class StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status) {
      case OrderStatus.pending:
        bg = AppColors.warningLight;
        fg = AppColors.warning;
        break;
      case OrderStatus.assigned:
        bg = AppColors.infoLight;
        fg = AppColors.info;
        break;
      case OrderStatus.inTransit:
        bg = const Color(0xFFEDE9FE);
        fg = const Color(0xFF7C3AED);
        break;
      case OrderStatus.delivered:
        bg = AppColors.successLight;
        fg = AppColors.success;
        break;
      case OrderStatus.cancelled:
        bg = AppColors.errorLight;
        fg = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ).animate().scale(duration: 250.ms, curve: Curves.easeOutBack).fadeIn();
  }
}

class PaymentStatusBadge extends StatelessWidget {
  final PaymentStatus status;

  const PaymentStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status) {
      case PaymentStatus.paid:
        bg = AppColors.successLight;
        fg = AppColors.success;
        break;
      case PaymentStatus.pending:
        bg = AppColors.errorLight;
        fg = AppColors.error;
        break;
      case PaymentStatus.partiallyPaid:
        bg = AppColors.warningLight;
        fg = AppColors.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ).animate().scale(duration: 250.ms, curve: Curves.easeOutBack).fadeIn();
  }
}
