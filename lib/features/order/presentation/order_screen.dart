import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/customer_model.dart';
import '../../../models/employee_model.dart';
import '../../../models/order_model.dart';
import '../../../providers/app_providers.dart';

class OrderScreen extends ConsumerStatefulWidget {
  const OrderScreen({super.key});

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen> {
  OrderStatus? _statusFilter;

  void _showCreateOrderDialog() {
    final customers = ref.read(customerProvider);
    if (customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one customer first!')),
      );
      return;
    }

    CustomerModel selectedCustomer = customers.first;
    final qtyCtrl = TextEditingController(text: '5');
    final priceCtrl = TextEditingController(text: selectedCustomer.canPrice.toString());
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;
    String? dialogError;

    bool isPriority = false;
    bool isRecurring = false;
    String recurringFreq = 'Daily';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Create Water Can Order'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dialogError != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          dialogError!,
                          style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    const Text('Select Customer', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<CustomerModel>(
                      initialValue: selectedCustomer,
                      isExpanded: true,
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                      items: customers.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(
                            '${c.name} (${c.phone})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: isSaving
                          ? null
                          : (val) {
                              if (val != null) {
                                setModalState(() {
                                  selectedCustomer = val;
                                  priceCtrl.text = val.canPrice.toString();
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Quantity (Cans)',
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomTextField(
                            label: 'Price / Can (₹)',
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: isPriority,
                          onChanged: (val) => setModalState(() => isPriority = val ?? false),
                        ),
                        const Text('⚡ Priority Express Order', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: isRecurring,
                          onChanged: (val) => setModalState(() => isRecurring = val ?? false),
                        ),
                        const Text('🔄 Recurring Auto-Delivery', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    if (isRecurring) ...[
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        initialValue: recurringFreq,
                        items: ['Daily', 'Weekly', 'Monthly'].map((f) => DropdownMenuItem(value: f, child: Text('$f Subscription'))).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => recurringFreq = val);
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    CustomTextField(
                      label: 'Delivery Notes / Address details',
                      controller: notesCtrl,
                      hint: 'e.g. Call security on arrival',
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
                          setModalState(() {
                            isSaving = true;
                            dialogError = null;
                          });
                          try {
                            final qty = int.tryParse(qtyCtrl.text) ?? 1;
                            final price = double.tryParse(priceCtrl.text) ?? 35.0;
                            final order = OrderModel(
                              id: '',
                              customerId: selectedCustomer.id,
                              customerName: selectedCustomer.name,
                              phone: selectedCustomer.phone,
                              address: selectedCustomer.address,
                              quantity: qty,
                              unitPrice: price,
                              totalAmount: qty * price,
                              createdAt: DateTime.now(),
                              notes: notesCtrl.text.trim(),
                              priority: isPriority ? OrderPriority.high : OrderPriority.normal,
                              isRecurring: isRecurring,
                              recurringFrequency: isRecurring ? recurringFreq : 'None',
                              otpCode: '${1000 + DateTime.now().millisecond % 9000}',
                            );
                            await ref.read(orderProvider.notifier).createOrder(order);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Order created successfully!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() {
                              isSaving = false;
                              dialogError = 'Failed to create order: ${e.toString().replaceAll('Exception: ', '')}';
                            });
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create Order'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAssignDriverDialog(OrderModel order) {
    final employees = ref.read(employeeProvider);
    final drivers = employees.where((e) => e.role == UserRole.deliveryBoy).toList();
    if (drivers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No delivery drivers available. Add staff in Employee module.')),
      );
      return;
    }

    var selectedDriver = drivers.first;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('Assign Driver for ${order.id}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<EmployeeModel>(
                initialValue: selectedDriver,
                isExpanded: true,
                items: drivers.map((d) {
                  return DropdownMenuItem(
                    value: d,
                    child: Text(
                      '${d.name} (${d.phone})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: isSaving
                    ? null
                    : (val) {
                        if (val != null) selectedDriver = val;
                      },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setModalState(() => isSaving = true);
                      try {
                        await ref.read(orderProvider.notifier).updateStatus(
                              order.id,
                              OrderStatus.assigned,
                              driverId: selectedDriver.id,
                              driverName: selectedDriver.name,
                            );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Order assigned to ${selectedDriver.name} successfully!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setModalState(() => isSaving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Failed to assign driver: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteOrder(OrderModel order) {
    bool isDeleting = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Delete Order'),
          content: Text('Are you sure you want to delete order "${order.id}"?'),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
              onPressed: isDeleting
                  ? null
                  : () async {
                      setModalState(() => isDeleting = true);
                      try {
                        await ref.read(orderProvider.notifier).deleteOrder(order.id);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Order "${order.id}" deleted successfully!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setModalState(() => isDeleting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Error deleting order: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: isDeleting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isAdmin = user?.role == UserRole.admin;
    final orders = ref.watch(orderProvider);

    final driverOrders = isAdmin
        ? orders
        : orders.where((o) {
            if (o.assignedDriverId != null && o.assignedDriverId == user?.id) return true;
            if (o.assignedDriverName != null && user?.name != null && o.assignedDriverName!.toLowerCase().contains(user!.name.toLowerCase())) return true;
            return false;
          }).toList();

    final filtered = _statusFilter == null
        ? driverOrders
        : driverOrders.where((o) => o.status == _statusFilter).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              final filterRow = SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All Orders'),
                      selected: _statusFilter == null,
                      onSelected: (_) => setState(() => _statusFilter = null),
                    ),
                    const SizedBox(width: 8),
                    ...OrderStatus.values.map((status) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(status.displayName),
                          selected: _statusFilter == status,
                          onSelected: (_) => setState(() => _statusFilter = status),
                        ),
                      );
                    }),
                  ],
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isAdmin) ...[
                      CustomButton(
                        label: 'New Order',
                        icon: Icons.add_shopping_cart,
                        onPressed: () => _showCreateOrderDialog(),
                      ),
                      const SizedBox(height: 10),
                    ],
                    filterRow,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: filterRow),
                  if (isAdmin) ...[
                    const SizedBox(width: 12),
                    CustomButton(
                      label: 'New Order',
                      icon: Icons.add_shopping_cart,
                      width: 140,
                      onPressed: () => _showCreateOrderDialog(),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? EmptyStateWidget(
                    title: 'No Orders Found',
                    description: isAdmin ? 'Create a new order to dispatch water cans.' : 'No orders assigned to your route.',
                    buttonLabel: isAdmin ? 'Create Order' : null,
                    onButtonPressed: isAdmin ? () => _showCreateOrderDialog() : null,
                  )
                : RefreshIndicator(
                    onRefresh: () async => ref.read(orderProvider.notifier).refresh(),
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: CustomCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      item.id,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    StatusBadge(status: item.status),
                                    const Spacer(),
                                    Text(
                                      AppFormatters.formatCurrency(item.totalAmount),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item.customerName,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.water_drop, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text('${item.quantity} Cans'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item.address,
                                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (item.assignedDriverName != null) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.delivery_dining, size: 16, color: AppColors.info),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Driver: ${item.assignedDriverName}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.info),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (item.status == OrderStatus.pending)
                                      OutlinedButton.icon(
                                        onPressed: () => _showAssignDriverDialog(item),
                                        icon: const Icon(Icons.person_add, size: 16),
                                        label: const Text('Assign Driver'),
                                      ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                      onPressed: () => _confirmDeleteOrder(item),
                                      tooltip: 'Delete Order',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
