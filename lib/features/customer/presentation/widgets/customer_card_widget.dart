import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/customer_model.dart';
import '../../../../models/delivery_model.dart';

class CustomerCardWidget extends StatelessWidget {
  final CustomerModel customer;
  final DeliveryModel? lastDelivery;
  final VoidCallback onTapCard;

  const CustomerCardWidget({
    super.key,
    required this.customer,
    this.lastDelivery,
    required this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: customer.isActive ? Colors.grey.shade200 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTapCard,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Auto height
                    children: [
                      // ── ROW 1: Avatar, Customer Name (auto wrap), Status Badge ─────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Hero(
                            tag: 'customer_avatar_${customer.id}',
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: customer.isActive
                                  ? AppColors.primaryLight
                                  : Colors.grey.shade200,
                              child: Text(
                                customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: customer.isActive ? AppColors.primaryDark : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ID: ${customer.id}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: customer.isActive ? AppColors.successLight : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: customer.isActive
                                    ? AppColors.success.withValues(alpha: 0.4)
                                    : Colors.grey.shade400,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: customer.isActive ? AppColors.success : Colors.grey.shade600,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  customer.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: customer.isActive ? AppColors.success : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // ── ROW 2: Full Mobile Number (NEVER truncated) ─────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone_android_rounded, size: 15, color: AppColors.primary),
                          const SizedBox(width: 6),
                          SelectableText(
                            customer.phone,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.2,
                            ),
                          ),
                          if (customer.whatsappNumber.isNotEmpty &&
                              customer.whatsappNumber != customer.phone) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F9F0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'WA: ${customer.whatsappNumber}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF25D366),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      // ── ROW 3: Location ─────────────────────────────────────────────
                      if (customer.address.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                customer.address,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),

                      // ── ROW 4 & 5: Water Can Balance, Pending Due, Last Delivery ───
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildMetricChip(
                            icon: Icons.water_drop_rounded,
                            label: '${customer.canBalance} Cans',
                            color: AppColors.primaryDark,
                            backgroundColor: AppColors.primaryLight,
                          ),
                          if (customer.emptyCansPending > 0)
                            _buildMetricChip(
                              icon: Icons.remove_shopping_cart_rounded,
                              label: '${customer.emptyCansPending} Empty Due',
                              color: Colors.orange.shade900,
                              backgroundColor: Colors.orange.shade50,
                            ),
                          if (customer.pendingDues > 0)
                            _buildMetricChip(
                              icon: Icons.warning_amber_rounded,
                              label: 'Dues: ${AppFormatters.formatCompactCurrency(customer.pendingDues)}',
                              color: AppColors.error,
                              backgroundColor: AppColors.errorLight,
                            ),
                          _buildMetricChip(
                            icon: Icons.calendar_today_rounded,
                            label: lastDelivery != null
                                ? 'Last: ${AppFormatters.formatDate(lastDelivery!.deliveryDate)}'
                                : 'No Deliveries',
                            color: AppColors.textSecondary,
                            backgroundColor: AppColors.surfaceSubtle,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // ── Chevron Arrow (Tap Indicator) ──────────────────────────────
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.04);
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
