import '../../../models/customer_model.dart';
import '../../../models/employee_model.dart';
import '../../../models/expense_model.dart';
import '../../../repositories/interfaces/i_customer_repository.dart';
import '../../../repositories/interfaces/i_order_repository.dart';
import '../../../repositories/interfaces/i_employee_repository.dart';
import '../../../repositories/interfaces/i_expense_repository.dart';
import '../../../repositories/interfaces/i_payment_repository.dart';
import '../../../core/constants/app_enums.dart';
import 'customer_automation.dart';
import 'order_automation.dart';
import 'employee_automation.dart';
import 'payment_automation.dart';
import 'inventory_automation.dart';
import 'report_automation.dart';
import 'timeline_automation.dart';
import 'notification_automation.dart';

class AutomationEngine {
  final CustomerAutomation customerAutomation;
  final OrderAutomation orderAutomation;
  final EmployeeAutomation employeeAutomation;
  final PaymentAutomation paymentAutomation;
  final InventoryAutomation inventoryAutomation;
  final TimelineAutomation timelineAutomation;
  final ReportAutomation reportAutomation;
  final NotificationAutomation notificationAutomation;

  final ICustomerRepository customerRepo;
  final IOrderRepository orderRepo;
  final IEmployeeRepository employeeRepo;
  final IExpenseRepository expenseRepo;
  final IPaymentRepository paymentRepo;

  AutomationEngine({
    required this.customerAutomation,
    required this.orderAutomation,
    required this.employeeAutomation,
    required this.paymentAutomation,
    required this.inventoryAutomation,
    required this.timelineAutomation,
    required this.reportAutomation,
    required this.notificationAutomation,
    required this.customerRepo,
    required this.orderRepo,
    required this.employeeRepo,
    required this.expenseRepo,
    required this.paymentRepo,
  });

  /// Run daily automatic operations on app launch or timer trigger
  Future<void> checkAndRunDailyAutomations() async {
    await orderAutomation.checkAndGenerateDailyOrders();
    final inventory = inventoryAutomation.getInventory();
    if (inventory.isLowStock) {
      await notificationAutomation.triggerLowStockAlert(inventory.filledCans);
    }
  }

  /// Trigger: Admin creates new customer
  Future<bool> handleCustomerCreation(CustomerModel customer) async {
    return customerAutomation.createCustomer(customer);
  }

  /// Trigger: Admin updates customer details
  Future<bool> handleCustomerEdit(CustomerModel customer) async {
    return customerAutomation.updateCustomer(customer);
  }

  /// Trigger: Admin pauses customer
  Future<bool> handleCustomerPause(String customerId) async {
    return customerAutomation.pauseCustomer(customerId);
  }

  /// Trigger: Admin resumes customer
  Future<bool> handleCustomerResume(String customerId) async {
    return customerAutomation.resumeCustomer(customerId);
  }

  /// Trigger: Admin cancels customer
  Future<bool> handleCustomerCancel(String customerId) async {
    return customerAutomation.cancelCustomer(customerId);
  }

  /// Trigger: Admin creates employee
  Future<bool> handleEmployeeCreation(EmployeeModel employee) async {
    return employeeAutomation.createEmployee(employee);
  }

  /// Trigger: Admin changes employee area
  Future<bool> handleEmployeeAreaChange(String employeeId, String newArea) async {
    return employeeAutomation.updateEmployeeArea(employeeId, newArea);
  }

  /// Trigger: Employee/Admin marks order as Delivered
  Future<bool> handleDeliveryCompleted({
    required String orderId,
    required int emptyCansCollected,
    required int damagedCansReported,
    required PaymentMode paymentMode,
    required bool isPaid,
  }) async {
    final order = await orderRepo.getOrderById(orderId);
    if (order == null) return false;

    // 1. Update Order status in Hive
    final updatedStatus = await orderRepo.updateOrderStatus(
      orderId,
      OrderStatus.delivered,
      emptyCansCollected: emptyCansCollected,
      damagedCansReported: damagedCansReported,
      paymentStatus: isPaid ? PaymentStatus.paid : PaymentStatus.pending,
      paymentMode: paymentMode,
    );

    if (!updatedStatus) return false;

    // 2. Process Bottle Balance & Can Stock Math
    await inventoryAutomation.processDeliveryCompleted(
      filledCansDelivered: order.quantity,
      emptyCansReturned: emptyCansCollected,
      damagedCansReported: damagedCansReported,
    );

    // 3. Update Customer Bottle Balance & Pending Dues
    final customer = await customerRepo.getCustomerById(order.customerId);
    if (customer != null) {
      final newCanBalance = (customer.canBalance + order.quantity).clamp(0, 9999);
      final newEmptyPending = (customer.emptyCansPending + order.quantity - emptyCansCollected).clamp(0, 9999);
      final newPendingDues = isPaid ? customer.pendingDues : (customer.pendingDues + order.totalAmount);

      final updatedCustomer = customer.copyWith(
        canBalance: newCanBalance,
        emptyCansPending: newEmptyPending,
        pendingDues: newPendingDues,
      );
      await customerRepo.saveCustomer(updatedCustomer);
    }

    // 4. Update Driver Active Workload
    if (order.assignedDriverId != null && order.assignedDriverId!.isNotEmpty) {
      final driver = await employeeRepo.getEmployeeById(order.assignedDriverId!);
      if (driver != null && driver.activeOrderCount > 0) {
        await employeeRepo.saveEmployee(driver.copyWith(
          activeOrderCount: (driver.activeOrderCount - 1).clamp(0, 9999),
        ));
      }
    }

    // 5. Record Payment if paid immediately on delivery
    if (isPaid) {
      await paymentAutomation.collectPayment(
        customerId: order.customerId,
        customerName: order.customerName,
        amount: order.totalAmount,
        paymentMode: paymentMode,
        notes: 'Collected on delivery (Order #${order.id})',
      );
      await notificationAutomation.triggerPaymentCollectedAlert(order.customerName, order.totalAmount);
    }

    // 6. Log Timeline Audit Entry
    await timelineAutomation.logEvent(
      title: 'Delivery Completed',
      description: 'Order #${order.id} delivered to ${order.customerName} (${order.quantity} cans)',
      category: 'Delivery',
      recordId: order.id,
      performedBy: order.assignedDriverName ?? 'Delivery Boy',
    );

    // 7. Check low stock notification trigger
    final inventory = inventoryAutomation.getInventory();
    if (inventory.isLowStock) {
      await notificationAutomation.triggerLowStockAlert(inventory.filledCans);
    }

    return true;
  }

  /// Trigger: Standalone Empty Cans Returned
  Future<bool> handleEmptyCansReturned({
    required String customerId,
    required int emptyCansCount,
  }) async {
    if (emptyCansCount <= 0) return false;
    final customer = await customerRepo.getCustomerById(customerId);
    if (customer == null) return false;

    final newEmptyPending = (customer.emptyCansPending - emptyCansCount).clamp(0, 9999);
    final newCanBalance = (customer.canBalance - emptyCansCount).clamp(0, 9999);
    await customerRepo.saveCustomer(customer.copyWith(
      emptyCansPending: newEmptyPending,
      canBalance: newCanBalance,
    ));

    final currentInv = inventoryAutomation.getInventory();
    await inventoryAutomation.saveInventory(currentInv.copyWith(
      emptyCans: currentInv.emptyCans + emptyCansCount,
      customerBalanceCans: (currentInv.customerBalanceCans - emptyCansCount).clamp(0, 99999),
      lastUpdated: DateTime.now(),
    ));

    await timelineAutomation.logEvent(
      title: 'Empty Cans Returned',
      description: 'Collected $emptyCansCount empty cans from ${customer.name}',
      category: 'Inventory',
      recordId: customerId,
    );
    return true;
  }

  /// Trigger: Standalone Damaged Cans Reported
  Future<bool> handleDamagedCansReported({
    required String customerId,
    required int damagedCansCount,
    String remarks = '',
  }) async {
    if (damagedCansCount <= 0) return false;
    final currentInv = inventoryAutomation.getInventory();
    await inventoryAutomation.saveInventory(currentInv.copyWith(
      damagedCans: currentInv.damagedCans + damagedCansCount,
      lastUpdated: DateTime.now(),
    ));

    await timelineAutomation.logEvent(
      title: 'Damaged Cans Reported',
      description: 'Reported $damagedCansCount damaged cans ($remarks)',
      category: 'Inventory',
      recordId: customerId,
    );
    return true;
  }

  /// Trigger: Employee or Admin collects payment
  Future<bool> handlePaymentCollected({
    required String customerId,
    required String customerName,
    required double amount,
    required PaymentMode paymentMode,
    String referenceNumber = '',
  }) async {
    final success = await paymentAutomation.collectPayment(
      customerId: customerId,
      customerName: customerName,
      amount: amount,
      paymentMode: paymentMode,
      referenceNumber: referenceNumber,
    );
    if (success) {
      await notificationAutomation.triggerPaymentCollectedAlert(customerName, amount);
    }
    return success;
  }

  /// Trigger: Admin adds expense
  Future<bool> handleExpenseAdded(ExpenseModel expense) async {
    final saved = await expenseRepo.addExpense(expense);
    if (saved) {
      await timelineAutomation.logEvent(
        title: 'Expense Recorded',
        description: '${expense.title} - ₹${expense.amount} (${expense.category.displayName})',
        category: 'Expense',
        recordId: expense.id,
      );
    }
    return saved;
  }
}
