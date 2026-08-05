import 'dart:convert';
import '../core/constants/app_constants.dart';
import '../core/constants/app_enums.dart';
import '../core/storage/hive_service.dart';
import '../core/utils/result.dart';
import '../models/customer_model.dart';
import '../models/expense_model.dart';
import '../models/inventory_model.dart';
import '../models/order_model.dart';
import '../models/payment_model.dart';
import 'base_repository.dart';

class DashboardRepository extends BaseRepository {
  Future<Result<Map<String, dynamic>>> getDashboardData() async {
    try {
      final orders = HiveService.getAll(AppConstants.orderBoxName).map((e) => OrderModel.fromJson(jsonDecode(e as String))).toList();
      final customers = HiveService.getAll(AppConstants.customerBoxName).map((e) => CustomerModel.fromJson(jsonDecode(e as String))).toList();
      final expenses = HiveService.getAll(AppConstants.expenseBoxName).map((e) => ExpenseModel.fromJson(jsonDecode(e as String))).toList();
      final payments = HiveService.getAll(AppConstants.paymentBoxName).map((e) => PaymentModel.fromJson(jsonDecode(e as String))).toList();

      InventoryModel inventory = InventoryModel.initial();
      final invStr = HiveService.getBoxSafe(AppConstants.inventoryBoxName)?.get('current');
      if (invStr != null) inventory = InventoryModel.fromJson(jsonDecode(invStr));

      final today = DateTime.now();
      final todayOrders = orders.where((o) => o.createdAt.year == today.year && o.createdAt.month == today.month && o.createdAt.day == today.day).toList();
      final todayRevenue = todayOrders.fold<double>(0.0, (sum, o) => sum + o.totalAmount);
      final completedDeliveries = orders.where((o) => o.status == OrderStatus.delivered).toList();
      final totalOrderRevenue = completedDeliveries.fold<double>(0.0, (sum, o) => sum + o.totalAmount);
      final totalPaymentIncome = payments.fold<double>(0.0, (sum, p) => sum + p.amount);
      final totalIncome = totalOrderRevenue + totalPaymentIncome;
      final totalExpenses = expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
      final pendingPaymentsTotal = customers.fold<double>(0.0, (sum, c) => sum + c.pendingDues);

      return Success({
        'todayOrdersCount': todayOrders.length,
        'todayRevenue': todayRevenue,
        'totalIncome': totalIncome,
        'totalExpenses': totalExpenses,
        'netProfit': totalIncome - totalExpenses,
        'filledCans': inventory.filledCans,
        'emptyCans': inventory.emptyCans,
        'damagedCans': inventory.damagedCans,
        'customerBalanceCans': inventory.customerBalanceCans,
        'pendingPaymentsTotal': pendingPaymentsTotal,
        'completedDeliveriesCount': completedDeliveries.length,
      });
    } catch (e, stack) {
      return Failure('Failed to load dashboard data: $e', e, stack);
    }
  }
}
