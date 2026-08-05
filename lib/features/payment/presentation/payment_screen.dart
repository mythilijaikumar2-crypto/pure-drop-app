import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
  void _printReceipt(PaymentModel payment) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'PURE DROP AQUA',
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ),
                ),
                pw.Center(
                  child: pw.Text('Packaged Drinking Water Delivery System', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                ),
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('RECEIPT #${payment.id}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(AppFormatters.formatDateTime(payment.date)),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Text('Received From: ${payment.customerName}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('Payment Mode: ${payment.paymentMode.displayName}'),
                if (payment.referenceNo.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text('Transaction / Ref No: ${payment.referenceNo}'),
                ],
                pw.SizedBox(height: 16),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.circular(6)),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('AMOUNT COLLECTED:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      pw.Text(AppFormatters.formatCurrency(payment.amount), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: PdfColors.green900)),
                    ],
                  ),
                ),
                pw.Spacer(),
                pw.Divider(),
                pw.Center(
                  child: pw.Text('Thank you for choosing Pure Drop Aqua!', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'PureDrop_Receipt_${payment.id}.pdf',
    );
  }

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
                                  content: Text('✅ Payment recorded for ${item.customerName} successfully!'),
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
                    onRefresh: () async => ref.read(paymentProvider.notifier).refresh(),
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
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    AppFormatters.formatCurrency(item.amount),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.success),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.print_outlined, color: AppColors.primary),
                                    onPressed: () => _printReceipt(item),
                                    tooltip: 'Print PDF Receipt',
                                  ),
                                ],
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
