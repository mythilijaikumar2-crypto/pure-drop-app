import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/customer_model.dart';
import '../../../providers/app_providers.dart';

class CustomerScreen extends ConsumerStatefulWidget {
  const CustomerScreen({super.key});

  @override
  ConsumerState<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends ConsumerState<CustomerScreen> {
  String _searchQuery = '';

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

  void _showAddEditCustomerDialog([CustomerModel? customer]) {
    final nameCtrl = TextEditingController(text: customer?.name ?? '');
    final phoneCtrl = TextEditingController(text: customer?.phone ?? '');
    final whatsappCtrl = TextEditingController(text: customer?.whatsappNumber ?? customer?.phone ?? '');
    final addressCtrl = TextEditingController(text: customer?.address ?? '');
    final priceCtrl = TextEditingController(text: (customer?.canPrice ?? 35.0).toString());
    final balanceCtrl = TextEditingController(text: (customer?.canBalance ?? 0).toString());
    final duesCtrl = TextEditingController(text: (customer?.pendingDues ?? 0.0).toString());
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(customer == null ? 'Add New Customer' : 'Edit Customer'),
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
                    hint: 'Enter WhatsApp number',
                    prefixIcon: Icons.chat_bubble_outline,
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
                          validator: (v) => AppValidators.positiveNumber(v, fieldName: 'Price'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomTextField(
                          label: 'Can Balance',
                          controller: balanceCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) => AppValidators.integer(v, fieldName: 'Balance'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Pending Dues (₹)',
                    controller: duesCtrl,
                    keyboardType: TextInputType.number,
                    validator: (v) => AppValidators.positiveNumber(v, fieldName: 'Dues'),
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
                        setDialogState(() {
                          isSaving = true;
                          dialogError = null;
                        });
                        try {
                          final model = CustomerModel(
                            id: customer?.id ?? '',
                            name: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            whatsappNumber: whatsappCtrl.text.trim(),
                            address: addressCtrl.text.trim(),
                            canPrice: double.parse(priceCtrl.text),
                            canBalance: int.parse(balanceCtrl.text),
                            pendingDues: double.parse(duesCtrl.text),
                          );
                          await ref.read(customerProvider.notifier).addOrUpdate(model);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ ${model.name} saved to Google Sheets!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() {
                            isSaving = false;
                            dialogError = 'Failed to save to Google Sheets: ${e.toString().replaceAll('Exception: ', '')}';
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
                  : const Text('Save Customer'),
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
          title: const Text('Delete Customer'),
          content: Text('Are you sure you want to delete "${customer.name}"? This row will be removed from Google Sheets.'),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: isDeleting
                  ? null
                  : () async {
                      setDialogState(() => isDeleting = true);
                      try {
                        await ref.read(customerProvider.notifier).delete(customer.id);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Customer "${customer.name}" deleted from Google Sheets!'),
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
    final filtered = customers.where((c) {
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.phone.contains(q) ||
          c.address.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 450;
              if (isNarrow) {
                return Column(
                  children: [
                    CustomTextField(
                      label: '',
                      hint: 'Search by name, phone...',
                      prefixIcon: Icons.search,
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    const SizedBox(height: 8),
                    CustomButton(
                      label: 'Add Customer',
                      icon: Icons.person_add,
                      onPressed: () => _showAddEditCustomerDialog(),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: '',
                      hint: 'Search by name, phone or address...',
                      prefixIcon: Icons.search,
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CustomButton(
                    label: 'Add Customer',
                    icon: Icons.person_add,
                    width: 160,
                    onPressed: () => _showAddEditCustomerDialog(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? EmptyStateWidget(
                    title: 'No Customers Found',
                    description: 'Add your first customer to manage water distribution.',
                    buttonLabel: 'Add Customer',
                    onButtonPressed: () => _showAddEditCustomerDialog(),
                  )
                : RefreshIndicator(
                    onRefresh: () async => ref.read(customerProvider.notifier).refresh(),
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: InkWell(
                            onTap: () => _showCustomerDetailsModal(item),
                            borderRadius: BorderRadius.circular(16),
                            child: CustomCard(
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primaryLight,
                                    child: Text(
                                      item.name.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${item.phone} • ${item.address}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryLight,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '${item.canBalance} Cans Held',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.primaryDark,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            if (item.pendingDues > 0)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.errorLight,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'Dues: ${AppFormatters.formatCompactCurrency(item.pendingDues)}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.error,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.phone, color: AppColors.success),
                                        onPressed: () => _makeCall(item.phone),
                                        tooltip: 'Call Customer',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366)),
                                        onPressed: () => _openWhatsApp(item.phone, item.whatsappNumber),
                                        tooltip: 'WhatsApp',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                                        onPressed: () => _showAddEditCustomerDialog(item),
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                        onPressed: () => _confirmDeleteCustomer(item),
                                        tooltip: 'Delete',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showCustomerDetailsModal(CustomerModel customer) {
    final allOrders = ref.read(orderProvider);
    final customerOrders = allOrders
        .where((o) => o.customerId == customer.id || o.customerName.toLowerCase() == customer.name.toLowerCase())
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      customer.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Active Account • ${customer.phone}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _makeCall(customer.phone),
                      icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                      label: const Text('Call', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openWhatsApp(customer.phone, customer.whatsappNumber),
                      icon: const Icon(Icons.chat_sharp, size: 18),
                      label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddEditCustomerDialog(customer);
                      },
                      icon: const Icon(Icons.edit_note_rounded, size: 20),
                      label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/orders');
                  },
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                  label: const Text('Create New Order for Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Account Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailCard(
                      label: 'Cans Balance',
                      value: '${customer.canBalance} Cans',
                      icon: Icons.inventory_2_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDetailCard(
                      label: 'Can Unit Price',
                      value: '₹${customer.canPrice}',
                      icon: Icons.sell_outlined,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailCard(
                      label: 'Pending Dues',
                      value: AppFormatters.formatCompactCurrency(customer.pendingDues),
                      icon: Icons.warning_amber_rounded,
                      color: customer.pendingDues > 0 ? AppColors.error : AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDetailCard(
                      label: 'Total Orders',
                      value: '${customerOrders.length} Orders',
                      icon: Icons.local_shipping_outlined,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text('Contact & Address', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              CustomCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.phone_iphone, size: 18, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Phone Number', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Text(customer.phone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                    if (customer.whatsappNumber.isNotEmpty) ...[
                      const Divider(height: 14),
                      Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF25D366)),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('WhatsApp Number', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(customer.whatsappNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 18, color: AppColors.error),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Delivery Address', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(
                                customer.address,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return CustomCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text(
                  value,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
