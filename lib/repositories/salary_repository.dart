import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/app_enums.dart';
import '../core/storage/hive_service.dart';
import '../core/utils/result.dart';
import '../models/expense_model.dart';
import '../models/salary_model.dart';
import 'base_repository.dart';

class SalaryRepository extends BaseRepository {
  final Uuid _uuid = const Uuid();

  Future<Result<List<SalaryModel>>> getSalaries() async {
    try {
      final items = HiveService.getAll(AppConstants.salaryBoxName);
      final list = items.map((item) {
        return SalaryModel.fromJson(jsonDecode(item as String));
      }).toList();
      return Success(list);
    } catch (e, stack) {
      return Failure('Failed to fetch salaries: $e', e, stack);
    }
  }

  Future<Result<SalaryModel>> addSalary(SalaryModel salary) async {
    try {
      final box = HiveService.getBoxSafe(AppConstants.salaryBoxName);
      final id = salary.id.isEmpty ? 'SAL-${_uuid.v4().substring(0, 5).toUpperCase()}' : salary.id;
      final item = salary.copyWith(id: id);

      if (box != null) await box.put(id, jsonEncode(item.toJson()));
      await enqueueSync(
        collection: 'salaries',
        docId: id,
        action: 'set',
        data: item.toJson(),
      );

      // Log Financial Expense
      final expBox = HiveService.getBoxSafe(AppConstants.expenseBoxName);
      final expId = 'EXP-SAL-$id';
      final exp = ExpenseModel(
        id: expId,
        category: ExpenseCategory.salary,
        amount: salary.netPayout,
        description: 'Salary Payout for ${salary.employeeName} (${salary.monthYear})',
        spentBy: 'Admin',
        date: salary.payoutDate,
      );

      if (expBox != null) await expBox.put(expId, jsonEncode(exp.toJson()));
      await enqueueSync(
        collection: 'expenses',
        docId: expId,
        action: 'set',
        data: exp.toJson(),
      );

      return Success(item);
    } catch (e, stack) {
      return Failure('Failed to record salary payout: $e', e, stack);
    }
  }
}
