import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/delivery_model.dart';
import '../../../providers/app_providers.dart';

class DeliveryScreen extends ConsumerStatefulWidget {
  const DeliveryScreen({super.key});

  @override
  ConsumerState<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends ConsumerState<DeliveryScreen> {
  String? _selectedDriverFilter;

  static const List<String> _reasonOptions = [
    'Customer Requested',
    'House Locked',
    'Going Out Of Station',
    'No Empty Can',
    'Already Purchased',
    'Payment Pending',
    'Customer Not Available',
    'Vehicle Breakdown',
    'Wrong Address',
    'Other',
  ];

  void _openGoogleMaps(String address) async {
    final encoded = Uri.encodeComponent(address);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _callCustomer(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'rescheduled':
        return Colors.orange;
      case 'customernotavailable':
      case 'customer_not_available':
        return Colors.purple;
      case 'skipped':
      case 'skiptoday':
        return Colors.grey;
      case 'pending':
      case 'assigned':
      case 'intransit':
      default:
        return AppColors.primary;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'rescheduled':
        return 'Rescheduled';
      case 'customernotavailable':
      case 'customer_not_available':
        return 'Customer Not Available';
      case 'skipped':
      case 'skiptoday':
        return 'Skipped Today';
      default:
        return 'Pending';
    }
  }

  void _showCompleteDeliveryDialog(DeliveryModel delivery) {
    final emptyCansCtrl = TextEditingController(text: delivery.quantity.toString());
    final damagedCansCtrl = TextEditingController(text: '0');
    String selectedPaymentMode = 'Cash';
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text('Complete Delivery - ${delivery.deliveryId}'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer: ${delivery.customerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Total Amount: ${AppFormatters.formatCurrency(delivery.totalAmount)}', style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                    const Divider(height: 20),

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

                    const Text('Payment Mode Received', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedPaymentMode,
                      isExpanded: true,
                      items: ['Cash', 'UPI / Online', 'Bank Transfer', 'Credit'].map((mode) {
                        return DropdownMenuItem(value: mode, child: Text(mode));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedPaymentMode = val);
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
                            final authState = ref.read(authProvider);
                            final currentUser = authState.user;
                            final updatedBy = currentUser?.name ?? 'Admin';
                            final updatedRole = currentUser?.role.name ?? 'Admin';

                            final emptyCollected = int.tryParse(emptyCansCtrl.text) ?? 0;
                            final damagedReported = int.tryParse(damagedCansCtrl.text) ?? 0;

                            final success = await ref.read(deliveryProvider.notifier).executeAction(
                                  delivery: delivery,
                                  newStatus: 'delivered',
                                  reason: 'Delivered Successfully',
                                  remarks: 'Delivered $emptyCollected empty cans returned',
                                  updatedBy: updatedBy,
                                  updatedRole: updatedRole,
                                  emptyCansCollected: emptyCollected,
                                  damagedCansReported: damagedReported,
                                  paymentMode: selectedPaymentMode,
                                );

                            if (context.mounted) {
                              Navigator.pop(context);
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✅ Delivery ${delivery.deliveryId} marked as DELIVERED!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            setModalState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('❌ Error updating delivery: $e'), backgroundColor: AppColors.error),
                              );
                            }
                          }
                        }
                      },
                icon: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle),
                label: const Text('Confirm Delivered'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeliveryActionDialog({
    required DeliveryModel delivery,
    required String actionName,
    required String targetStatus,
    bool isReschedule = false,
  }) {
    String selectedReason = _reasonOptions.first;
    final remarksCtrl = TextEditingController();
    DateTime? selectedFutureDate;
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text('$actionName - ${delivery.customerName}'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delivery ID: ${delivery.deliveryId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 12),

                    if (isReschedule) ...[
                      const Text('Select Reschedule Future Date *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final tomorrow = DateTime.now().add(const Duration(days: 1));
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tomorrow,
                            firstDate: tomorrow,
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          if (picked != null) {
                            setModalState(() => selectedFutureDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                selectedFutureDate != null
                                    ? DateFormat('dd MMM yyyy').format(selectedFutureDate!)
                                    : 'Tap to select Future Date',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: selectedFutureDate != null ? AppColors.textPrimary : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    const Text('Reason *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedReason,
                      isExpanded: true,
                      items: _reasonOptions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedReason = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      label: selectedReason == 'Other' ? 'Remarks (Mandatory for "Other") *' : 'Remarks / Notes (Optional)',
                      controller: remarksCtrl,
                      hint: 'Enter remarks details...',
                      validator: (v) {
                        if (selectedReason == 'Other' && (v == null || v.trim().isEmpty)) {
                          return 'Remarks are mandatory when "Other" reason is selected';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getStatusColor(targetStatus),
                  foregroundColor: Colors.white,
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (isReschedule && selectedFutureDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('⚠️ Please select a valid future date for reschedule'), backgroundColor: AppColors.warning),
                          );
                          return;
                        }

                        if (formKey.currentState!.validate()) {
                          setModalState(() => isSaving = true);
                          try {
                            final authState = ref.read(authProvider);
                            final currentUser = authState.user;
                            final updatedBy = currentUser?.name ?? 'Admin';
                            final updatedRole = currentUser?.role.name ?? 'Admin';

                            final success = await ref.read(deliveryProvider.notifier).executeAction(
                                  delivery: delivery,
                                  newStatus: targetStatus,
                                  reason: selectedReason,
                                  remarks: remarksCtrl.text.trim(),
                                  updatedBy: updatedBy,
                                  updatedRole: updatedRole,
                                  rescheduledDate: selectedFutureDate,
                                );

                            if (context.mounted) {
                              Navigator.pop(context);
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✅ Delivery ${delivery.deliveryId} updated to ${actionName.toUpperCase()}!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            setModalState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('❌ Error updating action: $e'), backgroundColor: AppColors.error),
                              );
                            }
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Submit $actionName'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDriver = user?.role == UserRole.deliveryBoy;
    final employees = ref.watch(employeeProvider);

    // Watch real-time snapshot stream
    final deliveriesStream = ref.watch(deliveriesStreamProvider);
    final List<DeliveryModel> allDeliveries = deliveriesStream.asData?.value ?? ref.watch(deliveryProvider);

    // Filter deliveries based on driver/admin selection
    final filteredDeliveries = allDeliveries.where((d) {
      if (isDriver) {
        if (user?.id != null && user!.id.isNotEmpty) {
          return d.employeeId == user.id;
        }
        return d.employeeName.isNotEmpty && user?.name != null && d.employeeName.toLowerCase() == user!.name.toLowerCase();
      } else {
        if (_selectedDriverFilter != null && _selectedDriverFilter!.isNotEmpty) {
          if (d.employeeId == _selectedDriverFilter || d.employeeName == _selectedDriverFilter) return true;
          return false;
        }
        return true;
      }
    }).toList();

    // Active today deliveries (Excludes cancelled, delivered, and rescheduled to future)
    final now = DateTime.now();
    final todayDeliveries = filteredDeliveries.where((d) {
      final status = d.deliveryStatus.toLowerCase();
      if (status == 'cancelled' || status == 'delivered') return false;
      if (status == 'rescheduled' && d.rescheduledDate != null && d.rescheduledDate!.isAfter(DateTime(now.year, now.month, now.day, 23, 59))) {
        return false; // Removed from today's list
      }
      return true;
    }).toList();

    final completedToday = filteredDeliveries.where((d) => d.deliveryStatus.toLowerCase() == 'delivered').toList();

    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Admin Driver Filter Header & Real-time Indicator
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Delivery Dispatch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          const Text('Real-time Firestore Snapshot Sync Active', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isDriver)
                  DropdownButton<String?>(
                    value: _selectedDriverFilter,
                    hint: const Text('All Drivers'),
                    underline: const SizedBox(),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('All Drivers')),
                      ...employees.where((e) => e.role == UserRole.deliveryBoy).map((e) {
                        return DropdownMenuItem<String?>(value: e.name, child: Text(e.name));
                      }),
                    ],
                    onChanged: (val) => setState(() => _selectedDriverFilter = val),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            const TabBar(
              tabs: [
                Tab(text: "Today's Pending Deliveries"),
                Tab(text: "Completed Logs"),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: TabBarView(
                children: [
                  // Pending Deliveries Tab
                  todayDeliveries.isEmpty
                      ? EmptyStateWidget(
                          title: isDriver ? 'No Pending Assignments' : 'No Today Deliveries',
                          description: 'All assigned deliveries have been completed or processed!',
                          icon: Icons.task_alt,
                        )
                      : ListView.builder(
                          itemCount: todayDeliveries.length,
                          itemBuilder: (context, index) {
                            final item = todayDeliveries[index];
                            final statusColor = _getStatusColor(item.deliveryStatus);
                            final statusText = _getStatusDisplayName(item.deliveryStatus);
                            final isDelivered = item.deliveryStatus.toLowerCase() == 'delivered';

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
                                        if (item.phone.isNotEmpty)
                                          IconButton(
                                            icon: const Icon(Icons.phone, color: AppColors.success, size: 18),
                                            onPressed: () => _callCustomer(item.phone),
                                            tooltip: 'Call Customer',
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 18),
                                          onPressed: () => _openGoogleMaps(item.address),
                                          tooltip: 'Navigate Google Maps',
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: statusColor),
                                          ),
                                          child: Text(
                                            statusText,
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.quantity} Cans • Total: ${AppFormatters.formatCurrency(item.totalAmount)} • Time: ${item.deliveryTime}',
                                      style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(item.address, style: const TextStyle(color: AppColors.textSecondary)),
                                    if (item.phone.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text('Contact: ${item.phone}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text('Updated By: ${item.updatedBy.isNotEmpty ? item.updatedBy : "System"}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                        const Spacer(),
                                        Text('Last Updated: ${DateFormat('dd MMM hh:mm a').format(item.updatedAt)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      ],
                                    ),
                                    const SizedBox(height: 14),

                                    // Delivery Action Buttons
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        // Deliver Button
                                        ElevatedButton.icon(
                                          onPressed: isDelivered ? null : () => _showCompleteDeliveryDialog(item),
                                          icon: const Icon(Icons.check_circle_outline, size: 14),
                                          label: const Text('Deliver'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.success,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          ),
                                        ),
                                        // Reschedule Button
                                        OutlinedButton.icon(
                                          onPressed: () => _showDeliveryActionDialog(
                                            delivery: item,
                                            actionName: 'Reschedule',
                                            targetStatus: 'rescheduled',
                                            isReschedule: true,
                                          ),
                                          icon: const Icon(Icons.edit_calendar, size: 14, color: Colors.orange),
                                          label: const Text('Reschedule', style: TextStyle(color: Colors.orange)),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Colors.orange),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          ),
                                        ),
                                        // Cancel Button
                                        OutlinedButton.icon(
                                          onPressed: () => _showDeliveryActionDialog(
                                            delivery: item,
                                            actionName: 'Cancel Delivery',
                                            targetStatus: 'cancelled',
                                          ),
                                          icon: const Icon(Icons.cancel_outlined, size: 14, color: AppColors.error),
                                          label: const Text('Cancel', style: TextStyle(color: AppColors.error)),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: AppColors.error),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          ),
                                        ),
                                        // Customer Not Available
                                        OutlinedButton.icon(
                                          onPressed: () => _showDeliveryActionDialog(
                                            delivery: item,
                                            actionName: 'Customer Not Available',
                                            targetStatus: 'customerNotAvailable',
                                          ),
                                          icon: const Icon(Icons.person_off_outlined, size: 14, color: Colors.purple),
                                          label: const Text('Not Available', style: TextStyle(color: Colors.purple)),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Colors.purple),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          ),
                                        ),
                                        // Skip Today
                                        OutlinedButton.icon(
                                          onPressed: () => _showDeliveryActionDialog(
                                            delivery: item,
                                            actionName: 'Skip Today',
                                            targetStatus: 'skipped',
                                          ),
                                          icon: const Icon(Icons.skip_next_rounded, size: 14, color: Colors.grey),
                                          label: const Text('Skip Today', style: TextStyle(color: Colors.grey)),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Colors.grey),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                  // Completed Logs Tab
                  completedToday.isEmpty
                      ? const EmptyStateWidget(
                          title: 'No Completed Delivery Logs Today',
                          description: 'Completed delivery logs will appear here.',
                        )
                      : ListView.builder(
                          itemCount: completedToday.length,
                          itemBuilder: (context, index) {
                            final item = completedToday[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: CustomCard(
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: AppColors.successLight,
                                    child: Icon(Icons.check, color: AppColors.success),
                                  ),
                                  title: Text(item.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Delivered ${item.quantity} Cans | Updated By: ${item.updatedBy}'),
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
