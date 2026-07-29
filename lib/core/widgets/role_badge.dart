import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../constants/app_enums.dart';

class RoleBadge extends StatelessWidget {
  final UserRole role;

  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == UserRole.admin;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin ? AppColors.primaryLight : AppColors.infoLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAdmin ? AppColors.primary : AppColors.info,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.delivery_dining,
            size: 14,
            color: isAdmin ? AppColors.primaryDark : AppColors.info,
          ),
          const SizedBox(width: 4),
          Text(
            role.displayName,
            style: TextStyle(
              color: isAdmin ? AppColors.primaryDark : AppColors.info,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().scale(duration: 250.ms, curve: Curves.easeOutBack).fadeIn();
  }
}
