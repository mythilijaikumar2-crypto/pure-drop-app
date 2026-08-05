import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../models/customer_model.dart';
import '../../../models/delivery_model.dart';
import '../../../models/order_model.dart';
import '../../../models/payment_model.dart';
import '../../../providers/app_providers.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerProfileScreen({
    super.key,
    required this.customerId,
  });

  @override
  ConsumerState<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openWhatsApp(String phone, [String? whatsappNumber]) async {
    final target = (whatsappNumber != null && whatsappNumber.isNotEmpty) ? whatsappNumber : phone;
    final clean = target.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/91$clean?text=Hello%20from%20Pure%20Drop%20Aqua');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openGoogleMaps(String address, double lat, double lng) async {
    final String query = (lat != 0.0 && lng != 0.0) ? '$lat,$lng' : Uri.encodeComponent(address);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showAddEditCustomerDialog(CustomerModel customer) {
    final nameCtrl = TextEditingController(text: customer.name);
    final phoneCtrl = TextEditingController(text: customer.phone);
    final whatsappCtrl = TextEditingController(text: customer.whatsappNumber);
    final addressCtrl = TextEditingController(text: customer.address);
    final priceCtrl = TextEditingController(text: customer.canPrice.toString());
    final balanceCtrl = TextEditingController(text: customer.canBalance.toString());
    final emptyPendingCtrl = TextEditingController(text: customer.emptyCansPending.toString());
    final duesCtrl = TextEditingController(text: customer.pendingDues.toString());
    final depositCtrl = TextEditingController(text: customer.securityDeposit.toString());
    final notesCtrl = TextEditingController(text: customer.notes);
    bool isActive = customer.isActive;
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Customer', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  CustomTextField(
                    label: 'Customer / Business Name',
                    controller: nameCtrl,
                    validator: (v) => AppValidators.required(v, fieldName: 'Customer Name'),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Phone Number',
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    validator: AppValidators.phone,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'WhatsApp Number',
                    controller: whatsappCtrl,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Delivery Address',
                    controller: addressCtrl,
                    maxLines: 2,
                    validator: (v) => AppValidators.required(v, fieldName: 'Address'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Can Price (₹)',
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomTextField(
                          label: 'Security Deposit (₹)',
                          controller: depositCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Active Cans Held',
                          controller: balanceCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomTextField(
                          label: 'Empty Cans Pending',
                          controller: emptyPendingCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Pending Dues (₹)',
                    controller: duesCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Customer Notes',
                    controller: notesCtrl,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      ChoiceChip(
                        label: const Text('Active'),
                        selected: isActive,
                        onSelected: (val) => setDialogState(() => isActive = true),
                        selectedColor: AppColors.successLight,
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Inactive'),
                        selected: !isActive,
                        onSelected: (val) => setDialogState(() => isActive = false),
                      ),
                    ],
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setDialogState(() {
                          isSaving = true;
                          dialogError = null;
                        });
                        try {
                          final model = customer.copyWith(
                            name: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            whatsappNumber: whatsappCtrl.text.trim(),
                            address: addressCtrl.text.trim(),
                            canPrice: double.tryParse(priceCtrl.text) ?? customer.canPrice,
                            canBalance: int.tryParse(balanceCtrl.text) ?? customer.canBalance,
                            emptyCansPending: int.tryParse(emptyPendingCtrl.text) ?? customer.emptyCansPending,
                            pendingDues: double.tryParse(duesCtrl.text) ?? customer.pendingDues,
                            securityDeposit: double.tryParse(depositCtrl.text) ?? customer.securityDeposit,
                            notes: notesCtrl.text.trim(),
                            isActive: isActive,
                          );
                          await ref.read(customerProvider.notifier).addOrUpdate(model);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ Customer "${model.name}" updated successfully!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() {
                            isSaving = false;
                            dialogError = 'Failed to save customer: ${e.toString().replaceAll('Exception: ', '')}';
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
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCustomer(CustomerModel customer) {
    bool isDeleting = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Customer'),
          content: Text('Are you sure you want to delete "${customer.name}"? This record will be deleted.'),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isDeleting
                  ? null
                  : () async {
                      setDialogState(() => isDeleting = true);
                      try {
                        await ref.read(customerProvider.notifier).delete(customer.id);
                        if (context.mounted) {
                          Navigator.pop(context); // close dialog
                          context.pop(); // navigate back to customer list
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Customer "${customer.name}" deleted successfully!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isDeleting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Error deleting customer: ${e.toString().replaceAll('Exception: ', '')}'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customerProvider);
    final customer = customers.firstWhere(
      (c) => c.id == widget.customerId,
      orElse: () => CustomerModel(id: widget.customerId, name: 'Unknown Customer', phone: '', address: ''),
    );

    final authState = ref.watch(authProvider);
    final isAdmin = authState.user?.role == UserRole.admin;

    final allOrders = ref.watch(orderProvider);
    final customerOrders = allOrders.where((o) => o.customerId == customer.id || o.customerName.toLowerCase() == customer.name.toLowerCase()).toList();

    final allDeliveries = ref.watch(deliveryProvider);
    final customerDeliveries = allDeliveries.where((d) => d.customerId == customer.id || d.customerName.toLowerCase() == customer.name.toLowerCase()).toList();

    final allPayments = ref.watch(paymentProvider);
    final customerPayments = allPayments.where((p) => p.customerId == customer.id || p.customerName.toLowerCase() == customer.name.toLowerCase()).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          if (isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: AppColors.warning),
              onPressed: () => _showAddEditCustomerDialog(customer),
              tooltip: 'Edit Customer',
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: AppColors.error),
              onPressed: () => _confirmDeleteCustomer(customer),
              tooltip: 'Delete Customer',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // ── Top Header Section ───────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Hero(
                      tag: 'customer_avatar_${customer.id}',
                      child: CircleAvatar(
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
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          SelectableText(
                            customer.phone,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                          ),
                          const SizedBox(height: 4),
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
                              Text('ID: ${customer.id}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Customer Action Buttons Suite ────────────────────────────────
                Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.phone_rounded,
                      label: 'Call',
                      color: AppColors.success,
                      backgroundColor: AppColors.successLight,
                      onTap: () => _makeCall(customer.phone),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.chat_rounded,
                      label: 'WhatsApp',
                      color: const Color(0xFF25D366),
                      backgroundColor: const Color(0xFFE8F9F0),
                      onTap: () => _openWhatsApp(customer.phone, customer.whatsappNumber),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.location_on_rounded,
                      label: 'Maps',
                      color: AppColors.primaryDark,
                      backgroundColor: AppColors.primaryLight,
                      onTap: () => _openGoogleMaps(customer.address, customer.latitude, customer.longitude),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        label: 'Create Order',
                        icon: Icons.add_shopping_cart_rounded,
                        onPressed: () => context.go('/orders'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: const BorderSide(color: AppColors.success),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.payments_rounded, size: 18),
                        label: const Text('Collect Payment'),
                        onPressed: () => context.go('/payments'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryDark,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: "Overview"),
                Tab(text: "Orders"),
                Tab(text: "Deliveries"),
                Tab(text: "Payments"),
              ],
            ),
          ),

          // Tab Views Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(context, customer, customerOrders, customerDeliveries, customerPayments),
                _buildOrdersTab(customerOrders),
                _buildDeliveriesTab(customerDeliveries),
                _buildPaymentsTab(customerPayments),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    CustomerModel customer,
    List<OrderModel> orders,
    List<DeliveryModel> deliveries,
    List<PaymentModel> payments,
  ) {
    final lastDelivery = deliveries.isNotEmpty ? deliveries.first : null;
    final lastPayment = payments.isNotEmpty ? payments.first : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Customer Information
          _buildSectionHeader('Customer Information', Icons.person_outline_rounded),
          const SizedBox(height: 10),
          _buildCardContainer([
            _buildInfoRow('Full Name', customer.name),
            _buildInfoRow('Customer ID', customer.id),
            _buildInfoRow('Mobile Number', customer.phone, isSelectable: true),
            if (customer.whatsappNumber.isNotEmpty)
              _buildInfoRow('WhatsApp Number', customer.whatsappNumber, isSelectable: true),
            _buildInfoRow('Delivery Address', customer.address),
            _buildInfoRow('Notes', customer.notes.isNotEmpty ? customer.notes : 'No custom notes set'),
          ]),
          const SizedBox(height: 20),

          // Section 2: Subscription & Pricing
          _buildSectionHeader('Subscription & Pricing', Icons.water_drop_outlined),
          const SizedBox(height: 10),
          _buildCardContainer([
            _buildInfoRow('Can Price', '₹${customer.canPrice.toStringAsFixed(0)} per can'),
            _buildInfoRow('Security Deposit', '₹${customer.securityDeposit.toStringAsFixed(0)}'),
            _buildInfoRow('Subscription Plan', 'Standard Daily/Weekly Supply'),
            _buildInfoRow('Assigned Delivery Boy', 'Default Route Staff'),
          ]),
          const SizedBox(height: 20),

          // Section 3: Key Statistics
          _buildSectionHeader('Key Statistics', Icons.analytics_outlined),
          const SizedBox(height: 10),
          _buildCardContainer([
            _buildInfoRow('Water Can Balance', '${customer.canBalance} Cans Held'),
            _buildInfoRow('Outstanding Empty Cans', '${customer.emptyCansPending} Cans Pending'),
            _buildInfoRow('Pending Dues', AppFormatters.formatCurrency(customer.pendingDues), isHighlight: customer.pendingDues > 0),
            _buildInfoRow('Total Orders Placed', '${orders.length} Orders'),
            _buildInfoRow('Completed Deliveries', '${deliveries.length} Deliveries'),
            _buildInfoRow('Last Delivery Date', lastDelivery != null ? AppFormatters.formatDateTime(lastDelivery.deliveryDate) : 'No deliveries recorded'),
            _buildInfoRow('Last Payment Date', lastPayment != null ? AppFormatters.formatDateTime(lastPayment.date) : 'No payments recorded'),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOrdersTab(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return const Center(
        child: Text('No orders found for this customer.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text('Order #${order.id} • ${order.quantity} Cans', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Date: ${AppFormatters.formatDateTime(order.createdAt)} • Status: ${order.status.name.toUpperCase()}'),
            trailing: Text(AppFormatters.formatCurrency(order.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
          ),
        );
      },
    );
  }

  Widget _buildDeliveriesTab(List<DeliveryModel> deliveries) {
    if (deliveries.isEmpty) {
      return const Center(
        child: Text('No delivery history recorded for this customer.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: deliveries.length,
      itemBuilder: (context, index) {
        final d = deliveries[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text('${d.quantity} Cans Delivered', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Date: ${AppFormatters.formatDateTime(d.deliveryDate)} | Driver: ${d.employeeName.isNotEmpty ? d.employeeName : "System"}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: d.deliveryStatus == 'delivered' ? AppColors.successLight : AppColors.warningLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                d.deliveryStatus.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: d.deliveryStatus == 'delivered' ? AppColors.success : AppColors.warning,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentsTab(List<PaymentModel> payments) {
    if (payments.isEmpty) {
      return const Center(
        child: Text('No payment transactions recorded.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final p = payments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text('Payment #${p.id} • ${p.paymentMode.displayName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Date: ${AppFormatters.formatDateTime(p.date)}'),
            trailing: Text(
              AppFormatters.formatCurrency(p.amount),
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 15),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isSelectable = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            flex: 3,
            child: isSelectable
                ? SelectableText(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isHighlight ? AppColors.error : AppColors.textPrimary,
                    ),
                  )
                : Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isHighlight ? AppColors.error : AppColors.textPrimary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
