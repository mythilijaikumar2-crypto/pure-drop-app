import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    showDialog(
      context: context,
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
                      onChanged: (val) {
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
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final item = EmployeeModel(
                      id: employee?.id ?? '',
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      role: selectedRole,
                      baseSalary: double.tryParse(salaryCtrl.text) ?? 15000.0,
                      joiningDate: employee?.joiningDate ?? DateTime.now(),
                    );
                    ref.read(employeeProvider.notifier).save(item);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item.name} saved!')),
                    );
                  }
                },
                child: const Text('Save Employee'),
              ),
            ],
          );
        },
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
                : ListView.builder(
                    itemCount: employees.length,
                    itemBuilder: (context, index) {
                      final item = employees[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
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
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                              onPressed: () => _showAddEmployeeDialog(item),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
