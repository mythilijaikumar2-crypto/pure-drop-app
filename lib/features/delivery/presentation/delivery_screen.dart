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
import '../../../models/customer_model.dart';
import '../../../models/delivery_model.dart';
import '../../../providers/app_providers.dart';
import 'widgets/customer_profile_sheet.dart';

class DeliveryScreen extends ConsumerStatefulWidget {
  const DeliveryScreen({super.key});

  @override
  ConsumerState<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends ConsumerState<DeliveryScreen> {
  String _selectedStatusTab = 'All';
  String _selectedSlotFilter = 'All';

  static const List<String> _cancelReasons = [
    'Customer Not Home',
    'Customer Cancelled',
    'Wrong Address',
    'Holiday',
    'No Stock',
    'Duplicate Order',
    'Other',
  ];

  void _openMaps(String address) async {
    if (address.isEmpty) return;
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

  void _openWhatsApp(String phone) async {
    if (phone.isEmpty) return;
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/91$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showUndoSnackBar(String deliveryId, String actionMessage) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(deliveryProvider.notifier);

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(actionMessage, style: const TextStyle(fontSize: 13))),
          ],
        ),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.amber,
          onPressed: () async {
            final undone = await notifier.undoLastAction(deliveryId);
            if (undone) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Action reverted successfully.'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'rescheduled':
        return Colors.orange;
      case 'skipped':
        return Colors.grey;
      case 'pending':
      case 'assigned':
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
      case 'skipped':
        return 'Skipped Today';
      default:
        return 'Pending';
    }
  }

  void _showCustomerProfile(DeliveryModel delivery) {
    final customers = ref.read(customerProvider);
    final customer = customers.cast<CustomerModel?>().firstWhere(
          (c) => c?.id == delivery.customerId,
          orElse: () => null,
        );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomerProfileSheet(
        customer: customer,
        delivery: delivery,
      ),
    );
  }

  void _showCompleteDeliveryDialog(DeliveryModel delivery, String userDisplayName) {
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer: ${delivery.customerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'Total Amount: ${AppFormatters.formatCurrency(delivery.totalAmount)}',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 20),

                    CustomTextField(
                      label: 'Empty Cans Collected',
                      controller: emptyCansCtrl,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.water_drop_outlined,
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
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: ['Cash', 'UPI', 'Pending'].map((mode) {
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
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setModalState(() => isSaving = true);
                          final emptyCount = int.tryParse(emptyCansCtrl.text.trim()) ?? delivery.quantity;
                          final damagedCount = int.tryParse(damagedCansCtrl.text.trim()) ?? 0;

                          try {
                            final ok = await ref.read(deliveryProvider.notifier).executeAction(
                                  delivery: delivery,
                                  newStatus: 'delivered',
                                  reason: '',
                                  remarks: 'Delivered',
                                  updatedBy: userDisplayName,
                                  updatedRole: 'Delivery Staff',
                                  emptyCansCollected: emptyCount,
                                  damagedCansReported: damagedCount,
                                  paymentMode: selectedPaymentMode,
                                );

                            if (context.mounted) {
                              Navigator.pop(context);
                              if (ok) {
                                _showUndoSnackBar(delivery.deliveryId, 'Delivery marked as Delivered');
                              }
                            }
                          } catch (e) {
                            setModalState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                              );
                            }
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirm Delivered'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCancelOrderDialog(DeliveryModel delivery, String userDisplayName) {
    String selectedReason = _cancelReasons.first;
    final customReasonCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isOtherSelected = selectedReason == 'Other';

          return AlertDialog(
            title: const Text('Cancel Order'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select reason for cancelling delivery for ${delivery.customerName}:', style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _cancelReasons.map((reason) {
                      final isSelected = selectedReason == reason;
                      return ChoiceChip(
                        label: Text(reason, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
                        selected: isSelected,
                        selectedColor: AppColors.error,
                        onSelected: (val) {
                          if (val) setModalState(() => selectedReason = reason);
                        },
                      );
                    }).toList(),
                  ),
                  if (isOtherSelected) ...[
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'Specify Reason',
                      hint: 'Enter cancellation reason...',
                      controller: customReasonCtrl,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text('Back'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: isSaving
                    ? null
                    : () async {
                        final finalReason = isOtherSelected ? customReasonCtrl.text.trim() : selectedReason;
                        if (isOtherSelected && finalReason.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a cancellation reason.')),
                          );
                          return;
                        }

                        setModalState(() => isSaving = true);
                        try {
                          final ok = await ref.read(deliveryProvider.notifier).executeAction(
                                delivery: delivery,
                                newStatus: 'cancelled',
                                reason: finalReason,
                                remarks: 'Cancelled by delivery staff',
                                updatedBy: userDisplayName,
                                updatedRole: 'Delivery Staff',
                              );

                          if (context.mounted) {
                            Navigator.pop(context);
                            if (ok) {
                              _showUndoSnackBar(delivery.deliveryId, 'Order cancelled');
                            }
                          }
                        } catch (e) {
                          setModalState(() => isSaving = false);
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirm Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChangeQuantityDialog(DeliveryModel delivery) {
    int qty = delivery.quantity;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Change Can Quantity'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Customer: ${delivery.customerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 32, color: AppColors.error),
                      onPressed: qty > 1 ? () => setModalState(() => qty--) : null,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$qty Cans',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 32, color: AppColors.success),
                      onPressed: () => setModalState(() => qty++),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Total: ${AppFormatters.formatCurrency(qty * delivery.unitPrice)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final ok = await ref.read(deliveryProvider.notifier).changeQuantity(delivery.deliveryId, qty);
                  if (context.mounted) {
                    Navigator.pop(context);
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Quantity updated to $qty Cans')),
                      );
                    }
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCollectPaymentDialog(DeliveryModel delivery) {
    String selectedMode = 'Cash';
    final amountCtrl = TextEditingController(text: delivery.totalAmount.toString());

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Collect Payment'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer: ${delivery.customerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Amount Collected (₹)',
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.currency_rupee,
                ),
                const SizedBox(height: 12),
                const Text('Payment Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedMode,
                  items: ['Cash', 'UPI', 'Pending'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) => setModalState(() => selectedMode = val!),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final amt = double.tryParse(amountCtrl.text.trim()) ?? delivery.totalAmount;
                  final ok = await ref.read(deliveryProvider.notifier).collectPayment(
                        deliveryId: delivery.deliveryId,
                        amount: amt,
                        paymentMode: selectedMode,
                      );
                  if (context.mounted) {
                    Navigator.pop(context);
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Payment of ${AppFormatters.formatCurrency(amt)} recorded via $selectedMode')),
                      );
                    }
                  }
                },
                child: const Text('Save Payment'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authState = ref.watch(authProvider);
    final user = authState.user;
    final currentUid = user?.id ?? '';
    final currentEmpId = user?.employeeId ?? '';
    final isDriver = user?.role == UserRole.deliveryBoy;
    final userDisplayName = user?.name ?? 'Delivery Staff';

    final deliveries = ref.watch(deliveryProvider);
    final expenses = ref.watch(expenseProvider);

    final driverDeliveries = isDriver
        ? deliveries.where((d) => d.employeeId == currentUid || d.employeeId == currentEmpId).toList()
        : deliveries;

    // Filter by delivery slot
    final slotFiltered = _selectedSlotFilter == 'All'
        ? driverDeliveries
        : driverDeliveries.where((d) => d.deliverySlot.toLowerCase() == _selectedSlotFilter.toLowerCase()).toList();

    // Metrics calculations
    final totalOrders = slotFiltered.length;
    final deliveredCount = slotFiltered.where((d) => d.deliveryStatus == 'delivered').length;
    final pendingCount = slotFiltered.where((d) => d.deliveryStatus == 'pending' || d.deliveryStatus == 'assigned').length;
    final amountCollected = slotFiltered.where((d) => d.deliveryStatus == 'delivered').fold(0.0, (sum, d) => sum + d.totalAmount);
    final pendingAmount = slotFiltered.where((d) => d.deliveryStatus != 'delivered' && d.deliveryStatus != 'cancelled').fold(0.0, (sum, d) => sum + d.totalAmount);
    final emptyCansCount = slotFiltered.fold(0, (sum, d) => sum + d.emptyCansCollected);
    final damagedCansCount = slotFiltered.fold(0, (sum, d) => sum + d.damagedCansReported);

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayExpenses = expenses
        .where((e) => DateFormat('yyyy-MM-dd').format(e.date) == todayStr)
        .fold(0.0, (sum, e) => sum + e.amount);

    // Filter list for tab
    final displayList = slotFiltered.where((d) {
      if (_selectedStatusTab == 'All') return true;
      if (_selectedStatusTab == 'Pending') return d.deliveryStatus == 'pending' || d.deliveryStatus == 'assigned';
      if (_selectedStatusTab == 'Delivered') return d.deliveryStatus == 'delivered';
      if (_selectedStatusTab == 'Cancelled') return d.deliveryStatus == 'cancelled';
      if (_selectedStatusTab == 'Skipped') return d.deliveryStatus == 'skipped';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : AppColors.surface,
      appBar: AppBar(
        title: Text(isDriver ? 'My Delivery Tasks' : 'Deliveries Overview'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(deliveryProvider.notifier).refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Deliveries refreshed'), duration: Duration(seconds: 1)),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Responsive Dashboard Counters Header
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildAnimatedMetricChip(context, title: 'Total Tasks', value: totalOrders.toString(), color: Colors.blue),
                  const SizedBox(width: 8),
                  _buildAnimatedMetricChip(context, title: 'Delivered', value: deliveredCount.toString(), color: AppColors.success),
                  const SizedBox(width: 8),
                  _buildAnimatedMetricChip(context, title: 'Pending', value: pendingCount.toString(), color: AppColors.primary),
                  const SizedBox(width: 8),
                  _buildAnimatedMetricChip(context, title: 'Collected', value: AppFormatters.formatCurrency(amountCollected), color: Colors.teal),
                  const SizedBox(width: 8),
                  _buildAnimatedMetricChip(context, title: 'Pending ₹', value: AppFormatters.formatCurrency(pendingAmount), color: Colors.orange),
                  const SizedBox(width: 8),
                  _buildAnimatedMetricChip(context, title: 'Empty Cans', value: '$emptyCansCount Cans', color: Colors.cyan),
                  const SizedBox(width: 8),
                  _buildAnimatedMetricChip(context, title: 'Damaged', value: '$damagedCansCount Cans', color: AppColors.error),
                  const SizedBox(width: 8),
                  _buildAnimatedMetricChip(context, title: 'Expenses', value: AppFormatters.formatCurrency(todayExpenses), color: Colors.purple),
                ],
              ),
            ),

            // Slot Filter Bar (All, Morning, Evening)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Text('Slot:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 12),
                  _buildSlotFilterChip('All'),
                  const SizedBox(width: 6),
                  _buildSlotFilterChip('Morning'),
                  const SizedBox(width: 6),
                  _buildSlotFilterChip('Evening'),
                ],
              ),
            ),

            // Status Tabs (All, Pending, Delivered, Skipped, Cancelled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Pending', 'Delivered', 'Skipped', 'Cancelled'].map((status) {
                    final isSelected = _selectedStatusTab == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(status, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        onSelected: (val) {
                          if (val) setState(() => _selectedStatusTab = status);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const Divider(height: 1),

            // Delivery Orders List
            Expanded(
              child: displayList.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.local_shipping_outlined,
                      title: 'No Deliveries Found',
                      description: 'No assigned delivery orders matching the selected filter.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: displayList.length,
                      itemBuilder: (context, index) {
                        final delivery = displayList[index];
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: CustomCard(
                            padding: const EdgeInsets.all(14),
                            onTap: () => _showCustomerProfile(delivery),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: Customer Name & Status Badge
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              delivery.customerName,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (delivery.deliverySlot == 'Morning' ? Colors.amber : Colors.indigo).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  delivery.deliverySlot == 'Morning' ? Icons.wb_sunny : Icons.nights_stay,
                                                  size: 12,
                                                  color: delivery.deliverySlot == 'Morning' ? Colors.amber.shade800 : Colors.indigo,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  delivery.deliverySlot,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: delivery.deliverySlot == 'Morning' ? Colors.amber.shade800 : Colors.indigo,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(delivery.deliveryStatus).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _getStatusDisplayName(delivery.deliveryStatus),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(delivery.deliveryStatus),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Address & Phone
                                Text(
                                  delivery.address,
                                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),

                                // Quantity & Total Amount Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${delivery.quantity} Cans',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          AppFormatters.formatCurrency(delivery.totalAmount),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark),
                                        ),
                                      ],
                                    ),

                                    // Quick Communication Action Buttons (Call, WhatsApp, Maps)
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.phone_outlined, size: 20, color: Colors.blue),
                                          onPressed: () => _callCustomer(delivery.phone),
                                          tooltip: 'Call',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.chat_outlined, size: 20, color: Color(0xFF25D366)),
                                          onPressed: () => _openWhatsApp(delivery.phone),
                                          tooltip: 'WhatsApp',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.navigation_outlined, size: 20, color: AppColors.primary),
                                          onPressed: () => _openMaps(delivery.address),
                                          tooltip: 'Maps',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                const Divider(height: 16),

                                // Employee Delivery Action Buttons Row
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      if (delivery.deliveryStatus != 'delivered') ...[
                                        ElevatedButton.icon(
                                          onPressed: () => _showCompleteDeliveryDialog(delivery, userDisplayName),
                                          icon: const Icon(Icons.check_circle_outline, size: 16),
                                          label: const Text('Delivered'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.success,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 6),

                                        OutlinedButton.icon(
                                          onPressed: () => _showCollectPaymentDialog(delivery),
                                          icon: const Icon(Icons.payment, size: 16),
                                          label: const Text('Payment'),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            textStyle: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        const SizedBox(width: 6),

                                        OutlinedButton.icon(
                                          onPressed: () => _showChangeQuantityDialog(delivery),
                                          icon: const Icon(Icons.edit_outlined, size: 16),
                                          label: const Text('Qty'),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            textStyle: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        const SizedBox(width: 6),

                                        OutlinedButton.icon(
                                          onPressed: () async {
                                            final nextSlot = delivery.deliverySlot == 'Morning' ? 'Evening' : 'Morning';
                                            final ok = await ref.read(deliveryProvider.notifier).shiftSlot(delivery.deliveryId, nextSlot);
                                            if (ok && context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Shifted delivery to $nextSlot slot')),
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.swap_horiz, size: 16),
                                          label: Text('Shift ${delivery.deliverySlot == "Morning" ? "Evening" : "Morning"}'),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            textStyle: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        const SizedBox(width: 6),

                                        OutlinedButton.icon(
                                          onPressed: () async {
                                            final ok = await ref.read(deliveryProvider.notifier).executeAction(
                                                  delivery: delivery,
                                                  newStatus: 'skipped',
                                                  reason: 'Skipped Today',
                                                  remarks: 'Skipped by driver',
                                                  updatedBy: userDisplayName,
                                                  updatedRole: 'Delivery Staff',
                                                );
                                            if (ok && context.mounted) {
                                              _showUndoSnackBar(delivery.deliveryId, 'Delivery skipped today');
                                            }
                                          },
                                          icon: const Icon(Icons.next_plan_outlined, size: 16),
                                          label: const Text('Skip Today'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.orange,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            textStyle: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        const SizedBox(width: 6),

                                        OutlinedButton.icon(
                                          onPressed: () => _showCancelOrderDialog(delivery, userDisplayName),
                                          icon: const Icon(Icons.cancel_outlined, size: 16),
                                          label: const Text('Cancel'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.error,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            textStyle: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                      if (delivery.deliveryStatus == 'delivered')
                                        Text(
                                          'Completed at ${delivery.completedAt != null ? DateFormat("hh:mm a").format(delivery.completedAt!) : "Today"} (${delivery.paymentMode})',
                                          style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedMetricChip(
    BuildContext context, {
    required String title,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, val, child) {
              return Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSlotFilterChip(String slot) {
    final isSelected = _selectedSlotFilter == slot;
    return ChoiceChip(
      label: Text(slot, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : null)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      onSelected: (val) {
        if (val) setState(() => _selectedSlotFilter = slot);
      },
    );
  }
}
