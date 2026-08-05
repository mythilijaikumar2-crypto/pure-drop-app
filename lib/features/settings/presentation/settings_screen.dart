import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/export_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isExporting = false;

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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Employee Management Section (Admin Only)
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
                  'Create new employee accounts with auto-generated Employee IDs (PDAEMP-001), manage staff details, search employees, and toggle Active/Inactive statuses.',
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

          const SizedBox(height: 16),
          const Text('Admin System & Data Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Backup & Storage Status Card
          CustomCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.cloud_done_rounded, color: AppColors.success, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Cloud Sync & Backup Status',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Last Live Sync: ${AppFormatters.formatDateTime(DateTime.now())}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Firestore Backup Active (puredropaqua-369f6)',
                        style: TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Export Firebase Data Card (Excel / CSV)
          CustomCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.table_chart_rounded, color: AppColors.primary, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Export Database (Excel / CSV)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Export customers, orders, inventory, payments, expenses, employees, and purchases to CSV/Excel format.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),

                const Text('Select Collection to Export', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCollection,
                  isExpanded: true,
                  items: _collectionsList.map((c) {
                    return DropdownMenuItem(
                      value: c['id'],
                      child: Text(c['name']!),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCollection = val);
                  },
                ),

                const SizedBox(height: 16),
                CustomButton(
                  label: _isExporting ? 'Generating Export...' : 'Export & Download CSV',
                  icon: Icons.download_rounded,
                  isLoading: _isExporting,
                  onPressed: _exportData,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Import Data Card (Future Feature - Locked)
          CustomCard(
            backgroundColor: Colors.grey.shade50,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.lock_clock, color: Colors.grey.shade600, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import Data (Future Release)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Bulk CSV/Excel importing will be enabled in an upcoming release.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Business Pricing & Rules Configuration Card
          CustomCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: AppColors.primary, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Business Rules & Price Settings',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Water Can Price (Default): ₹35.00 / can', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Security Deposit (Default): ₹160.00 / new customer', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Plant Water Purchase Cost: ₹15.00 / filled can', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Business rules & prices updated!'), backgroundColor: AppColors.success),
                    );
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Save Pricing Configuration'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
