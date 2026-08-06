import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/customer_model.dart';
import '../../../models/delivery_model.dart';
import '../../../providers/app_providers.dart';
import 'widgets/customer_card_widget.dart';
import 'widgets/customer_filter_bottom_sheet.dart';
import 'widgets/customer_search_header.dart';
import 'widgets/customer_statistics_section.dart';

class CustomerScreen extends ConsumerStatefulWidget {
  const CustomerScreen({super.key});

  @override
  ConsumerState<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends ConsumerState<CustomerScreen> {
  String _searchQuery = '';
  CustomerFilterOptions _filterOptions = CustomerFilterOptions();

  void _showAddCustomerDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final whatsappCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '35.0');
    final balanceCtrl = TextEditingController(text: '0');
    final emptyPendingCtrl = TextEditingController(text: '0');
    final duesCtrl = TextEditingController(text: '0.0');
    final depositCtrl = TextEditingController(text: '160.0');
    final notesCtrl = TextEditingController();
    bool isActive = true;
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Add New Customer',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
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
                          label: 'Security Deposit (₹)',
                          controller: depositCtrl,
                          keyboardType: TextInputType.number,
                          hint: '160',
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
                          validator: (v) => AppValidators.integer(v, fieldName: 'Cans'),
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
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Pending Dues (₹)',
                          controller: duesCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) => AppValidators.positiveNumber(v, fieldName: 'Dues'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Customer Notes',
                    controller: notesCtrl,
                    hint: 'Special instructions or landmarks',
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
                          final model = CustomerModel(
                            id: '',
                            name: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            whatsappNumber: whatsappCtrl.text.trim(),
                            address: addressCtrl.text.trim(),
                            canPrice: double.tryParse(priceCtrl.text) ?? 35.0,
                            canBalance: int.tryParse(balanceCtrl.text) ?? 0,
                            emptyCansPending: int.tryParse(emptyPendingCtrl.text) ?? 0,
                            pendingDues: double.tryParse(duesCtrl.text) ?? 0.0,
                            securityDeposit: double.tryParse(depositCtrl.text) ?? 160.0,
                            notes: notesCtrl.text.trim(),
                            isActive: isActive,
                          );
                          await ref.read(customerProvider.notifier).addOrUpdate(model);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ Customer "${model.name}" saved successfully!'),
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
                  : const Text('Save Customer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAdmin = authState.user?.role == UserRole.admin || authState.user?.role == UserRole.superAdmin;
    final customers = ref.watch(customerProvider);
    final allDeliveries = ref.watch(deliveryProvider);

    // Compute metrics for Statistics section
    final totalCustomers = customers.length;
    final activeCustomers = customers.where((c) => c.isActive).length;
    final inactiveCustomers = totalCustomers - activeCustomers;
    final totalPendingDues = customers.fold<double>(0.0, (sum, c) => sum + c.pendingDues);
    final todaysDeliveries = allDeliveries.where((d) =>
      d.deliveryDate.year == DateTime.now().year &&
      d.deliveryDate.month == DateTime.now().month &&
      d.deliveryDate.day == DateTime.now().day
    ).length;

    // Apply Filter & Search
    final filtered = customers.where((c) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = c.name.toLowerCase().contains(q) ||
          c.phone.contains(q) ||
          c.address.toLowerCase().contains(q);

      final matchesStatus = _filterOptions.statusFilter == 'all' ||
          (_filterOptions.statusFilter == 'active' && c.isActive) ||
          (_filterOptions.statusFilter == 'inactive' && !c.isActive);

      final matchesArea = _filterOptions.areaQuery.isEmpty ||
          c.address.toLowerCase().contains(_filterOptions.areaQuery.toLowerCase());

      return matchesSearch && matchesStatus && matchesArea;
    }).toList();

    // Apply Sorting
    switch (_filterOptions.sortOption) {
      case CustomerSortOption.nameAsc:
        filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case CustomerSortOption.newest:
        filtered.sort((a, b) => b.id.compareTo(a.id));
        break;
      case CustomerSortOption.highestDue:
        filtered.sort((a, b) => b.pendingDues.compareTo(a.pendingDues));
        break;
      case CustomerSortOption.mostActive:
        filtered.sort((a, b) => b.canBalance.compareTo(a.canBalance));
        break;
    }

    final hasActiveFilters = _filterOptions.statusFilter != 'all' ||
        _filterOptions.areaQuery.isNotEmpty ||
        _filterOptions.sortOption != CustomerSortOption.nameAsc;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isDesktop = width >= 1024;
          final isTablet = width >= 600 && width < 1024;
          final horizontalPadding = isDesktop ? 28.0 : isTablet ? 20.0 : 16.0;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
            child: Column(
              children: [
                // ── Search & Actions Header ─────────────────────────────────────────
                CustomerSearchHeader(
                  onSearchChanged: (v) => setState(() => _searchQuery = v),
                  onOpenFilter: () {
                    CustomerFilterBottomSheet.show(
                      context,
                      currentOptions: _filterOptions,
                      onApply: (opts) => setState(() => _filterOptions = opts),
                    );
                  },
                  onAddCustomer: () => _showAddCustomerDialog(),
                  isAdmin: isAdmin,
                  hasActiveFilters: hasActiveFilters,
                ),
                const SizedBox(height: 14),

                // ── Key Statistics Section ──────────────────────────────────────────
                CustomerStatisticsSection(
                  totalCustomers: totalCustomers,
                  activeCustomers: activeCustomers,
                  inactiveCustomers: inactiveCustomers,
                  todaysDeliveries: todaysDeliveries,
                  totalPendingDues: totalPendingDues,
                ),

                // ── Adaptive Customer Browser List / Grid View ───────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyStateWidget(
                          title: 'No Customers Found',
                          description: isAdmin
                              ? 'Add your first customer to manage water distribution.'
                              : 'No customer records match your filter criteria.',
                          buttonLabel: isAdmin ? 'Add Customer' : null,
                          onButtonPressed: isAdmin ? () => _showAddCustomerDialog() : null,
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () async => ref.read(customerProvider.notifier).refresh(),
                          child: isDesktop
                              ? _buildGridList(context, filtered, allDeliveries, crossAxisCount: 3)
                              : isTablet
                                  ? _buildGridList(context, filtered, allDeliveries, crossAxisCount: 2)
                                  : _buildMobileList(context, filtered, allDeliveries),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileList(
    BuildContext context,
    List<CustomerModel> list,
    List<DeliveryModel> allDeliveries,
  ) {
    return ListView.builder(
      itemCount: list.length,
      padding: const EdgeInsets.only(top: 4, bottom: 20),
      itemBuilder: (context, index) {
        final item = list[index];
        final customerDeliveries = allDeliveries
            .where((d) => d.customerId == item.id || d.customerName.toLowerCase() == item.name.toLowerCase())
            .toList();
        final lastDelivery = customerDeliveries.isNotEmpty ? customerDeliveries.first : null;

        return CustomerCardWidget(
          customer: item,
          lastDelivery: lastDelivery,
          onTapCard: () => context.push('/customer/profile/${item.id}'),
        );
      },
    );
  }

  Widget _buildGridList(
    BuildContext context,
    List<CustomerModel> list,
    List<DeliveryModel> allDeliveries, {
    required int crossAxisCount,
  }) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 185, // Compact height extent for browser cards without action rows
      ),
      itemCount: list.length,
      padding: const EdgeInsets.only(top: 4, bottom: 20),
      itemBuilder: (context, index) {
        final item = list[index];
        final customerDeliveries = allDeliveries
            .where((d) => d.customerId == item.id || d.customerName.toLowerCase() == item.name.toLowerCase())
            .toList();
        final lastDelivery = customerDeliveries.isNotEmpty ? customerDeliveries.first : null;

        return CustomerCardWidget(
          customer: item,
          lastDelivery: lastDelivery,
          onTapCard: () => context.push('/customer/profile/${item.id}'),
        );
      },
    );
  }
}
