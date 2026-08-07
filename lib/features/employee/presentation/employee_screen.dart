import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/role_badge.dart';
import '../../../models/employee_model.dart';
import '../../../providers/app_providers.dart';

import '../../../core/services/auth_service.dart';

class EmployeeScreen extends ConsumerStatefulWidget {
  const EmployeeScreen({super.key});

  @override
  ConsumerState<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends ConsumerState<EmployeeScreen> {
  String _searchQuery = '';
  UserRole? _roleFilter;

  void _showAddEmployeeDialog([EmployeeModel? employee]) async {
    final empRepo = ref.read(employeeRepositoryProvider);
    final String autoId = (employee != null && employee.id.isNotEmpty)
        ? employee.id
        : await empRepo.generateNextEmployeeId();

    final nameCtrl = TextEditingController(text: employee?.name ?? '');
    final usernameCtrl = TextEditingController(text: employee?.username ?? '');
    final passwordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: employee?.phone ?? '');
    final addressCtrl = TextEditingController(text: employee?.address ?? '');
    final salaryCtrl = TextEditingController(text: (employee?.baseSalary ?? 15000.0).toString());
    UserRole selectedRole = employee?.role ?? UserRole.deliveryBoy;
    bool isActive = employee?.isActive ?? true;
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text(employee == null ? 'Create Employee ($autoId)' : 'Edit Employee Details'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(
                      label: 'Employee ID (Auto)',
                      controller: TextEditingController(text: autoId),
                      enabled: false,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Employee Name',
                      controller: nameCtrl,
                      validator: (v) => AppValidators.required(v, fieldName: 'Employee Name'),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Username',
                      controller: usernameCtrl,
                      validator: (v) => v == null || v.trim().length < 4 ? 'Username min 4 characters' : null,
                    ),
                    const SizedBox(height: 12),
                    if (employee == null) ...[
                      CustomTextField(
                        label: 'Password',
                        controller: passwordCtrl,
                        obscureText: true,
                        validator: (v) => v == null || v.trim().length < 6 ? 'Password min 6 characters' : null,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'Confirm Password',
                        controller: confirmPasswordCtrl,
                        obscureText: true,
                        validator: (v) => v != passwordCtrl.text ? 'Passwords do not match' : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    CustomTextField(
                      label: 'Phone Number',
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      validator: AppValidators.phone,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Address',
                      controller: addressCtrl,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<UserRole>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(labelText: 'System Access Role'),
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
                    CustomTextField(
                      label: 'Monthly Base Salary (₹)',
                      controller: salaryCtrl,
                      keyboardType: TextInputType.number,
                      validator: (v) => AppValidators.positiveNumber(v, fieldName: 'Salary'),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Account Status (Active / Inactive)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: Text(isActive ? 'Status: Active (Allowed to login)' : 'Status: Inactive (Login blocked)', style: TextStyle(fontSize: 11, color: isActive ? AppColors.success : AppColors.error)),
                      value: isActive,
                      activeTrackColor: AppColors.successLight,
                      activeThumbColor: AppColors.success,
                      onChanged: isSaving
                          ? null
                          : (val) {
                              setModalState(() => isActive = val);
                            },
                    ),
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
                            String uid = autoId;
                            // 1. Create local Auth user & profile if new
                            if (employee == null) {
                              try {
                                final authService = AuthService();
                                final userMap = {
                                  'employeeId': autoId,
                                  'username': usernameCtrl.text.trim(),
                                  'name': nameCtrl.text.trim(),
                                  'phone': phoneCtrl.text.trim(),
                                  'address': addressCtrl.text.trim(),
                                  'role': selectedRole == UserRole.admin ? 'admin' : 'deliveryBoy',
                                  'status': isActive ? 'Active' : 'Inactive',
                                  'createdAt': DateTime.now().toIso8601String(),
                                  'updatedAt': DateTime.now().toIso8601String(),
                                };
                                final createdMap = await authService.createLocalAccount(
                                  usernameCtrl.text.trim(),
                                  passwordCtrl.text.trim(),
                                  userMap,
                                );
                                uid = createdMap['uid'] ?? autoId;
                              } catch (_) {}
                            }

                            final item = EmployeeModel(
                              id: uid,
                              name: nameCtrl.text.trim(),
                              username: usernameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              address: addressCtrl.text.trim(),
                              role: selectedRole,
                              baseSalary: double.tryParse(salaryCtrl.text) ?? 15000.0,
                              joiningDate: employee?.joiningDate ?? DateTime.now(),
                              isActive: isActive,
                            );

                            await ref.read(employeeProvider.notifier).save(item);

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ Employee "$autoId" (${item.name}) saved successfully!'),
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
          content: Text('Are you sure you want to delete "${employee.name}"? This will remove their record from local & cloud database.'),
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
                              content: Text('✅ Employee "${employee.name}" deleted successfully!'),
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

  void _showIdCardDialog(EmployeeModel employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Text(
                    AppConstants.appName.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'AUTHORIZED STAFF IDENTIFICATION CARD',
                    style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 14),
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 33,
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(
                        employee.role == UserRole.admin ? Icons.admin_panel_settings : Icons.delivery_dining,
                        size: 36,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    employee.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  RoleBadge(role: employee.role),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _idRow('Employee ID', employee.id.isEmpty ? 'EMP-101' : employee.id),
                        const Divider(height: 12),
                        _idRow('Phone Number', employee.phone),
                        const Divider(height: 12),
                        _idRow('Joined Date', AppFormatters.formatDate(employee.joiningDate)),
                        const Divider(height: 12),
                        _idRow('Monthly Salary', AppFormatters.formatCurrency(employee.baseSalary)),
                        const Divider(height: 12),
                        _idRow('Status', employee.isActive ? 'Active Staff' : 'Inactive'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () => _printStaffIdCardPdf(employee),
            icon: const Icon(Icons.print, size: 18),
            label: const Text('Print Staff ID'),
          ),
        ],
      ),
    );
  }

  Widget _idRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Future<void> _printStaffIdCardPdf(EmployeeModel employee) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue800, width: 2),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(AppConstants.appName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                pw.Text('OFFICIAL EMPLOYEE ID CARD', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text(employee.name, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Role: ${employee.role.displayName}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  headers: ['Attribute', 'Details'],
                  data: [
                    ['Employee ID', employee.id.isEmpty ? 'EMP-101' : employee.id],
                    ['Phone', employee.phone],
                    ['Joined', AppFormatters.formatDate(employee.joiningDate)],
                    ['Base Salary', AppFormatters.formatCurrency(employee.baseSalary)],
                  ],
                ),
                pw.Spacer(),
                pw.Text('Pure Drop Aqua Authorized Personnel Signature', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeeProvider);

    final filtered = employees.where((e) {
      final q = _searchQuery.toLowerCase();
      final matchesQuery = e.name.toLowerCase().contains(q) || e.phone.contains(q) || e.id.toLowerCase().contains(q);
      final matchesRole = _roleFilter == null || e.role == _roleFilter;
      return matchesQuery && matchesRole;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
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

          // Search & Filter Row
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: '',
                  hint: 'Search by staff name, phone or ID...',
                  prefixIcon: Icons.search,
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Staff'),
                  selected: _roleFilter == null,
                  onSelected: (_) => setState(() => _roleFilter = null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Delivery Drivers'),
                  selected: _roleFilter == UserRole.deliveryBoy,
                  onSelected: (_) => setState(() => _roleFilter = UserRole.deliveryBoy),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Admins'),
                  selected: _roleFilter == UserRole.admin,
                  onSelected: (_) => setState(() => _roleFilter = UserRole.admin),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Office Staff'),
                  selected: _roleFilter == UserRole.officeStaff,
                  onSelected: (_) => setState(() => _roleFilter = UserRole.officeStaff),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Employee List
          Expanded(
            child: filtered.isEmpty
                ? EmptyStateWidget(
                    title: 'No Staff Found',
                    description: 'Add delivery drivers and office staff members to manage your business operations.',
                    buttonLabel: 'Add Staff Member',
                    onButtonPressed: () => _showAddEmployeeDialog(),
                  )
                : RefreshIndicator(
                    onRefresh: () async => ref.read(employeeProvider.notifier).refresh(),
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: InkWell(
                            onTap: () => _showEmployeeDetailsModal(item),
                            borderRadius: BorderRadius.circular(16),
                            child: CustomCard(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primaryLight,
                                  child: Icon(
                                    item.role == UserRole.admin ? Icons.admin_panel_settings : Icons.delivery_dining,
                                    color: AppColors.primary,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        item.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    RoleBadge(role: item.role),
                                  ],
                                ),
                                subtitle: Text(
                                  '${item.phone} • ${AppFormatters.formatCurrency(item.baseSalary)}/mo',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                                  tooltip: 'Staff Actions',
                                  onSelected: (val) {
                                    if (val == 'id') _showIdCardDialog(item);
                                    if (val == 'edit') _showAddEmployeeDialog(item);
                                    if (val == 'delete') _confirmDeleteEmployee(item);
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'id',
                                      child: Row(
                                        children: [
                                          Icon(Icons.badge_outlined, color: AppColors.info, size: 20),
                                          SizedBox(width: 8),
                                          Text('Digital ID Card'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                                          SizedBox(width: 8),
                                          Text('Edit Staff'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                          SizedBox(width: 8),
                                          Text('Delete Staff'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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
        height: MediaQuery.of(context).size.height * 0.85,
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
                      _showIdCardDialog(employee);
                    },
                    icon: const Icon(Icons.badge_outlined, size: 20),
                    label: const Text('ID Card', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/salary');
                },
                icon: const Icon(Icons.payments_outlined, size: 20),
                label: const Text('Process Monthly Salary Payout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
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
