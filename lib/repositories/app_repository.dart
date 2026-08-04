import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/app_enums.dart';
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
  final Uuid _uuid = const Uuid();

  AppRepository();

  // Initialize and ensure clean storage state (clears initial demo data once)
  Future<void> seedInitialDataIfEmpty() async {
    try {
      final settingsBox = HiveService.getBoxSafe(AppConstants.settingsBoxName);

      final isCleared = settingsBox?.get('demo_data_cleared_v1', defaultValue: false) ?? false;

      if (!isCleared) {
        // Clear all initial demo data boxes
        final boxesToClear = [
          AppConstants.customerBoxName,
          AppConstants.orderBoxName,
          AppConstants.employeeBoxName,
          AppConstants.expenseBoxName,
          AppConstants.waterPurchaseBoxName,
          AppConstants.deliveryBoxName,
          AppConstants.salaryBoxName,
          AppConstants.paymentBoxName,
          AppConstants.inventoryBoxName,
        ];

        for (final boxName in boxesToClear) {
          final box = HiveService.getBoxSafe(boxName);
          if (box != null) {
            await box.clear();
          }
        }

        // Initialize inventory with 0 values
        final inventoryBox = HiveService.getBoxSafe(AppConstants.inventoryBoxName);
        if (inventoryBox != null) {
          final initialInventory = InventoryModel.initial();
          await inventoryBox.put('current', jsonEncode(initialInventory.toJson()));
        }

        await settingsBox?.put('demo_data_cleared_v1', true);
      } else {
        // Ensure inventory exists
        final inventoryBox = HiveService.getBoxSafe(AppConstants.inventoryBoxName);
        if (inventoryBox != null && inventoryBox.isEmpty) {
          final initialInventory = InventoryModel.initial();
          await inventoryBox.put('current', jsonEncode(initialInventory.toJson()));
        }
      }
    } catch (_) {}
  }

  // Explicit method to manually wipe database if needed
  Future<void> clearAllData() async {
    try {
      final boxesToClear = [
        AppConstants.customerBoxName,
        AppConstants.orderBoxName,
        AppConstants.employeeBoxName,
        AppConstants.expenseBoxName,
        AppConstants.waterPurchaseBoxName,
        AppConstants.deliveryBoxName,
        AppConstants.salaryBoxName,
        AppConstants.paymentBoxName,
        AppConstants.inventoryBoxName,
      ];

      for (final boxName in boxesToClear) {
        final box = HiveService.getBoxSafe(boxName);
        if (box != null) {
          await box.clear();
        }
      }

      final inventoryBox = HiveService.getBoxSafe(AppConstants.inventoryBoxName);
      if (inventoryBox != null) {
        final initialInventory = InventoryModel.initial();
        await inventoryBox.put('current', jsonEncode(initialInventory.toJson()));
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

  Future<bool> saveCustomer(CustomerModel customer) async {
    final box = HiveService.getBox(AppConstants.customerBoxName);
    final id = customer.id.isEmpty ? 'CUST-${_uuid.v4().substring(0, 5).toUpperCase()}' : customer.id;
    final updatedCustomer = customer.copyWith(id: id);

    try {
      await box.put(id, jsonEncode(updatedCustomer.toJson()));
      if (kDebugMode) {
        debugPrint('✅ Customer "${updatedCustomer.name}" saved locally.');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ saveCustomer failed: $e');
      }
      rethrow;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    final box = HiveService.getBox(AppConstants.customerBoxName);
    try {
      await box.delete(id);
      return true;
    } catch (e) {
      rethrow;
    }
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

  Future<bool> createOrder(OrderModel order) async {
    final box = HiveService.getBox(AppConstants.orderBoxName);
    final id = order.id.isEmpty ? 'ORD-${1000 + box.length + 1}' : order.id;
    final newOrder = order.copyWith(id: id);

    try {
      await box.put(id, jsonEncode(newOrder.toJson()));
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateOrderStatus(
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
    if (jsonStr == null) return false;

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

    try {
      await box.put(orderId, jsonEncode(updated.toJson()));
      if (status == OrderStatus.delivered) {
        await _onOrderDelivered(updated);
      }
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteOrder(String id) async {
    final box = HiveService.getBox(AppConstants.orderBoxName);
    try {
      await box.delete(id);
      return true;
    } catch (e) {
      rethrow;
    }
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

  Future<bool> saveInventory(InventoryModel inventory) async {
    final box = HiveService.getBox(AppConstants.inventoryBoxName);
    try {
      await box.put('current', jsonEncode(inventory.toJson()));
      return true;
    } catch (e) {
      rethrow;
    }
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

  Future<bool> addWaterPurchase(WaterPurchaseModel purchase) async {
    try {
      final box = HiveService.getBoxSafe(AppConstants.waterPurchaseBoxName);
      final id = purchase.id.isEmpty ? 'WP-${_uuid.v4().substring(0, 5).toUpperCase()}' : purchase.id;
      final item = purchase.copyWith(id: id);

      if (box != null) await box.put(id, jsonEncode(item.toJson()));
      final inv = getInventory();
      final updatedInv = inv.copyWith(
        filledCans: inv.filledCans + purchase.cansPurchased,
        totalCans: inv.totalCans + (purchase.notes.contains('New Cans') ? purchase.cansPurchased : 0),
        lastUpdated: DateTime.now(),
      );
      await saveInventory(updatedInv);

      await addExpense(ExpenseModel(
        id: 'EXP-WP-$id',
        category: ExpenseCategory.waterPurchase,
        amount: purchase.totalCost,
        description: 'Water Purchase batch from ${purchase.plantName} (${purchase.cansPurchased} Cans)',
        spentBy: 'Admin',
        date: purchase.date,
      ));
      return true;
    } catch (e) {
      rethrow;
    }
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

  Future<bool> saveEmployee(EmployeeModel employee) async {
    try {
      final box = HiveService.getBoxSafe(AppConstants.employeeBoxName);
      final id = employee.id.isEmpty ? 'EMP-${_uuid.v4().substring(0, 4).toUpperCase()}' : employee.id;
      final emp = employee.copyWith(id: id);
      if (box != null) await box.put(id, jsonEncode(emp.toJson()));
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteEmployee(String id) async {
    try {
      final box = HiveService.getBoxSafe(AppConstants.employeeBoxName);
      if (box != null) await box.delete(id);
      return true;
    } catch (e) {
      rethrow;
    }
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

  Future<bool> addSalary(SalaryModel salary) async {
    try {
      final box = HiveService.getBoxSafe(AppConstants.salaryBoxName);
      final id = salary.id.isEmpty ? 'SAL-${_uuid.v4().substring(0, 5).toUpperCase()}' : salary.id;
      final item = salary.copyWith(id: id);

      if (box != null) await box.put(id, jsonEncode(item.toJson()));

      await addExpense(ExpenseModel(
        id: 'EXP-SAL-$id',
        category: ExpenseCategory.salary,
        amount: salary.netPayout,
        description: 'Salary Payout for ${salary.employeeName} (${salary.monthYear})',
        spentBy: 'Admin',
        date: salary.payoutDate,
      ));
      return true;
    } catch (e) {
      rethrow;
    }
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

  Future<bool> addExpense(ExpenseModel expense) async {
    try {
      final box = HiveService.getBoxSafe(AppConstants.expenseBoxName);
      final id = expense.id.isEmpty ? 'EXP-${_uuid.v4().substring(0, 5).toUpperCase()}' : expense.id;
      final item = expense.copyWith(id: id);
      if (box != null) await box.put(id, jsonEncode(item.toJson()));
      return true;
    } catch (e) {
      rethrow;
    }
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

  Future<bool> recordPayment(PaymentModel payment) async {
    try {
      final box = HiveService.getBoxSafe(AppConstants.paymentBoxName);
      final id = payment.id.isEmpty ? 'PAY-${_uuid.v4().substring(0, 5).toUpperCase()}' : payment.id;
      final item = payment.copyWith(id: id);

      if (box != null) await box.put(id, jsonEncode(item.toJson()));

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
      return true;
    } catch (e) {
      rethrow;
    }
  }
}
