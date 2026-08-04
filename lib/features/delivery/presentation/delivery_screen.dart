import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/order_model.dart';
import '../../../providers/app_providers.dart';

class DeliveryScreen extends ConsumerStatefulWidget {
  const DeliveryScreen({super.key});

  @override
  ConsumerState<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends ConsumerState<DeliveryScreen> {
  void _openGoogleMaps(String address) async {
    final encoded = Uri.encodeComponent(address);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showCompleteDeliveryDialog(OrderModel order) {
    final cansDeliveredCtrl = TextEditingController(text: order.quantity.toString());
    final emptyCansCtrl = TextEditingController(text: order.quantity.toString());
    final damagedCansCtrl = TextEditingController(text: '0');
    PaymentMode selectedPaymentMode = PaymentMode.upi;
    PaymentStatus selectedPaymentStatus = PaymentStatus.paid;
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text('Complete Delivery - ${order.id}'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer: ${order.customerName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text('Total Amount: ${AppFormatters.formatCurrency(order.totalAmount)}', style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                    const Divider(height: 20),

                    CustomTextField(
                      label: 'Cans Delivered (Filled Cans)',
                      controller: cansDeliveredCtrl,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.water_drop_outlined,
                      hint: 'Enter quantity of filled cans delivered',
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      label: 'Empty Cans Collected',
                      controller: emptyCansCtrl,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.crop_portrait,
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      label: 'Damaged Cans Reported',
                      controller: damagedCansCtrl,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.warning_amber_outlined,
                    ),
                    const SizedBox(height: 12),

                    const Text('Payment Mode Received', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<PaymentMode>(
                      initialValue: selectedPaymentMode,
                      isExpanded: true,
                      items: PaymentMode.values.map((mode) {
                        return DropdownMenuItem(value: mode, child: Text(mode.displayName));
                      }).toList(),
                      onChanged: isSaving
                          ? null
                          : (val) {
                              if (val != null) setModalState(() => selectedPaymentMode = val);
                            },
                    ),
                    const SizedBox(height: 12),

                    const Text('Payment Status', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<PaymentStatus>(
                      initialValue: selectedPaymentStatus,
                      isExpanded: true,
                      items: PaymentStatus.values.map((status) {
                        return DropdownMenuItem(value: status, child: Text(status.displayName));
                      }).toList(),
                      onChanged: isSaving
                          ? null
                          : (val) {
                              if (val != null) setModalState(() => selectedPaymentStatus = val);
                            },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton.icon(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setModalState(() => isSaving = true);
                          try {
                            final emptyCollected = int.tryParse(emptyCansCtrl.text) ?? 0;
                            final damagedReported = int.tryParse(damagedCansCtrl.text) ?? 0;

                            await ref.read(orderProvider.notifier).updateStatus(
                                  order.id,
                                  OrderStatus.delivered,
                                  emptyCansCollected: emptyCollected,
                                  damagedCansReported: damagedReported,
                                  paymentMode: selectedPaymentMode,
                                  paymentStatus: selectedPaymentStatus,
                                );

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ Order ${order.id} marked as DELIVERED in Google Sheets!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('❌ Error updating delivery status: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        }
                      },
                icon: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle),
                label: const Text('Confirm Delivery'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(orderProvider);
    final activeDeliveries = orders.where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled).toList();
    final completedDeliveries = orders.where((o) => o.status == OrderStatus.delivered).toList();

    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: "Active Deliveries"),
                Tab(text: "Completed Today"),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  // Active Deliveries Tab
                  activeDeliveries.isEmpty
                      ? const EmptyStateWidget(
                          title: 'No Active Deliveries',
                          description: 'All assigned orders have been successfully delivered!',
                          icon: Icons.task_alt,
                        )
                      : ListView.builder(
                          itemCount: activeDeliveries.length,
                          itemBuilder: (context, index) {
                            final item = activeDeliveries[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: CustomCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.customerName,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        StatusBadge(status: item.status),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('${item.quantity} Cans • Total: ${AppFormatters.formatCurrency(item.totalAmount)}',
                                        style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    Text(item.address, style: const TextStyle(color: AppColors.textSecondary)),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () => _openGoogleMaps(item.address),
                                          icon: const Icon(Icons.navigation, size: 16),
                                          label: const Text('Navigate'),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () => _showCompleteDeliveryDialog(item),
                                          icon: const Icon(Icons.check, size: 16),
                                          label: const Text('Complete'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                  // Completed Deliveries Tab
                  completedDeliveries.isEmpty
                      ? const EmptyStateWidget(
                          title: 'No Deliveries Completed Yet',
                          description: 'Complete active delivery checklists to see completed logs.',
                        )
                      : ListView.builder(
                          itemCount: completedDeliveries.length,
                          itemBuilder: (context, index) {
                            final item = completedDeliveries[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: CustomCard(
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: AppColors.successLight,
                                    child: Icon(Icons.check, color: AppColors.success),
                                  ),
                                  title: Text(item.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Delivered ${item.quantity} Cans | Collected ${item.emptyCansCollected} Empty Cans'),
                                  trailing: Text(
                                    AppFormatters.formatCurrency(item.totalAmount),
                                    style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
