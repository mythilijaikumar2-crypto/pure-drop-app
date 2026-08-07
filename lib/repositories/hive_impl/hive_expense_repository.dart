import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/storage/hive_service.dart';
import '../../models/expense_model.dart';
import '../interfaces/i_expense_repository.dart';

class HiveExpenseRepository implements IExpenseRepository {
  final Uuid _uuid = const Uuid();

  @override
  Future<List<ExpenseModel>> getExpenses() async {
    try {
      final items = HiveService.getAll(AppConstants.expenseBoxName);
      final list = items.map((item) {
        final Map<String, dynamic> json = jsonDecode(item as String);
        return ExpenseModel.fromJson(json);
      }).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<bool> addExpense(ExpenseModel expense) async {
    final box = HiveService.getBox(AppConstants.expenseBoxName);
    final id = expense.id.isEmpty
        ? 'EXP-${_uuid.v4().substring(0, 5).toUpperCase()}'
        : expense.id;
    final updated = expense.copyWith(id: id);

    try {
      await box.put(id, jsonEncode(updated.toJson()));
      return true;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> deleteExpense(String id) async {
    final box = HiveService.getBox(AppConstants.expenseBoxName);
    try {
      await box.delete(id);
      return true;
    } catch (e) {
      rethrow;
    }
  }
}
