import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';

class CustomerStatisticsSection extends StatelessWidget {
  final int totalCustomers;
  final int activeCustomers;
  final int inactiveCustomers;
  final int todaysDeliveries;
  final double totalPendingDues;

  const CustomerStatisticsSection({
    super.key,
    required this.totalCustomers,
    required this.activeCustomers,
    required this.inactiveCustomers,
    required this.todaysDeliveries,
    required this.totalPendingDues,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatCard(
              title: 'Total Customers',
              value: '$totalCustomers',
              icon: Icons.people_alt_rounded,
              color: AppColors.primaryDark,
              backgroundColor: AppColors.primaryLight,
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              title: 'Active',
              value: '$activeCustomers',
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
              backgroundColor: AppColors.successLight,
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              title: 'Inactive',
              value: '$inactiveCustomers',
              icon: Icons.pause_circle_filled_rounded,
              color: AppColors.textSecondary,
              backgroundColor: AppColors.surfaceSubtle,
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              title: "Today's Deliveries",
              value: '$todaysDeliveries',
              icon: Icons.local_shipping_rounded,
              color: AppColors.info,
              backgroundColor: AppColors.infoLight,
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              title: 'Pending Dues',
              value: AppFormatters.formatCompactCurrency(totalPendingDues),
              icon: Icons.account_balance_wallet_rounded,
              color: AppColors.error,
              backgroundColor: AppColors.errorLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
