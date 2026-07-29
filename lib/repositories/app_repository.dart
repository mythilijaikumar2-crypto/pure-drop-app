import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/app_enums.dart';
import '../core/network/dio_client.dart';
import '../core/storage/hive_service.dart';
import '../models/customer_model.dart';
import '../models/employee_model.dart';
import '../models/expense_model.dart';
import '../models/inventory_model.dart';
import '../models/order_model.dart';
import '../models/payment_model.dart';
import '../models/salary_model.dart';
import '../models/water_purchase_model.dart';

class AppRepository {
  final DioClient _dioClient;
  final Uuid _uuid = const Uuid();

  AppRepository(this._dioClient);

  // Initialize and Seed Initial Production Demo Data if empty
  Future<void> seedInitialDataIfEmpty() async {
    try {
      final customerBox = HiveService.getBoxSafe(AppConstants.customerBoxName);
      if (customerBox == null) return;
      if (customerBox.isEmpty) {
      final initialCustomers = [
        CustomerModel(
          id: 'CUST-101',
          name: 'Blue Star Apartments',
          phone: '9876543210',
          address: 'Block A, MG Road, Tech Park Area',
          canPrice: 35.0,
          canBalance: 25,
          pendingDues: 875.0,
          latitude: 12.9716,
          longitude: 77.5946,
        ),
        CustomerModel(
          id: 'CUST-102',
          name: 'Rajesh Sharma (Villa 14)',
          phone: '9822011223',
          address: 'Villa 14, Palm Meadows, Whitefield',
          canPrice: 40.0,
          canBalance: 4,
          pendingDues: 0.0,
          latitude: 12.9698,
          longitude: 77.7499,
        ),
        CustomerModel(
          id: 'CUST-103',
          name: 'Zenith Tech Solutions',
          phone: '9988776655',
          address: '4th Floor, Innovation Hub, Outer Ring Rd',
          canPrice: 35.0,
          canBalance: 30,
          pendingDues: 1050.0,
          latitude: 12.9279,
          longitude: 77.6271,
        ),
        CustomerModel(
          id: 'CUST-104',
          name: 'Green Cafe & Resto',
          phone: '9744112233',
          address: '12th Main, Indiranagar',
          canPrice: 35.0,
          canBalance: 12,
          pendingDues: 420.0,
          latitude: 12.9784,
          longitude: 77.6408,
        ),
      ];

      for (var c in initialCustomers) {
        await customerBox.put(c.id, jsonEncode(c.toJson()));
      }
    }

    final inventoryBox = HiveService.getBox(AppConstants.inventoryBoxName);
    if (inventoryBox.isEmpty) {
      final initialInventory = InventoryModel.initial();
      await inventoryBox.put('current', jsonEncode(initialInventory.toJson()));
    }

    final employeeBox = HiveService.getBox(AppConstants.employeeBoxName);
    if (employeeBox.isEmpty) {
      final employees = [
        EmployeeModel(
          id: 'EMP-01',
          name: 'Ramesh Kumar',
          phone: '9876001122',
          role: UserRole.deliveryBoy,
          baseSalary: 16000,
          joiningDate: DateTime(2025, 1, 15),
        ),
        EmployeeModel(
          id: 'EMP-02',
          name: 'Suresh Patel',
          phone: '9876003344',
          role: UserRole.deliveryBoy,
          baseSalary: 16500,
          joiningDate: DateTime(2025, 3, 1),
        ),
        EmployeeModel(
          id: 'EMP-03',
          name: 'Sunil Verma',
          phone: '9876005566',
          role: UserRole.admin,
          baseSalary: 30000,
          joiningDate: DateTime(2024, 6, 1),
        ),
      ];
      for (var e in employees) {
        await employeeBox.put(e.id, jsonEncode(e.toJson()));
      }
    }

    final orderBox = HiveService.getBox(AppConstants.orderBoxName);
    if (orderBox.isEmpty) {
      final initialOrders = [
        OrderModel(
          id: 'ORD-1001',
          customerId: 'CUST-101',
          customerName: 'Blue Star Apartments',
          phone: '9876543210',
          address: 'Block A, MG Road, Tech Park Area',
          quantity: 10,
          unitPrice: 35.0,
          totalAmount: 350.0,
          status: OrderStatus.assigned,
          paymentStatus: PaymentStatus.pending,
          assignedDriverId: 'EMP-01',
          assignedDriverName: 'Ramesh Kumar',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          notes: 'Deliver before 5 PM to security desk',
        ),
        OrderModel(
          id: 'ORD-1002',
          customerId: 'CUST-102',
          customerName: 'Rajesh Sharma (Villa 14)',
          phone: '9822011223',
          address: 'Villa 14, Palm Meadows, Whitefield',
          quantity: 2,
          unitPrice: 40.0,
          totalAmount: 80.0,
          status: OrderStatus.pending,
          paymentStatus: PaymentStatus.pending,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          notes: 'Call before arriving',
        ),
        OrderModel(
          id: 'ORD-1003',
          customerId: 'CUST-104',
          customerName: 'Green Cafe & Resto',
          phone: '9744112233',
          address: '12th Main, Indiranagar',
          quantity: 5,
          unitPrice: 35.0,
          totalAmount: 175.0,
          status: OrderStatus.delivered,
          paymentStatus: PaymentStatus.paid,
          paymentMode: PaymentMode.upi,
          assignedDriverId: 'EMP-01',
          assignedDriverName: 'Ramesh Kumar',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          deliveredAt: DateTime.now().subtract(const Duration(hours: 3)),
          emptyCansCollected: 5,
          notes: 'Paid via Google Pay UPI',
        ),
      ];
      for (var o in initialOrders) {
        await orderBox.put(o.id, jsonEncode(o.toJson()));
      }
    }

    final expenseBox = HiveService.getBox(AppConstants.expenseBoxName);
    if (expenseBox.isEmpty) {
      final initialExpenses = [
        ExpenseModel(
          id: 'EXP-501',
          category: ExpenseCategory.petrol,
          amount: 500.0,
          description: 'Auto Van Fuel Refill',
          spentBy: 'Ramesh Kumar',
          date: DateTime.now().subtract(const Duration(days: 1)),
        ),
        ExpenseModel(
          id: 'EXP-502',
          category: ExpenseCategory.tea,
          amount: 80.0,
          description: 'Tea & Snacks for drivers',
          spentBy: 'Admin',
          date: DateTime.now(),
        ),
      ];
      for (var ex in initialExpenses) {
        await expenseBox.put(ex.id, jsonEncode(ex.toJson()));
      }
    }

    final waterPurchaseBox = HiveService.getBox(AppConstants.waterPurchaseBoxName);
    if (waterPurchaseBox.isEmpty) {
      final initialPurchases = [
        WaterPurchaseModel(
          id: 'WP-201',
          plantName: 'Aqua Pure Filtration Plant #2',
          cansPurchased: 200,
          costPerCan: 15.0,
          totalCost: 3000.0,
          paymentStatus: PaymentStatus.paid,
          date: DateTime.now().subtract(const Duration(days: 2)),
          notes: 'Batch 8092, High Quality RO Water',
        ),
      ];
      for (var wp in initialPurchases) {
        await waterPurchaseBox.put(wp.id, jsonEncode(wp.toJson()));
      }
    }
  } catch (_) {}
  }

  // --- CUSTOMER MODULE CRUD ---
  List<CustomerModel> getCustomers() {
    try {
      final items = HiveService.getAll(AppConstants.customerBoxName);
      return items.map((item) {
        final Map<String, dynamic> json = jsonDecode(item as String);
        return CustomerModel.fromJson(json);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCustomer(CustomerModel customer) async {
    final box = HiveService.getBox(AppConstants.customerBoxName);
    final id = customer.id.isEmpty ? 'CUST-${_uuid.v4().substring(0, 5).toUpperCase()}' : customer.id;
    final updatedCustomer = customer.copyWith(id: id);
    await box.put(id, jsonEncode(updatedCustomer.toJson()));

    try {
      await _dioClient.postAction('saveCustomer', updatedCustomer.toJson());
    } catch (_) {}
  }

  Future<void> deleteCustomer(String id) async {
    final box = HiveService.getBox(AppConstants.customerBoxName);
    await box.delete(id);
    try {
      await _dioClient.postAction('deleteCustomer', {'id': id});
    } catch (_) {}
  }

  // --- ORDER MODULE CRUD ---
  List<OrderModel> getOrders() {
    try {
      final items = HiveService.getAll(AppConstants.orderBoxName);
      final list = items.map((item) {
        final Map<String, dynamic> json = jsonDecode(item as String);
        return OrderModel.fromJson(json);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> createOrder(OrderModel order) async {
    final box = HiveService.getBox(AppConstants.orderBoxName);
    final id = order.id.isEmpty ? 'ORD-${1000 + box.length + 1}' : order.id;
    final newOrder = order.copyWith(id: id);
    await box.put(id, jsonEncode(newOrder.toJson()));

    try {
      await _dioClient.postAction('createOrder', newOrder.toJson());
    } catch (_) {}
  }

  Future<void> updateOrderStatus(
    String orderId,
    OrderStatus status, {
    String? driverId,
    String? driverName,
    int emptyCansCollected = 0,
    int damagedCansReported = 0,
    PaymentStatus? paymentStatus,
    PaymentMode? paymentMode,
  }) async {
    final box = HiveService.getBox(AppConstants.orderBoxName);
    final jsonStr = box.get(orderId);
    if (jsonStr == null) return;

    final order = OrderModel.fromJson(jsonDecode(jsonStr));
    final updated = order.copyWith(
      status: status,
      assignedDriverId: driverId ?? order.assignedDriverId,
      assignedDriverName: driverName ?? order.assignedDriverName,
      emptyCansCollected: emptyCansCollected > 0 ? emptyCansCollected : order.emptyCansCollected,
      damagedCansReported: damagedCansReported > 0 ? damagedCansReported : order.damagedCansReported,
      paymentStatus: paymentStatus ?? order.paymentStatus,
      paymentMode: paymentMode ?? order.paymentMode,
      deliveredAt: status == OrderStatus.delivered ? DateTime.now() : order.deliveredAt,
    );

    await box.put(orderId, jsonEncode(updated.toJson()));

    // Auto update inventory & customer can balance if delivered
    if (status == OrderStatus.delivered) {
      await _onOrderDelivered(updated);
    }

    try {
      await _dioClient.postAction('updateOrder', updated.toJson());
    } catch (_) {}
  }

  Future<void> _onOrderDelivered(OrderModel order) async {
    // 1. Update Inventory
    final inventory = getInventory();
    final newFilled = (inventory.filledCans - order.quantity).clamp(0, 99999);
    final newEmpty = (inventory.emptyCans + order.emptyCansCollected).clamp(0, 99999);
    final newDamaged = inventory.damagedCans + order.damagedCansReported;
    final newCustomerBalance = inventory.customerBalanceCans + order.quantity - order.emptyCansCollected;

    final updatedInventory = inventory.copyWith(
      filledCans: newFilled,
      emptyCans: newEmpty,
      damagedCans: newDamaged,
      customerBalanceCans: newCustomerBalance,
      lastUpdated: DateTime.now(),
    );
    await saveInventory(updatedInventory);

    // 2. Update Customer Balance & Dues
    final customerBox = HiveService.getBox(AppConstants.customerBoxName);
    final custStr = customerBox.get(order.customerId);
    if (custStr != null) {
      final cust = CustomerModel.fromJson(jsonDecode(custStr));
      final newCustBalance = (cust.canBalance + order.quantity - order.emptyCansCollected).clamp(0, 9999);
      final newDues = order.paymentStatus == PaymentStatus.paid
          ? cust.pendingDues
          : cust.pendingDues + order.totalAmount;

      final updatedCust = cust.copyWith(
        canBalance: newCustBalance,
        pendingDues: newDues,
      );
      await customerBox.put(cust.id, jsonEncode(updatedCust.toJson()));
    }
  }

  // --- INVENTORY MODULE CRUD ---
  InventoryModel getInventory() {
    try {
      final box = HiveService.getBoxSafe(AppConstants.inventoryBoxName);
      if (box != null) {
        final str = box.get('current');
        if (str != null) {
          return InventoryModel.fromJson(jsonDecode(str));
        }
      }
    } catch (_) {}
    return InventoryModel.initial();
  }

  Future<void> saveInventory(InventoryModel inventory) async {
    final box = HiveService.getBox(AppConstants.inventoryBoxName);
    await box.put('current', jsonEncode(inventory.toJson()));
    try {
      await _dioClient.postAction('updateInventory', inventory.toJson());
    } catch (_) {}
  }

  // --- WATER PURCHASE CRUD ---
  List<WaterPurchaseModel> getWaterPurchases() {
    try {
      final items = HiveService.getAll(AppConstants.waterPurchaseBoxName);
      final list = items.map((item) {
        return WaterPurchaseModel.fromJson(jsonDecode(item as String));
      }).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> addWaterPurchase(WaterPurchaseModel purchase) async {
    try {
      final box = HiveService.getBoxSafe(AppConstants.waterPurchaseBoxName);
      if (box == null) return;
      final id = purchase.id.isEmpty ? 'WP-${_uuid.v4().substring(0, 5).toUpperCase()}' : purchase.id;
      final item = WaterPurchaseModel(
        id: id,
        plantName: purchase.plantName,
        cansPurchased: purchase.cansPurchased,
        costPerCan: purchase.costPerCan,
        totalCost: purchase.totalCost,
        paymentStatus: purchase.paymentStatus,
        date: purchase.date,
        notes: purchase.notes,
      );

      await box.put(id, jsonEncode(item.toJson()));

      // Automatically increase filled cans inventory
      final inv = getInventory();
      final updatedInv = inv.copyWith(
        filledCans: inv.filledCans + purchase.cansPurchased,
        totalCans: inv.totalCans + (purchase.notes.contains('New Cans') ? purchase.cansPurchased : 0),
        lastUpdated: DateTime.now(),
      );
      await saveInventory(updatedInv);

      // Record expense for water purchase
      await addExpense(ExpenseModel(
        id: 'EXP-WP-$id',
        category: ExpenseCategory.waterPurchase,
        amount: purchase.totalCost,
        description: 'Water Purchase batch from ${purchase.plantName} (${purchase.cansPurchased} Cans)',
        spentBy: 'Admin',
        date: purchase.date,
      ));

      try {
        await _dioClient.postAction('addWaterPurchase', item.toJson());
      } catch (_) {}
    } catch (_) {}
  }

  // --- EMPLOYEES CRUD ---
  List<EmployeeModel> getEmployees() {
    try {
      final items = HiveService.getAll(AppConstants.employeeBoxName);
      return items.map((item) {
        return EmployeeModel.fromJson(jsonDecode(item as String));
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveEmployee(EmployeeModel employee) async {
    try {
      final box = HiveService.getBoxSafe(AppConstants.employeeBoxName);
      if (box == null) return;
      final id = employee.id.isEmpty ? 'EMP-${_uuid.v4().substring(0, 4).toUpperCase()}' : employee.id;
      final emp = EmployeeModel(
        id: id,
        name: employee.name,
        phone: employee.phone,
        role: employee.role,
 baseSalary: employee.baseSalary,
        joiningDate: employee.joiningDate,
        isActive: employee.isActive,
      );
      await box.put(id, jsonEncode(emp.toJson()));
    } catch (_) {}
  }

  // --- SALARY CRUD ---
  List<SalaryModel> getSalaries() {
    try {
      final items = HiveService.getAll(AppConstants.salaryBoxName);
      return items.map((item) {
        return SalaryModel.fromJson(jsonDecode(item as String));
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addSalary(SalaryModel salary) async {
    try {
      final box = HiveService.getBoxSafe(AppConstants.salaryBoxName);
      if (box == null) return;
      final id = salary.id.isEmpty ? 'SAL-${_uuid.v4().substring(0, 5).toUpperCase()}' : salary.id;
      final item = SalaryModel(
        id: id,
        employeeId: salary.employeeId,
        employeeName: salary.employeeName,
        monthYear: salary.monthYear,
        baseSalary: salary.baseSalary,
        advances: salary.advances,
        bonus: salary.bonus,
        netPayout: salary.netPayout,
        payoutDate: salary.payoutDate,
        isPaid: salary.isPaid,
      );
      await box.put(id, jsonEncode(item.toJson()));

      // Record as Expense
      await addExpense(ExpenseModel(
        id: 'EXP-SAL-$id',
        category: ExpenseCategory.salary,
        amount: salary.netPayout,
        description: 'Salary Payout for ${salary.employeeName} (${salary.monthYear})',
        spentBy: 'Admin',
        date: salary.payoutDate,
      ));
    } catch (_) {}
  }

  // --- EXPENSE MODULE CRUD ---
  List<ExpenseModel> getExpenses() {
    try {
      final items = HiveService.getAll(AppConstants.expenseBoxName);
      final list = items.map((item) {
        return ExpenseModel.fromJson(jsonDecode(item as String));
      }).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> addExpense(ExpenseModel expense) async {
    try {
      final box = HiveService.getBoxSafe(AppConstants.expenseBoxName);
      if (box == null) return;
      final id = expense.id.isEmpty ? 'EXP-${_uuid.v4().substring(0, 5).toUpperCase()}' : expense.id;
      final item = ExpenseModel(
        id: id,
        category: expense.category,
        amount: expense.amount,
        description: expense.description,
        spentBy: expense.spentBy,
        date: expense.date,
      );
      await box.put(id, jsonEncode(item.toJson()));
      try {
        await _dioClient.postAction('addExpense', item.toJson());
      } catch (_) {}
    } catch (_) {}
  }

  // --- PAYMENTS MODULE CRUD ---
  List<PaymentModel> getPayments() {
    try {
      final items = HiveService.getAll(AppConstants.paymentBoxName);
      final list = items.map((item) {
        return PaymentModel.fromJson(jsonDecode(item as String));
      }).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> recordPayment(PaymentModel payment) async {
    try {
      final box = HiveService.getBoxSafe(AppConstants.paymentBoxName);
      if (box == null) return;
      final id = payment.id.isEmpty ? 'PAY-${_uuid.v4().substring(0, 5).toUpperCase()}' : payment.id;
      final item = PaymentModel(
        id: id,
        customerId: payment.customerId,
        customerName: payment.customerName,
        amount: payment.amount,
        paymentMode: payment.paymentMode,
        referenceNo: payment.referenceNo,
        date: payment.date,
        notes: payment.notes,
      );
      await box.put(id, jsonEncode(item.toJson()));

      // Deduct pending dues from customer record
      final custBox = HiveService.getBoxSafe(AppConstants.customerBoxName);
      if (custBox != null) {
        final custStr = custBox.get(payment.customerId);
        if (custStr != null) {
          final cust = CustomerModel.fromJson(jsonDecode(custStr));
          final updatedDues = (cust.pendingDues - payment.amount).clamp(0.0, 999999.0);
          final updatedCust = cust.copyWith(pendingDues: updatedDues);
          await custBox.put(cust.id, jsonEncode(updatedCust.toJson()));
        }
      }

      try {
        await _dioClient.postAction('recordPayment', item.toJson());
      } catch (_) {}
    } catch (_) {}
  }
}
