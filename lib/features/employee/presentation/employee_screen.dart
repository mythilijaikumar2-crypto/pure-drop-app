import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/role_badge.dart';
import '../../../models/employee_model.dart';
import '../../../providers/app_providers.dart';

class EmployeeScreen extends ConsumerStatefulWidget {
  const EmployeeScreen({super.key});

  @override
  ConsumerState<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends ConsumerState<EmployeeScreen> {
  void _showAddEmployeeDialog([EmployeeModel? employee]) {
    final nameCtrl = TextEditingController(text: employee?.name ?? '');
    final phoneCtrl = TextEditingController(text: employee?.phone ?? '');
    final salaryCtrl = TextEditingController(text: (employee?.baseSalary ?? 15000.0).toString());
    UserRole selectedRole = employee?.role ?? UserRole.deliveryBoy;
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text(employee == null ? 'Add New Staff / Driver' : 'Edit Employee'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(label: 'Full Name', controller: nameCtrl),
                    const SizedBox(height: 12),
                    CustomTextField(label: 'Phone Number', controller: phoneCtrl, keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<UserRole>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(labelText: 'Assign Role'),
                      items: UserRole.values.map((r) {
                        return DropdownMenuItem(value: r, child: Text(r.displayName));
                      }).toList(),
                      onChanged: isSaving
                          ? null
                          : (val) {
                              if (val != null) setModalState(() => selectedRole = val);
                            },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(label: 'Monthly Base Salary (₹)', controller: salaryCtrl, keyboardType: TextInputType.number),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setModalState(() => isSaving = true);
                          try {
                            final item = EmployeeModel(
                              id: employee?.id ?? '',
                              name: nameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              role: selectedRole,
                              baseSalary: double.tryParse(salaryCtrl.text) ?? 15000.0,
                              joiningDate: employee?.joiningDate ?? DateTime.now(),
                            );
                            await ref.read(employeeProvider.notifier).save(item);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ Staff "${item.name}" saved to Google Sheets!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('❌ Error saving staff: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Employee'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteEmployee(EmployeeModel employee) {
    bool isDeleting = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Delete Employee'),
          content: Text('Are you sure you want to delete "${employee.name}"? This will remove their record from Google Sheets.'),
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
                        await ref.read(employeeProvider.notifier).delete(employee.id);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Employee "${employee.name}" deleted from Google Sheets!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setModalState(() => isDeleting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Error deleting employee: $e'),
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
    final employees = ref.watch(employeeProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 450;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Employees & Delivery Staff',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    CustomButton(
                      label: 'Add Employee',
                      icon: Icons.person_add,
                      onPressed: () => _showAddEmployeeDialog(),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Employees & Delivery Staff',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CustomButton(
                    label: 'Add Employee',
                    icon: Icons.person_add,
                    width: 160,
                    onPressed: () => _showAddEmployeeDialog(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: employees.isEmpty
                ? EmptyStateWidget(
                    title: 'No Staff Registered',
                    description: 'Add delivery drivers and office staff members.',
                    buttonLabel: 'Add Staff',
                    onButtonPressed: () => _showAddEmployeeDialog(),
                  )
                : RefreshIndicator(
                    onRefresh: () => ref.read(employeeProvider.notifier).fetchLive(),
                    child: ListView.builder(
                      itemCount: employees.length,
                      itemBuilder: (context, index) {
                        final item = employees[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: InkWell(
                            onTap: () => _showEmployeeDetailsModal(item),
                            borderRadius: BorderRadius.circular(16),
                            child: CustomCard(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primaryLight,
                                  child: Icon(
                                    item.role == UserRole.admin ? Icons.admin_panel_settings : Icons.delivery_dining,
                                    color: AppColors.primary,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    RoleBadge(role: item.role),
                                  ],
                                ),
                                subtitle: Text(
                                  '${item.phone} • Base Salary: ${AppFormatters.formatCurrency(item.baseSalary)}/mo',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                                      onPressed: () => _showAddEmployeeDialog(item),
                                      tooltip: 'Edit Staff',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                      onPressed: () => _confirmDeleteEmployee(item),
                                      tooltip: 'Delete Staff',
                                    ),
                                  ],
                                ),
                              ),
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

  void _showEmployeeDetailsModal(EmployeeModel employee) {
    final allOrders = ref.read(orderProvider);
    final assignedOrders = allOrders.where((o) {
      if (o.assignedDriverId != null && o.assignedDriverId == employee.id) return true;
      if (o.assignedDriverName != null && o.assignedDriverName!.toLowerCase().contains(employee.name.toLowerCase())) return true;
      return false;
    }).toList();

    final pendingAssigned = assignedOrders.where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled).toList();
    final completedAssigned = assignedOrders.where((o) => o.status == OrderStatus.delivered).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.82,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
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
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(
                    employee.role == UserRole.admin ? Icons.admin_panel_settings : Icons.delivery_dining,
                    size: 28,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              employee.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          RoleBadge(role: employee.role),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${employee.id.isEmpty ? "EMP-101" : employee.id} • Joined: ${AppFormatters.formatDate(employee.joiningDate)}',
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse('tel:${employee.phone}');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                    icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                    label: const Text('Call Staff', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final clean = employee.phone.replaceAll(RegExp(r'\D'), '');
                      final uri = Uri.parse('https://wa.me/91$clean?text=Hello%20${employee.name}');
                      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    icon: const Icon(Icons.chat_sharp, size: 18),
                    label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showAddEmployeeDialog(employee);
                    },
                    icon: const Icon(Icons.edit_note_rounded, size: 20),
                    label: const Text('Edit Staff', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    label: 'Assigned Orders',
                    value: '${assignedOrders.length} Total',
                    icon: Icons.assignment_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Pending Active',
                    value: '${pendingAssigned.length} Pending',
                    icon: Icons.pending_actions,
                    color: pendingAssigned.isNotEmpty ? AppColors.warning : AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    label: 'Deliveries Done',
                    value: '${completedAssigned.length} Done',
                    icon: Icons.task_alt,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Monthly Base Salary',
                    value: AppFormatters.formatCompactCurrency(employee.baseSalary),
                    icon: Icons.badge_outlined,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Assigned Orders List (${assignedOrders.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${pendingAssigned.length} Pending',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: pendingAssigned.isNotEmpty ? AppColors.warning : AppColors.success),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: assignedOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          const Text(
                            'No orders assigned to this delivery staff today',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: assignedOrders.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final order = assignedOrders[index];
                        final isDelivered = order.status == OrderStatus.delivered;

                        return CustomCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isDelivered ? AppColors.successLight : AppColors.warningLight,
                                radius: 18,
                                child: Icon(
                                  isDelivered ? Icons.check_circle_outline : Icons.local_shipping_outlined,
                                  color: isDelivered ? AppColors.success : AppColors.warning,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.customerName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${order.quantity} Cans • ₹${order.totalAmount} • ${order.address}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDelivered ? AppColors.successLight : AppColors.warningLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  order.status.displayName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDelivered ? AppColors.success : AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
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

  Widget _buildMetricCard({
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
