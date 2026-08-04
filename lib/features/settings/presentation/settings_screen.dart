import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../providers/app_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isClearingData = false;

  void _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'இந்த செயல் எல்லா local data வையும் delete பண்ணும். Continue பண்ணணுமா?',
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
      // Refresh all providers
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Offline Storage Status Card
          CustomCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.storage, color: AppColors.success, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Offline Storage (Hive)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'All data is stored locally on this device using Hive NoSQL database. '
                  'No internet connection required.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
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
                    const Text('Local Storage Active', style: TextStyle(color: AppColors.success, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Data Management Card
          CustomCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.manage_search, color: AppColors.warning, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Data Management',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

          const SizedBox(height: 20),

          // App Info Card
          CustomCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'App Information',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _infoRow('App Name', AppConstants.appName),
                const SizedBox(height: 6),
                _infoRow('Version', '1.0.0 • Production Ready'),
                const SizedBox(height: 6),
                _infoRow('Architecture', 'Clean Architecture + Riverpod'),
                const SizedBox(height: 6),
                _infoRow('Storage', 'Hive Local NoSQL'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 13)),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}
