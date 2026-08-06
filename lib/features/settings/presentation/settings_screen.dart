import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/export_service.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../providers/app_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isExporting = false;
  bool _isClearingData = false;
  bool _isSavingSettings = false;

  String _selectedCollection = 'all';

  final List<Map<String, String>> _collectionsList = [
    {'id': 'all', 'name': 'Complete Database Data (All Collections)'},
    {'id': 'customers', 'name': 'Customers Collection'},
    {'id': 'orders', 'name': 'Orders Collection'},
    {'id': 'inventory', 'name': 'Inventory Collection'},
    {'id': 'payments', 'name': 'Payments Collection'},
    {'id': 'expenses', 'name': 'Expenses Collection'},
    {'id': 'employees', 'name': 'Employees Collection'},
    {'id': 'attendance', 'name': 'Attendance Collection'},
    {'id': 'salary', 'name': 'Salary Payroll Collection'},
    {'id': 'water_purchases', 'name': 'Water Purchases Collection'},
    {'id': 'settings', 'name': 'Settings Collection'},
  ];

  late TextEditingController _waterPriceCtrl;
  late TextEditingController _bottlePriceCtrl;
  late TextEditingController _depositPriceCtrl;
  late TextEditingController _companyNameCtrl;
  late TextEditingController _companyPhoneCtrl;
  late TextEditingController _companyAddressCtrl;
  late TextEditingController _taxNumberCtrl;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _waterPriceCtrl = TextEditingController(text: settings.defaultWaterPrice.toString());
    _bottlePriceCtrl = TextEditingController(text: settings.defaultBottlePrice.toString());
    _depositPriceCtrl = TextEditingController(text: settings.defaultSecurityDeposit.toString());
    _companyNameCtrl = TextEditingController(text: settings.companyName);
    _companyPhoneCtrl = TextEditingController(text: settings.companyPhone);
    _companyAddressCtrl = TextEditingController(text: settings.companyAddress);
    _taxNumberCtrl = TextEditingController(text: settings.taxNumber);
  }

  @override
  void dispose() {
    _waterPriceCtrl.dispose();
    _bottlePriceCtrl.dispose();
    _depositPriceCtrl.dispose();
    _companyNameCtrl.dispose();
    _companyPhoneCtrl.dispose();
    _companyAddressCtrl.dispose();
    _taxNumberCtrl.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    setState(() => _isSavingSettings = true);
    final current = ref.read(settingsProvider);
    final updated = current.copyWith(
      defaultWaterPrice: double.tryParse(_waterPriceCtrl.text) ?? 35.0,
      defaultBottlePrice: double.tryParse(_bottlePriceCtrl.text) ?? 150.0,
      defaultSecurityDeposit: double.tryParse(_depositPriceCtrl.text) ?? 160.0,
      companyName: _companyNameCtrl.text.trim(),
      companyPhone: _companyPhoneCtrl.text.trim(),
      companyAddress: _companyAddressCtrl.text.trim(),
      taxNumber: _taxNumberCtrl.text.trim(),
    );

    await ref.read(settingsProvider.notifier).updateSettings(updated);
    setState(() => _isSavingSettings = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Settings saved successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _exportData() async {
    setState(() => _isExporting = true);
    await Future.delayed(const Duration(milliseconds: 400));

    try {
      final collectionsData = ExportService.getALLCollectionsData();
      String exportContent = '';

      if (_selectedCollection == 'all') {
        exportContent = ExportService.generateCompleteERPExportCSV(collectionsData);
      } else {
        final list = collectionsData[_selectedCollection] ?? [];
        exportContent = ExportService.convertToCSV(list);
      }

      setState(() => _isExporting = false);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.table_chart_outlined, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedCollection == 'all' ? 'Complete Database Export Ready' : 'Collection Export: ${_selectedCollection.toUpperCase()}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✅ Excel / CSV formatted data generated successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          exportContent.length > 1000 ? '${exportContent.substring(0, 1000)}\n...[Truncated Preview]' : exportContent,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              ElevatedButton.icon(
                onPressed: () async {
                  final bytes = utf8.encode(exportContent);
                  final uri = Uri.dataFromBytes(bytes, mimeType: 'text/csv');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Download CSV File'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isExporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error generating export: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Local Data'),
        content: const Text(
          'Are you sure you want to clear all locally stored records? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isClearingData = true);
      final repo = ref.read(appRepositoryProvider);
      await repo.clearAllData();
      ref.invalidate(customerProvider);
      ref.invalidate(orderProvider);
      ref.invalidate(inventoryProvider);
      ref.invalidate(waterPurchaseProvider);
      ref.invalidate(employeeProvider);
      ref.invalidate(expenseProvider);
      ref.invalidate(paymentProvider);
      setState(() => _isClearingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ All data cleared successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Pricing & Business Configuration Card
          CustomCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune, color: AppColors.primary, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pricing & Business Configuration',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Water Can Price (₹)',
                        controller: _waterPriceCtrl,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.water_drop_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomTextField(
                        label: 'Empty Can Price (₹)',
                        controller: _bottlePriceCtrl,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.shopping_bag_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  label: 'Default Security Deposit (₹)',
                  controller: _depositPriceCtrl,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.verified_user_outlined,
                  hint: 'Default deposit amount per customer profile (₹160)',
                ),
                const SizedBox(height: 16),

                const Text('Company Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                CustomTextField(
                  label: 'Company Name',
                  controller: _companyNameCtrl,
                  prefixIcon: Icons.business,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Company Phone',
                        controller: _companyPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomTextField(
                        label: 'GST / Tax Number',
                        controller: _taxNumberCtrl,
                        prefixIcon: Icons.receipt_long,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  label: 'Company Address',
                  controller: _companyAddressCtrl,
                  maxLines: 2,
                  prefixIcon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 16),

                CustomButton(
                  label: _isSavingSettings ? 'Saving Settings...' : 'Save Configuration',
                  icon: Icons.save_rounded,
                  isLoading: _isSavingSettings,
                  onPressed: _saveSettings,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Employee Management Link Card
          CustomCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.badge_rounded, color: AppColors.primary, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Employee Management',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage staff profiles, assign delivery roles, and track active employee credentials.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                CustomButton(
                  label: 'Open Employee Management',
                  icon: Icons.people_alt_rounded,
                  onPressed: () => context.go('/employees'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Data Export Card
          CustomCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.table_chart, color: AppColors.success, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Excel & CSV Export',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCollection,
                  decoration: const InputDecoration(labelText: 'Select Collection'),
                  items: _collectionsList.map((c) {
                    return DropdownMenuItem(value: c['id'], child: Text(c['name']!));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCollection = val);
                  },
                ),
                const SizedBox(height: 16),
                CustomButton(
                  label: _isExporting ? 'Generating Export...' : 'Export Collection Data',
                  icon: Icons.download_rounded,
                  isLoading: _isExporting,
                  onPressed: _exportData,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Data Wipe Card
          CustomCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.manage_search, color: AppColors.warning, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Database Reset & Management',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Clear all locally stored data. This action cannot be undone.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  label: _isClearingData ? 'Clearing Data...' : 'Clear All Local Data',
                  icon: Icons.delete_sweep_rounded,
                  isLoading: _isClearingData,
                  onPressed: _clearAllData,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
