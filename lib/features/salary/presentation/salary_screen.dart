import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/employee_model.dart';
import '../../../models/salary_model.dart';
import '../../../providers/app_providers.dart';

class SalaryScreen extends ConsumerStatefulWidget {
  const SalaryScreen({super.key});

  @override
  ConsumerState<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends ConsumerState<SalaryScreen> {
  void _showProcessSalaryDialog() {
    final employees = ref.read(employeeProvider);
    if (employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add employees in the Employee module first!')),
      );
      return;
    }

    EmployeeModel selectedEmp = employees.first;
    final monthCtrl = TextEditingController(text: AppFormatters.formatMonthYear(DateTime.now()));
    final baseCtrl = TextEditingController(text: selectedEmp.baseSalary.toString());
    final advancesCtrl = TextEditingController(text: '0.0');
    final bonusCtrl = TextEditingController(text: '0.0');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Process Staff Salary Payout'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<EmployeeModel>(
                      initialValue: selectedEmp,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Select Employee'),
                      items: employees.map((e) {
                        return DropdownMenuItem(
                          value: e,
                          child: Text(
                            '${e.name} (${e.role.displayName})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedEmp = val;
                            baseCtrl.text = val.baseSalary.toString();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(label: 'Month & Year', controller: monthCtrl),
                    const SizedBox(height: 12),
                    CustomTextField(label: 'Base Salary (₹)', controller: baseCtrl, keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: CustomTextField(label: 'Advances Deducted', controller: advancesCtrl, keyboardType: TextInputType.number)),
                        const SizedBox(width: 8),
                        Expanded(child: CustomTextField(label: 'Bonus / Incentive', controller: bonusCtrl, keyboardType: TextInputType.number)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final base = double.tryParse(baseCtrl.text) ?? 0.0;
                    final adv = double.tryParse(advancesCtrl.text) ?? 0.0;
                    final bonus = double.tryParse(bonusCtrl.text) ?? 0.0;
                    final net = base - adv + bonus;

                    final item = SalaryModel(
                      id: '',
                      employeeId: selectedEmp.id,
                      employeeName: selectedEmp.name,
                      monthYear: monthCtrl.text.trim(),
                      baseSalary: base,
                      advances: adv,
                      bonus: bonus,
                      netPayout: net,
                      payoutDate: DateTime.now(),
                    );
                    ref.read(salaryProvider.notifier).addSalary(item);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Salary paid for ${item.employeeName}')),
                    );
                  }
                },
                child: const Text('Confirm Payout'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _generateSalarySlipPdf(SalaryModel item) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('PURE DROP AQUA - SALARY SLIP', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                      pw.Text(item.monthYear, style: const pw.TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Employee Name: ${item.employeeName}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text('Payout Date: ${AppFormatters.formatDate(item.payoutDate)}'),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Base Salary:'),
                    pw.Text(AppFormatters.formatCurrency(item.baseSalary)),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Bonus / Incentives:'),
                    pw.Text(AppFormatters.formatCurrency(item.bonus)),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Advances Deducted:'),
                    pw.Text('- ${AppFormatters.formatCurrency(item.advances)}'),
                  ],
                ),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('NET PAYOUT TOTAL:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text(AppFormatters.formatCurrency(item.netPayout), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Spacer(),
                pw.Align(
                  alignment: pw.Alignment.bottomRight,
                  child: pw.Text('Authorized Signature: Pure Drop Aqua Admin'),
                ),
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
    final salaries = ref.watch(salaryProvider);

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
                      'Staff Salary & Payout Ledger',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    CustomButton(
                      label: 'Process Payout',
                      icon: Icons.payments,
                      onPressed: () => _showProcessSalaryDialog(),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Staff Salary & Payout Ledger',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CustomButton(
                    label: 'Process Payout',
                    icon: Icons.payments,
                    width: 150,
                    onPressed: () => _showProcessSalaryDialog(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: salaries.isEmpty
                ? EmptyStateWidget(
                    title: 'No Salary Payouts Processed',
                    description: 'Process monthly salaries for staff and drivers.',
                    buttonLabel: 'Process Payout',
                    onButtonPressed: () => _showProcessSalaryDialog(),
                  )
                : ListView.builder(
                    itemCount: salaries.length,
                    itemBuilder: (context, index) {
                      final item = salaries[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: CustomCard(
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.successLight,
                              child: Icon(Icons.receipt, color: AppColors.success),
                            ),
                            title: Text(
                              '${item.employeeName} (${item.monthYear})',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'Base: ${AppFormatters.formatCompactCurrency(item.baseSalary)} | Adv: ${AppFormatters.formatCompactCurrency(item.advances)} | Bonus: ${AppFormatters.formatCompactCurrency(item.bonus)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppFormatters.formatCurrency(item.netPayout),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.success),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.print, color: AppColors.primary),
                                  onPressed: () => _generateSalarySlipPdf(item),
                                  tooltip: 'Print Salary Slip PDF',
                                ),
                              ],
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
