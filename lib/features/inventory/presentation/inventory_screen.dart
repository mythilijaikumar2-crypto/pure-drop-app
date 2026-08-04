import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../models/inventory_model.dart';
import '../../../providers/app_providers.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  void _showCanAuditDialog(InventoryModel inv) {
    final filledCtrl = TextEditingController(text: inv.filledCans.toString());
    final emptyCtrl = TextEditingController(text: inv.emptyCans.toString());
    final damagedCtrl = TextEditingController(text: inv.damagedCans.toString());
    final totalCtrl = TextEditingController(text: inv.totalCans.toString());
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Inventory Physical Stock Audit'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    label: 'Total Cans Owned in Stock',
                    controller: totalCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Filled Cans Available',
                    controller: filledCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Empty Cans at Plant / Warehouse',
                    controller: emptyCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Damaged Cans Count',
                    controller: damagedCtrl,
                    keyboardType: TextInputType.number,
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
                          final updated = inv.copyWith(
                            totalCans: int.tryParse(totalCtrl.text) ?? inv.totalCans,
                            filledCans: int.tryParse(filledCtrl.text) ?? inv.filledCans,
                            emptyCans: int.tryParse(emptyCtrl.text) ?? inv.emptyCans,
                            damagedCans: int.tryParse(damagedCtrl.text) ?? inv.damagedCans,
                            lastUpdated: DateTime.now(),
                          );
                          await ref.read(inventoryProvider.notifier).update(updated);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Inventory audit saved to Google Sheets!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          setModalState(() => isSaving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Error saving audit: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Stock Audit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventory = ref.watch(inventoryProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(inventoryProvider.notifier).fetchLive(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 500;
                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Water Can Inventory Management',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Last updated: ${AppFormatters.formatDateTime(inventory.lastUpdated)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        label: 'Stock Audit',
                        icon: Icons.edit_note,
                        onPressed: () => _showCanAuditDialog(inventory),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Water Can Inventory Management',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Last updated: ${AppFormatters.formatDateTime(inventory.lastUpdated)}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    CustomButton(
                      label: 'Stock Audit',
                      icon: Icons.edit_note,
                      width: 140,
                      onPressed: () => _showCanAuditDialog(inventory),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Total Stock Overview Banner
            CustomCard(
              backgroundColor: AppColors.primaryLight,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.inventory, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Water Cans in Circulation',
                          style: TextStyle(fontSize: 14, color: AppColors.primaryDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${inventory.totalCans} Cans',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Grid breakdown
            LayoutBuilder(
              builder: (context, constraints) {
                final count = constraints.maxWidth > 900
                    ? 4
                    : constraints.maxWidth > 500
                        ? 2
                        : 1;
                final aspect = count == 1 ? 2.4 : (count == 2 ? 1.15 : 1.3);

                return GridView.count(
                  crossAxisCount: count,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: aspect,
                  children: [
                _InventoryCard(
                  title: 'Filled Cans Ready',
                  value: inventory.filledCans.toString(),
                  icon: Icons.water_drop,
                  color: AppColors.filledCans,
                ),
                _InventoryCard(
                  title: 'Empty Cans Available',
                  value: inventory.emptyCans.toString(),
                  icon: Icons.crop_portrait,
                  color: AppColors.emptyCans,
                ),
                _InventoryCard(
                  title: 'With Customers',
                  value: inventory.customerBalanceCans.toString(),
                  icon: Icons.people_outline,
                  color: AppColors.customerBalance,
                ),
                _InventoryCard(
                  title: 'Damaged / Broken',
                  value: inventory.damagedCans.toString(),
                  icon: Icons.error_outline,
                  color: AppColors.damagedCans,
                ),
              ],
            );
          },
        ),
          ],
        ),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InventoryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
