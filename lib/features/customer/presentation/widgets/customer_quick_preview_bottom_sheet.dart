import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../models/customer_model.dart';
import '../../../../models/delivery_model.dart';

class CustomerQuickPreviewBottomSheet extends StatelessWidget {
  final CustomerModel customer;
  final DeliveryModel? lastDelivery;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onNavigate;
  final VoidCallback onCreateOrder;
  final VoidCallback onCollectPayment;
  final VoidCallback onOpenFullProfile;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isAdmin;

  const CustomerQuickPreviewBottomSheet({
    super.key,
    required this.customer,
    this.lastDelivery,
    required this.onCall,
    required this.onWhatsApp,
    required this.onNavigate,
    required this.onCreateOrder,
    required this.onCollectPayment,
    required this.onOpenFullProfile,
    this.onEdit,
    this.onDelete,
    this.isAdmin = false,
  });

  static void show(
    BuildContext context, {
    required CustomerModel customer,
    DeliveryModel? lastDelivery,
    required VoidCallback onCall,
    required VoidCallback onWhatsApp,
    required VoidCallback onNavigate,
    required VoidCallback onCreateOrder,
    required VoidCallback onCollectPayment,
    required VoidCallback onOpenFullProfile,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    bool isAdmin = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomerQuickPreviewBottomSheet(
        customer: customer,
        lastDelivery: lastDelivery,
        onCall: onCall,
        onWhatsApp: onWhatsApp,
        onNavigate: onNavigate,
        onCreateOrder: onCreateOrder,
        onCollectPayment: onCollectPayment,
        onOpenFullProfile: onOpenFullProfile,
        onEdit: onEdit,
        onDelete: onDelete,
        isAdmin: isAdmin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Drag indicator handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Header: Avatar, Name, Status & ID
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: customer.isActive ? AppColors.primaryLight : Colors.grey.shade200,
                          child: Text(
                            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: customer.isActive ? AppColors.primaryDark : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: customer.isActive ? AppColors.successLight : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      customer.isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: customer.isActive ? AppColors.success : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ID: ${customer.id}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Direct Contact Info Cards
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.phone_rounded, size: 18, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SelectableText(
                                  customer.phone,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.call, color: AppColors.success, size: 20),
                                onPressed: onCall,
                              ),
                              IconButton(
                                icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
                                onPressed: onWhatsApp,
                              ),
                            ],
                          ),
                          if (customer.address.isNotEmpty) ...[
                            const Divider(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on_rounded, size: 18, color: AppColors.primaryDark),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    customer.address,
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.map_rounded, color: AppColors.primaryDark, size: 20),
                                  onPressed: onNavigate,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Metrics Grid
                    const Text('Quick Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildOverviewCard(
                          title: 'Active Cans',
                          value: '${customer.canBalance} Cans',
                          color: AppColors.primaryDark,
                          backgroundColor: AppColors.primaryLight,
                        ),
                        const SizedBox(width: 10),
                        _buildOverviewCard(
                          title: 'Pending Dues',
                          value: AppFormatters.formatCurrency(customer.pendingDues),
                          color: AppColors.error,
                          backgroundColor: AppColors.errorLight,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildOverviewCard(
                          title: 'Security Deposit',
                          value: '₹${customer.securityDeposit.toStringAsFixed(0)}',
                          color: AppColors.warning,
                          backgroundColor: AppColors.warningLight,
                        ),
                        const SizedBox(width: 10),
                        _buildOverviewCard(
                          title: 'Can Price',
                          value: '₹${customer.canPrice.toStringAsFixed(0)} / can',
                          color: AppColors.info,
                          backgroundColor: AppColors.infoLight,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Quick Action Buttons
                    const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                            label: const Text('Create Order'),
                            onPressed: onCreateOrder,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.payments_rounded, size: 18),
                            label: const Text('Collect Payment'),
                            onPressed: onCollectPayment,
                          ),
                        ),
                      ],
                    ),
                    if (isAdmin) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (onEdit != null)
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.edit_rounded, size: 18),
                                label: const Text('Edit Customer'),
                                onPressed: onEdit,
                              ),
                            ),
                          if (onEdit != null && onDelete != null) const SizedBox(width: 10),
                          if (onDelete != null)
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(color: AppColors.error),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.delete_rounded, size: 18),
                                label: const Text('Delete'),
                                onPressed: onDelete,
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Full Profile Navigation Button
                    CustomButton(
                      label: 'Open Full Customer Profile',
                      icon: Icons.account_box_rounded,
                      onPressed: () {
                        Navigator.pop(context);
                        onOpenFullProfile();
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String value,
    required Color color,
    required Color backgroundColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
