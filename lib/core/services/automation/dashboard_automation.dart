import '../../../models/customer_model.dart';
import '../../../models/employee_model.dart';
import '../../../models/expense_model.dart';
import '../../../models/order_model.dart';
import '../../../models/payment_model.dart';
import '../../../core/constants/app_enums.dart';

class CustomerMetrics {
  final int totalCustomers;
  final int activeCustomers;
  final int pausedCustomers;
  final int cancelledCustomers;

  CustomerMetrics({
    required this.totalCustomers,
    required this.activeCustomers,
    required this.pausedCustomers,
    required this.cancelledCustomers,
  });

  factory CustomerMetrics.fromList(List<CustomerModel> customers) {
    int active = 0;
    int paused = 0;
    int cancelled = 0;

    for (final c in customers) {
      if (c.status == CustomerStatus.active) {
        active++;
      } else if (c.status == CustomerStatus.inactive) {
        paused++;
      } else if (c.status == CustomerStatus.blocked) {
        cancelled++;
      }
    }

    return CustomerMetrics(
      totalCustomers: customers.length,
      activeCustomers: active,
      pausedCustomers: paused,
      cancelledCustomers: cancelled,
    );
  }
}

class OrderMetrics {
  final int todayOrdersCount;
  final int todayDeliveredCount;
  final int todayPendingCount;
  final int totalDeliveredCount;

  OrderMetrics({
    required this.todayOrdersCount,
    required this.todayDeliveredCount,
    required this.todayPendingCount,
    required this.totalDeliveredCount,
  });

  factory OrderMetrics.fromList(List<OrderModel> orders) {
    final now = DateTime.now();
    bool isToday(DateTime d) => d.year == now.year && d.month == now.month && d.day == now.day;

    final todayOrders = orders.where((o) => isToday(o.createdAt)).toList();
    final todayDelivered = todayOrders.where((o) => o.status == OrderStatus.delivered).length;
    final todayPending = todayOrders.where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.assigned).length;
    final totalDelivered = orders.where((o) => o.status == OrderStatus.delivered).length;

    return OrderMetrics(
      todayOrdersCount: todayOrders.length,
      todayDeliveredCount: todayDelivered,
      todayPendingCount: todayPending,
      totalDeliveredCount: totalDelivered,
    );
  }
}

class RevenueMetrics {
  final double todayRevenue;
  final double totalIncome;
  final double totalPendingDues;
  final double netProfit;

  RevenueMetrics({
    required this.todayRevenue,
    required this.totalIncome,
    required this.totalPendingDues,
    required this.netProfit,
  });

  factory RevenueMetrics.calculate({
    required List<OrderModel> orders,
    required List<PaymentModel> payments,
    required List<CustomerModel> customers,
    required double totalExpenses,
  }) {
    final now = DateTime.now();
    bool isToday(DateTime d) => d.year == now.year && d.month == now.month && d.day == now.day;

    final todayDelivered = orders.where((o) => o.status == OrderStatus.delivered && isToday(o.createdAt));
    final todayRev = todayDelivered.fold<double>(0.0, (sum, o) => sum + o.totalAmount);

    final totalOrderRevenue = orders.where((o) => o.status == OrderStatus.delivered).fold<double>(0.0, (sum, o) => sum + o.totalAmount);
    final totalPaymentIncome = payments.fold<double>(0.0, (sum, p) => sum + p.amount);

    final income = totalOrderRevenue + totalPaymentIncome;
    final dues = customers.fold<double>(0.0, (sum, c) => sum + c.pendingDues);
    final profit = income - totalExpenses;

    return RevenueMetrics(
      todayRevenue: todayRev,
      totalIncome: income,
      totalPendingDues: dues,
      netProfit: profit,
    );
  }
}

class ExpenseMetrics {
  final double totalExpenses;
  final int expenseCount;

  ExpenseMetrics({
    required this.totalExpenses,
    required this.expenseCount,
  });

  factory ExpenseMetrics.fromList(List<ExpenseModel> expenses) {
    final total = expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    return ExpenseMetrics(
      totalExpenses: total,
      expenseCount: expenses.length,
    );
  }
}

class EmployeeMetrics {
  final int totalEmployees;
  final int activeEmployees;
  final int deliveryBoysCount;

  EmployeeMetrics({
    required this.totalEmployees,
    required this.activeEmployees,
    required this.deliveryBoysCount,
  });

  factory EmployeeMetrics.fromList(List<EmployeeModel> employees) {
    final active = employees.where((e) => e.isActive && !e.isOnLeave).length;
    final drivers = employees.where((e) => e.role == UserRole.deliveryBoy).length;

    return EmployeeMetrics(
      totalEmployees: employees.length,
      activeEmployees: active,
      deliveryBoysCount: drivers,
    );
  }
}
