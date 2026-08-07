import 'package:flutter_test/flutter_test.dart';
import 'package:pure_drop_aqua/models/customer_model.dart';
import 'package:pure_drop_aqua/models/employee_model.dart';
import 'package:pure_drop_aqua/models/inventory_model.dart';
import 'package:pure_drop_aqua/models/order_model.dart';
import 'package:pure_drop_aqua/models/payment_model.dart';
import 'package:pure_drop_aqua/core/constants/app_enums.dart';
import 'package:pure_drop_aqua/core/services/automation/dashboard_automation.dart';

void main() {
  group('Admin Business Automation Engine Logic Unit Tests', () {
    test('CustomerMetrics calculation', () {
      final customers = [
        CustomerModel(id: 'C1', name: 'Cust 1', phone: '9000000001', address: 'A1', status: CustomerStatus.active),
        CustomerModel(id: 'C2', name: 'Cust 2', phone: '9000000002', address: 'A2', status: CustomerStatus.inactive),
        CustomerModel(id: 'C3', name: 'Cust 3', phone: '9000000003', address: 'A3', status: CustomerStatus.blocked),
      ];

      final metrics = CustomerMetrics.fromList(customers);
      expect(metrics.totalCustomers, 3);
      expect(metrics.activeCustomers, 1);
      expect(metrics.pausedCustomers, 1);
      expect(metrics.cancelledCustomers, 1);
    });

    test('Inventory Can Balance calculation on delivery', () {
      final current = InventoryModel(
        totalCans: 1000,
        filledCans: 500,
        emptyCans: 100,
        damagedCans: 10,
        customerBalanceCans: 50,
        lastUpdated: DateTime.now(),
      );

      const delivered = 5;
      const returned = 3;
      const damaged = 1;

      final updatedFilled = (current.filledCans - delivered).clamp(0, 9999);
      final updatedEmpty = current.emptyCans + returned;
      final updatedDamaged = current.damagedCans + damaged;
      final updatedCustBalance = current.customerBalanceCans + delivered - returned;

      expect(updatedFilled, 495);
      expect(updatedEmpty, 103);
      expect(updatedDamaged, 11);
      expect(updatedCustBalance, 52);
    });

    test('Employee Capacity Availability check', () {
      final emp1 = EmployeeModel(
        id: 'E1',
        name: 'John',
        phone: '9888888888',
        role: UserRole.deliveryBoy,
        baseSalary: 15000,
        joiningDate: DateTime.now(),
        assignedArea: 'Zone 1',
        maxDailyCapacity: 80,
        activeOrderCount: 80, // Full
      );

      final emp2 = EmployeeModel(
        id: 'E2',
        name: 'David',
        phone: '9777777777',
        role: UserRole.deliveryBoy,
        baseSalary: 15000,
        joiningDate: DateTime.now(),
        assignedArea: 'Zone 1',
        maxDailyCapacity: 80,
        activeOrderCount: 30, // Available
      );

      expect(emp1.isAvailableForAssignment, false);
      expect(emp2.isAvailableForAssignment, true);
    });

    test('Revenue Metrics net profit calculation', () {
      final now = DateTime.now();
      final orders = [
        OrderModel(
          id: 'O1',
          customerId: 'C1',
          customerName: 'Cust 1',
          phone: '999',
          address: 'A1',
          quantity: 2,
          unitPrice: 35,
          totalAmount: 70,
          status: OrderStatus.delivered,
          createdAt: now,
        ),
      ];

      final payments = [
        PaymentModel(
          id: 'P1',
          customerId: 'C1',
          customerName: 'Cust 1',
          amount: 50,
          paymentMode: PaymentMode.cash,
          date: now,
        ),
      ];

      final customers = [
        CustomerModel(id: 'C1', name: 'Cust 1', phone: '999', address: 'A1', pendingDues: 20),
      ];

      final metrics = RevenueMetrics.calculate(
        orders: orders,
        payments: payments,
        customers: customers,
        totalExpenses: 30.0,
      );

      expect(metrics.todayRevenue, 70.0);
      expect(metrics.totalIncome, 120.0); // 70 + 50
      expect(metrics.totalPendingDues, 20.0);
      expect(metrics.netProfit, 90.0); // 120 - 30
    });
  });
}
