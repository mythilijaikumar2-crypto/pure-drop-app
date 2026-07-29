import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  void _openWhatsApp(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
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
    final addressCtrl = TextEditingController(text: customer?.address ?? '');
    final priceCtrl = TextEditingController(text: (customer?.canPrice ?? 35.0).toString());
    final balanceCtrl = TextEditingController(text: (customer?.canBalance ?? 0).toString());
    final duesCtrl = TextEditingController(text: (customer?.pendingDues ?? 0.0).toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer == null ? 'Add New Customer' : 'Edit Customer'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final model = CustomerModel(
                  id: customer?.id ?? '',
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  address: addressCtrl.text.trim(),
                  canPrice: double.parse(priceCtrl.text),
                  canBalance: int.parse(balanceCtrl.text),
                  pendingDues: double.parse(duesCtrl.text),
                );
                ref.read(customerProvider.notifier).addOrUpdate(model);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${model.name} saved successfully!')),
                );
              }
            },
            child: const Text('Save Customer'),
          ),
        ],
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
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
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
                                    onPressed: () => _openWhatsApp(item.phone),
                                    tooltip: 'WhatsApp',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                                    onPressed: () => _showAddEditCustomerDialog(item),
                                    tooltip: 'Edit',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
