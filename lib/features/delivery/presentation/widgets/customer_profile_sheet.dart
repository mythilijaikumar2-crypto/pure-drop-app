import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/customer_model.dart';
import '../../../../models/delivery_model.dart';

class CustomerProfileSheet extends StatelessWidget {
  final CustomerModel? customer;
  final DeliveryModel delivery;

  const CustomerProfileSheet({
    super.key,
    required this.customer,
    required this.delivery,
  });

  void _callPhone(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openWhatsApp(String phone) async {
    if (phone.isEmpty) return;
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/91$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openMaps(String address) async {
    if (address.isEmpty) return;
    final encoded = Uri.encodeComponent(address);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pendingDues = customer?.pendingDues ?? delivery.totalAmount;
    final emptyPending = customer?.emptyCansPending ?? delivery.emptyCansCollected;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Profile Info
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    delivery.customerName.isNotEmpty ? delivery.customerName[0].toUpperCase() : 'C',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delivery.customerName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        delivery.address,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Action Quick Buttons (Call, WhatsApp, Maps)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _callPhone(delivery.phone),
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openWhatsApp(delivery.phone),
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openMaps(delivery.address),
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('Navigate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Details Metrics Cards
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricItem(
                        context,
                        title: 'Slot',
                        value: delivery.deliverySlot,
                        icon: Icons.wb_sunny_outlined,
                        color: Colors.amber,
                      ),
                      _buildMetricItem(
                        context,
                        title: 'Plan',
                        value: delivery.subscriptionType,
                        icon: Icons.card_membership,
                        color: Colors.blue,
                      ),
                      _buildMetricItem(
                        context,
                        title: 'Pending Dues',
                        value: AppFormatters.formatCurrency(pendingDues),
                        icon: Icons.account_balance_wallet_outlined,
                        color: pendingDues > 0 ? AppColors.error : AppColors.success,
                      ),
                      _buildMetricItem(
                        context,
                        title: 'Empty Cans',
                        value: '$emptyPending Cans',
                        icon: Icons.opacity,
                        color: Colors.cyan,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Customer Notes Section
            if (customer != null && customer!.notes.isNotEmpty) ...[
              Text(
                'Customer Notes',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note_alt_outlined, size: 20, color: Colors.amber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        customer!.notes,
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Delivery Timeline Progress
            Text(
              'Delivery Timeline',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildTimelineTrack(context, delivery),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineTrack(BuildContext context, DeliveryModel delivery) {
    final isDelivered = delivery.deliveryStatus == 'delivered';
    final isCancelled = delivery.deliveryStatus == 'cancelled';
    final isSkipped = delivery.deliveryStatus == 'skipped';

    return Row(
      children: [
        _buildTimelineStep(
          context,
          title: 'Assigned',
          time: DateFormat('hh:mm a').format(delivery.createdAt),
          isDone: true,
          isCurrent: false,
        ),
        _buildLine(isDone: true),
        _buildTimelineStep(
          context,
          title: isCancelled ? 'Cancelled' : isSkipped ? 'Skipped' : isDelivered ? 'Delivered' : 'On the Way',
          time: delivery.completedAt != null ? DateFormat('hh:mm a').format(delivery.completedAt!) : 'Pending',
          isDone: isDelivered || isCancelled || isSkipped,
          isCurrent: !isDelivered && !isCancelled && !isSkipped,
          color: isCancelled ? AppColors.error : isSkipped ? Colors.grey : AppColors.success,
        ),
        _buildLine(isDone: isDelivered),
        _buildTimelineStep(
          context,
          title: 'Payment',
          time: delivery.paymentMode,
          isDone: isDelivered,
          isCurrent: false,
        ),
      ],
    );
  }

  Widget _buildTimelineStep(
    BuildContext context, {
    required String title,
    required String time,
    required bool isDone,
    required bool isCurrent,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final activeColor = color ?? AppColors.primary;

    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: isDone ? activeColor : isCurrent ? activeColor.withValues(alpha: 0.2) : Colors.grey.shade300,
            child: Icon(
              isDone ? Icons.check : Icons.circle,
              size: 14,
              color: isDone ? Colors.white : isCurrent ? activeColor : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              fontWeight: isDone || isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            time,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLine({required bool isDone}) {
    return Expanded(
      child: Container(
        height: 2,
        color: isDone ? AppColors.primary : Colors.grey.shade300,
      ),
    );
  }
}
