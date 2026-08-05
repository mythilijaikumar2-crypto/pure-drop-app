import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../core/storage/hive_service.dart';
import '../core/utils/result.dart';
import '../models/expense_model.dart';
import 'base_repository.dart';

class ExpenseRepository extends BaseRepository {
  final Uuid _uuid = const Uuid();

  Future<Result<List<ExpenseModel>>> getExpenses() async {
    try {
      final items = HiveService.getAll(AppConstants.expenseBoxName);
      final list = items.map((item) {
        return ExpenseModel.fromJson(jsonDecode(item as String));
      }).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return Success(list);
    } catch (e, stack) {
      return Failure('Failed to fetch expenses: $e', e, stack);
    }
  }

  Future<Result<ExpenseModel>> addExpense(ExpenseModel expense) async {
    try {
      final box = HiveService.getBoxSafe(AppConstants.expenseBoxName);
      final id = expense.id.isEmpty ? 'EXP-${_uuid.v4().substring(0, 5).toUpperCase()}' : expense.id;
      final item = expense.copyWith(id: id);

      if (box != null) await box.put(id, jsonEncode(item.toJson()));
      await enqueueSync(
        collection: 'expenses',
        docId: id,
        action: 'set',
        data: item.toJson(),
      );

      return Success(item);
    } catch (e, stack) {
      return Failure('Failed to log expense: $e', e, stack);
    }
  }
}
