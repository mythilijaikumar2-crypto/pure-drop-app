import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/expense_model.dart';
import '../../../providers/app_providers.dart';

class ExpenseScreen extends ConsumerStatefulWidget {
  const ExpenseScreen({super.key});

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  ExpenseCategory? _categoryFilter;

  void _showAddExpenseDialog() {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final spentByCtrl = TextEditingController();
    ExpenseCategory selectedCat = ExpenseCategory.petrol;
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Log Business Expense'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<ExpenseCategory>(
                      initialValue: selectedCat,
                      decoration: const InputDecoration(labelText: 'Expense Category'),
                      items: ExpenseCategory.values.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat.displayName));
                      }).toList(),
                      onChanged: isSaving
                          ? null
                          : (val) {
                              if (val != null) setModalState(() => selectedCat = val);
                            },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(label: 'Amount (₹)', controller: amountCtrl, keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    CustomTextField(label: 'Expense Description', controller: descCtrl, hint: 'e.g. Fuel for delivery van'),
                    const SizedBox(height: 12),
                    CustomTextField(label: 'Spent By', controller: spentByCtrl),
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
                            final item = ExpenseModel(
                              id: '',
                              category: selectedCat,
                              amount: double.tryParse(amountCtrl.text) ?? 0.0,
                              description: descCtrl.text.trim(),
                              spentBy: spentByCtrl.text.trim(),
                              date: DateTime.now(),
                            );
                            await ref.read(expenseProvider.notifier).addExpense(item);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Expense logged successfully!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('❌ Error saving expense: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Expense'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isAdmin = user?.role == UserRole.admin;
    final expenses = ref.watch(expenseProvider);

    final userExpenses = isAdmin
        ? expenses
        : expenses.where((e) => e.spentBy.toLowerCase().contains((user?.name ?? '').toLowerCase()) || e.category == ExpenseCategory.petrol || e.category == ExpenseCategory.vehicleService || e.category == ExpenseCategory.maintenance).toList();

    final filtered = _categoryFilter == null
        ? userExpenses
        : userExpenses.where((e) => e.category == _categoryFilter).toList();

    final totalAmount = filtered.fold<double>(0.0, (sum, item) => sum + item.amount);

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
                      'Business Expenses Logger',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Total Expenses: ${AppFormatters.formatCurrency(totalAmount)}',
                      style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    CustomButton(
                      label: 'Add Expense',
                      icon: Icons.add,
                      onPressed: () => _showAddExpenseDialog(),
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
                          'Business Expenses Logger',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Total Expenses: ${AppFormatters.formatCurrency(totalAmount)}',
                          style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  CustomButton(
                    label: 'Add Expense',
                    icon: Icons.add,
                    width: 160,
                    onPressed: () => _showAddExpenseDialog(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Categories'),
                  selected: _categoryFilter == null,
                  onSelected: (_) => setState(() => _categoryFilter = null),
                ),
                const SizedBox(width: 8),
                ...ExpenseCategory.values.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(cat.displayName),
                      selected: _categoryFilter == cat,
                      onSelected: (_) => setState(() => _categoryFilter = cat),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? EmptyStateWidget(
                    title: 'No Expenses Logged',
                    description: 'Log petrol, tea, maintenance or plant purchase expenses.',
                    buttonLabel: 'Add Expense',
                    onButtonPressed: () => _showAddExpenseDialog(),
                  )
                : RefreshIndicator(
                    onRefresh: () async => ref.read(expenseProvider.notifier).refresh(),
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: CustomCard(
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppColors.errorLight,
                                child: Icon(Icons.receipt_long, color: AppColors.error),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.category.displayName,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppFormatters.formatCurrency(item.amount),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.error),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                '${item.description} • Spent by: ${item.spentBy} • ${AppFormatters.formatDateTime(item.date)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
