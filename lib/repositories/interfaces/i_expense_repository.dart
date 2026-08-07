import '../../models/expense_model.dart';

abstract class IExpenseRepository {
  Future<List<ExpenseModel>> getExpenses();
  Future<bool> addExpense(ExpenseModel expense);
  Future<bool> deleteExpense(String id);
}
