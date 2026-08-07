import '../../models/customer_model.dart';
import '../../models/order_model.dart';
import '../../models/employee_model.dart';
import '../../models/payment_model.dart';

class SearchSearchResult {
  final String type; // 'Customer', 'Order', 'Employee', 'Payment'
  final String id;
  final String title;
  final String subtitle;
  final String status;

  SearchSearchResult({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
  });
}

class SearchIndexService {
  final List<CustomerModel> _customers = [];
  final List<OrderModel> _orders = [];
  final List<EmployeeModel> _employees = [];
  final List<PaymentModel> _payments = [];

  void updateCustomers(List<CustomerModel> customers) {
    _customers.clear();
    _customers.addAll(customers);
  }

  void updateOrders(List<OrderModel> orders) {
    _orders.clear();
    _orders.addAll(orders);
  }

  void updateEmployees(List<EmployeeModel> employees) {
    _employees.clear();
    _employees.addAll(employees);
  }

  void updatePayments(List<PaymentModel> payments) {
    _payments.clear();
    _payments.addAll(payments);
  }

  List<SearchSearchResult> globalSearch(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase().trim();
    final results = <SearchSearchResult>[];

    for (final c in _customers) {
      if (c.name.toLowerCase().contains(q) || c.phone.contains(q) || c.address.toLowerCase().contains(q)) {
        results.add(SearchSearchResult(
          type: 'Customer',
          id: c.id,
          title: c.name,
          subtitle: '${c.phone} • ${c.address}',
          status: c.status.name,
        ));
      }
    }

    for (final o in _orders) {
      if (o.id.toLowerCase().contains(q) || o.customerName.toLowerCase().contains(q) || o.phone.contains(q)) {
        results.add(SearchSearchResult(
          type: 'Order',
          id: o.id,
          title: '${o.customerName} (${o.quantity} Cans)',
          subtitle: '₹${o.totalAmount} • Status: ${o.status.displayName}',
          status: o.status.displayName,
        ));
      }
    }

    for (final e in _employees) {
      if (e.name.toLowerCase().contains(q) || e.phone.contains(q) || e.assignedArea.toLowerCase().contains(q)) {
        results.add(SearchSearchResult(
          type: 'Employee',
          id: e.id,
          title: e.name,
          subtitle: '${e.role.name} • Area: ${e.assignedArea}',
          status: e.isActive ? 'Active' : 'Inactive',
        ));
      }
    }

    for (final p in _payments) {
      if (p.customerName.toLowerCase().contains(q) || p.referenceNo.toLowerCase().contains(q)) {
        results.add(SearchSearchResult(
          type: 'Payment',
          id: p.id,
          title: '${p.customerName} - ₹${p.amount}',
          subtitle: 'Mode: ${p.paymentMode.name} • Ref: ${p.referenceNo}',
          status: 'Collected',
        ));
      }
    }

    return results;
  }
}
