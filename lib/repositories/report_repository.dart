import 'dart:convert';
import '../core/constants/app_constants.dart';
import '../core/storage/hive_service.dart';
import '../core/utils/result.dart';
import '../models/expense_model.dart';
import '../models/order_model.dart';
import '../models/payment_model.dart';
import 'base_repository.dart';

class ReportRepository extends BaseRepository {
  Future<Result<Map<String, dynamic>>> getFinancialReport() async {
    try {
      final orders = HiveService.getAll(AppConstants.orderBoxName).map((e) => OrderModel.fromJson(jsonDecode(e as String))).toList();
      final expenses = HiveService.getAll(AppConstants.expenseBoxName).map((e) => ExpenseModel.fromJson(jsonDecode(e as String))).toList();
      final payments = HiveService.getAll(AppConstants.paymentBoxName).map((e) => PaymentModel.fromJson(jsonDecode(e as String))).toList();

      final totalRevenue = orders.fold<double>(0.0, (sum, o) => sum + o.totalAmount);
      final totalIncome = payments.fold<double>(0.0, (sum, p) => sum + p.amount);
      final totalExpenses = expenses.fold<double>(0.0, (sum, e) => sum + e.amount);

      return Success({
        'totalRevenue': totalRevenue,
        'totalIncome': totalIncome,
        'totalExpenses': totalExpenses,
        'netProfit': (totalRevenue + totalIncome) - totalExpenses,
      });
    } catch (e, stack) {
      return Failure('Failed to build financial report: $e', e, stack);
    }
  }
}
