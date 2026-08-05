import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class CustomerActionButtons extends StatelessWidget {
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onMap;
  final VoidCallback onViewProfile;
  final VoidCallback onCreateOrder;
  final VoidCallback onCollectPayment;
  final VoidCallback onViewHistory;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isAdmin;

  const CustomerActionButtons({
    super.key,
    required this.onCall,
    required this.onWhatsApp,
    required this.onMap,
    required this.onViewProfile,
    required this.onCreateOrder,
    required this.onCollectPayment,
    required this.onViewHistory,
    this.onEdit,
    this.onDelete,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.phone_rounded,
          color: AppColors.success,
          backgroundColor: AppColors.successLight,
          tooltip: 'Call Customer',
          onTap: onCall,
        ),
        _buildActionButton(
          icon: Icons.chat_rounded,
          color: const Color(0xFF25D366),
          backgroundColor: const Color(0xFFE8F9F0),
          tooltip: 'WhatsApp',
          onTap: onWhatsApp,
        ),
        _buildActionButton(
          icon: Icons.location_on_rounded,
          color: AppColors.primaryDark,
          backgroundColor: AppColors.primaryLight,
          tooltip: 'Google Maps Location',
          onTap: onMap,
        ),
        _buildMoreOptionsMenu(context),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 22,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreOptionsMenu(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        cardColor: Colors.white,
        popupMenuTheme: PopupMenuThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
        ),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'More Options',
        offset: const Offset(0, 40),
        onSelected: (value) {
          switch (value) {
            case 'profile':
              onViewProfile();
              break;
            case 'create_order':
              onCreateOrder();
              break;
            case 'collect_payment':
              onCollectPayment();
              break;
            case 'history':
              onViewHistory();
              break;
            case 'edit':
              if (onEdit != null) onEdit!();
              break;
            case 'delete':
              if (onDelete != null) onDelete!();
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem<String>(
            value: 'profile',
            child: Row(
              children: [
                Icon(Icons.account_box_rounded, color: AppColors.primaryDark, size: 20),
                SizedBox(width: 12),
                Text('View Profile', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'create_order',
            child: Row(
              children: [
                Icon(Icons.add_shopping_cart_rounded, color: AppColors.primary, size: 20),
                SizedBox(width: 12),
                Text('Create Order', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'collect_payment',
            child: Row(
              children: [
                Icon(Icons.payments_rounded, color: AppColors.success, size: 20),
                SizedBox(width: 12),
                Text('Collect Payment', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'history',
            child: Row(
              children: [
                Icon(Icons.history_rounded, color: AppColors.info, size: 20),
                SizedBox(width: 12),
                Text('View History', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
          if (isAdmin && onEdit != null) ...[
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_rounded, color: AppColors.warning, size: 20),
                  SizedBox(width: 12),
                  Text('Edit Customer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
          ],
          if (isAdmin && onDelete != null) ...[
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_rounded, color: AppColors.error, size: 20),
                  SizedBox(width: 12),
                  Text('Delete Customer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.error)),
                ],
              ),
            ),
          ],
        ],
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.more_vert_rounded,
            size: 22,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
