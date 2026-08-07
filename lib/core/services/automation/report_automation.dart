import '../../../models/customer_model.dart';
import '../../../models/employee_model.dart';
import '../../../models/expense_model.dart';
import '../../../models/order_model.dart';
import '../../../models/payment_model.dart';
import '../../../core/constants/app_enums.dart';

class ERPReport {
  final String title;
  final DateTime generatedAt;
  final Map<String, dynamic> summary;
  final List<Map<String, dynamic>> items;

  ERPReport({
    required this.title,
    required this.generatedAt,
    required this.summary,
    required this.items,
  });
}

class ReportAutomation {
  ERPReport buildDailyReport({
    required DateTime date,
    required List<OrderModel> orders,
    required List<ExpenseModel> expenses,
    required List<PaymentModel> payments,
  }) {
    bool isSameDay(DateTime d) => d.year == date.year && d.month == date.month && d.day == date.day;

    final dayOrders = orders.where((o) => isSameDay(o.createdAt)).toList();
    final dayDelivered = dayOrders.where((o) => o.status == OrderStatus.delivered).toList();
    final dayExpenses = expenses.where((e) => isSameDay(e.date)).toList();
    final dayPayments = payments.where((p) => isSameDay(p.createdAt)).toList();

    final revenue = dayDelivered.fold<double>(0.0, (sum, o) => sum + o.totalAmount);
    final collections = dayPayments.fold<double>(0.0, (sum, p) => sum + p.amount);
    final totalExp = dayExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);

    return ERPReport(
      title: 'Daily ERP Summary (${date.day}/${date.month}/${date.year})',
      generatedAt: DateTime.now(),
      summary: {
        'totalOrders': dayOrders.length,
        'deliveredOrders': dayDelivered.length,
        'grossRevenue': revenue,
        'collections': collections,
        'expenses': totalExp,
        'netCashflow': (revenue + collections) - totalExp,
      },
      items: dayDelivered.map((o) => {
        'id': o.id,
        'customer': o.customerName,
        'amount': o.totalAmount,
        'driver': o.assignedDriverName ?? 'Unassigned',
      }).toList(),
    );
  }

  ERPReport buildEmployeeReport({
    required List<EmployeeModel> employees,
    required List<OrderModel> orders,
    required List<PaymentModel> payments,
  }) {
    final reportItems = employees.map((emp) {
      final empOrders = orders.where((o) => o.assignedDriverId == emp.id).toList();
      final delivered = empOrders.where((o) => o.status == OrderStatus.delivered).toList();
      final totalRevenue = delivered.fold<double>(0.0, (sum, o) => sum + o.totalAmount);

      return {
        'employeeId': emp.id,
        'name': emp.name,
        'area': emp.assignedArea,
        'totalAssigned': empOrders.length,
        'deliveredCount': delivered.length,
        'revenueGenerated': totalRevenue,
      };
    }).toList();

    return ERPReport(
      title: 'Employee Performance & Route Summary',
      generatedAt: DateTime.now(),
      summary: {'totalStaff': employees.length},
      items: reportItems,
    );
  }

  ERPReport buildCustomerDuesReport(List<CustomerModel> customers) {
    final pendingCustomers = customers.where((c) => c.pendingDues > 0).toList();
    pendingCustomers.sort((a, b) => b.pendingDues.compareTo(a.pendingDues));

    final totalDues = pendingCustomers.fold<double>(0.0, (sum, c) => sum + c.pendingDues);

    return ERPReport(
      title: 'Customer Dues & Balance Aging Report',
      generatedAt: DateTime.now(),
      summary: {
        'customersWithDues': pendingCustomers.length,
        'totalPendingAmount': totalDues,
      },
      items: pendingCustomers.map((c) => {
        'id': c.id,
        'name': c.name,
        'phone': c.phone,
        'area': c.area,
        'pendingDues': c.pendingDues,
        'canBalance': c.canBalance,
      }).toList(),
    );
  }
}
