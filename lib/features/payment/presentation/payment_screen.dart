import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/customer_model.dart';
import '../../../models/payment_model.dart';
import '../../../providers/app_providers.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  void _showCollectPaymentDialog() {
    final customers = ref.read(customerProvider);
    final dueCustomers = customers.where((c) => c.pendingDues > 0).toList();
    final list = dueCustomers.isNotEmpty ? dueCustomers : customers;

    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No customer records available.')),
      );
      return;
    }

    CustomerModel selectedCust = list.first;
    final amountCtrl = TextEditingController(text: selectedCust.pendingDues.toString());
    final refCtrl = TextEditingController();
    PaymentMode selectedMode = PaymentMode.upi;
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Record Customer Payment Collection'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<CustomerModel>(
                      initialValue: selectedCust,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Select Customer'),
                      items: list.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(
                            '${c.name} (Dues: ${AppFormatters.formatCompactCurrency(c.pendingDues)})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: isSaving
                          ? null
                          : (val) {
                              if (val != null) {
                                setModalState(() {
                                  selectedCust = val;
                                  amountCtrl.text = val.pendingDues.toString();
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(label: 'Amount Collected (₹)', controller: amountCtrl, keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PaymentMode>(
                      initialValue: selectedMode,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Payment Mode'),
                      items: PaymentMode.values.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(
                            m.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: isSaving
                          ? null
                          : (val) {
                              if (val != null) setModalState(() => selectedMode = val);
                            },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(label: 'UPI Ref / Transaction ID', controller: refCtrl, hint: 'Optional reference number'),
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
                            final item = PaymentModel(
                              id: '',
                              customerId: selectedCust.id,
                              customerName: selectedCust.name,
                              amount: double.tryParse(amountCtrl.text) ?? 0.0,
                              paymentMode: selectedMode,
                              referenceNo: refCtrl.text.trim(),
                              date: DateTime.now(),
                            );
                            await ref.read(paymentProvider.notifier).recordPayment(item);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ Payment recorded for ${item.customerName} in Google Sheets!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('❌ Error recording payment: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirm Payment'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payments = ref.watch(paymentProvider);

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
                      'Payment Collection Ledger',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    CustomButton(
                      label: 'Record Payment',
                      icon: Icons.add_card,
                      onPressed: () => _showCollectPaymentDialog(),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Payment Collection Ledger',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CustomButton(
                    label: 'Record Payment',
                    icon: Icons.add_card,
                    width: 180,
                    onPressed: () => _showCollectPaymentDialog(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: payments.isEmpty
                ? EmptyStateWidget(
                    title: 'No Payments Recorded',
                    description: 'Record payments collected from customers.',
                    buttonLabel: 'Record Payment',
                    onButtonPressed: () => _showCollectPaymentDialog(),
                  )
                : RefreshIndicator(
                    onRefresh: () => ref.read(paymentProvider.notifier).fetchLive(),
                    child: ListView.builder(
                      itemCount: payments.length,
                      itemBuilder: (context, index) {
                        final item = payments[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: CustomCard(
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppColors.successLight,
                                child: Icon(Icons.account_balance_wallet, color: AppColors.success),
                              ),
                              title: Text(
                                item.customerName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                'Mode: ${item.paymentMode.displayName} • ${AppFormatters.formatDateTime(item.date)} ${item.referenceNo.isNotEmpty ? "• Ref: ${item.referenceNo}" : ""}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                AppFormatters.formatCurrency(item.amount),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.success),
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
