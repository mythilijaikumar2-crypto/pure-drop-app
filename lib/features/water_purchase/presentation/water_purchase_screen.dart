import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/water_purchase_model.dart';
import '../../../providers/app_providers.dart';

class WaterPurchaseScreen extends ConsumerStatefulWidget {
  const WaterPurchaseScreen({super.key});

  @override
  ConsumerState<WaterPurchaseScreen> createState() => _WaterPurchaseScreenState();
}

class _WaterPurchaseScreenState extends ConsumerState<WaterPurchaseScreen> {
  void _showAddWaterPurchaseDialog() {
    final plantCtrl = TextEditingController();
    final cansCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    PaymentStatus selectedPaymentStatus = PaymentStatus.paid;
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Log Plant Water Purchase Batch'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(
                      label: 'Water Purification Plant Name',
                      controller: plantCtrl,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Cans Filled',
                            controller: cansCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomTextField(
                            label: 'Cost / Can (₹)',
                            controller: costCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PaymentStatus>(
                      initialValue: selectedPaymentStatus,
                      decoration: const InputDecoration(labelText: 'Payment Status'),
                      items: PaymentStatus.values.map((s) {
                        return DropdownMenuItem(value: s, child: Text(s.displayName));
                      }).toList(),
                      onChanged: isSaving
                          ? null
                          : (val) {
                              if (val != null) setModalState(() => selectedPaymentStatus = val);
                            },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Batch Notes / Invoice Ref',
                      controller: notesCtrl,
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
                            final cans = int.tryParse(cansCtrl.text) ?? 0;
                            final cost = double.tryParse(costCtrl.text) ?? 15.0;
                            final item = WaterPurchaseModel(
                              id: '',
                              plantName: plantCtrl.text.trim(),
                              cansPurchased: cans,
                              costPerCan: cost,
                              totalCost: cans * cost,
                              paymentStatus: selectedPaymentStatus,
                              date: DateTime.now(),
                              notes: notesCtrl.text.trim(),
                            );
                            await ref.read(waterPurchaseProvider.notifier).addPurchase(item);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Water purchase saved to Google Sheets!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('❌ Error logging purchase: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Log Purchase'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purchases = ref.watch(waterPurchaseProvider);

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
                      'Water Plant Refill History',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    CustomButton(
                      label: 'Log Purchase',
                      icon: Icons.water_drop,
                      onPressed: () => _showAddWaterPurchaseDialog(),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Water Plant Refill History',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CustomButton(
                    label: 'Log Purchase',
                    icon: Icons.water_drop,
                    width: 140,
                    onPressed: () => _showAddWaterPurchaseDialog(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: purchases.isEmpty
                ? EmptyStateWidget(
                    title: 'No Purchase Batches Yet',
                    description: 'Record water purchases from processing plants.',
                    buttonLabel: 'Log Water Purchase',
                    onButtonPressed: () => _showAddWaterPurchaseDialog(),
                  )
                : RefreshIndicator(
                    onRefresh: () async => ref.read(waterPurchaseProvider.notifier).refresh(),
                    child: ListView.builder(
                      itemCount: purchases.length,
                      itemBuilder: (context, index) {
                        final item = purchases[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: CustomCard(
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppColors.primaryLight,
                                child: Icon(Icons.water, color: AppColors.primary),
                              ),
                              title: Text(
                                item.plantName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${item.cansPurchased} Cans @ ${AppFormatters.formatCurrency(item.costPerCan)}/can • ${AppFormatters.formatDate(item.date)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                AppFormatters.formatCurrency(item.totalCost),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.error),
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
}
