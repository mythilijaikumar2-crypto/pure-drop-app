import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/app_enums.dart';
import '../core/services/firebase_service.dart';
import '../core/storage/hive_service.dart';
import '../models/customer_model.dart';
import '../models/employee_model.dart';
import '../models/expense_model.dart';
import '../models/inventory_model.dart';
import '../models/order_model.dart';
import '../models/payment_model.dart';
import '../models/salary_model.dart';
import '../models/settings_model.dart';
import '../models/water_purchase_model.dart';
import '../models/delivery_model.dart';
import '../models/audit_log_model.dart';

class AppRepository {
  final Uuid _uuid = const Uuid();
  final FirebaseService _firebase = FirebaseService();

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
        final currentUser = _firebase.currentUser;
        debugPrint('═══ saveCustomer ══════════════════════════════════════');
        debugPrint('📦 Repository     : AppRepository.saveCustomer');
        debugPrint('📂 Collection     : customers/$id');
        debugPrint('🔐 Auth Status    : ${currentUser == null ? "NULL ❌" : "Authenticated ✅"}');
        debugPrint('🆔 UID            : ${currentUser?.uid ?? "N/A — will cause permission-denied"}');
        debugPrint('📧 Email          : ${currentUser?.email ?? "N/A"}');
        debugPrint('💾 Hive saved     : ✅ (local write succeeded)');
        debugPrint('🔄 Firestore sync : about to call syncDocument...');
        debugPrint('══════════════════════════════════════════════════════');
      }

      _firebase.syncDocument(collection: 'customers', docId: id, data: updatedCustomer.toJson());

      if (kDebugMode) {
        debugPrint('✅ Customer "${updatedCustomer.name}" saved locally & sync dispatched.');
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
      _firebase.deleteDocument(collection: 'customers', docId: id);
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
    final initialStatus = (order.assignedDriverId != null && order.assignedDriverId!.isNotEmpty)
        ? OrderStatus.assigned
        : OrderStatus.pending;

    final newOrder = order.copyWith(id: id, status: initialStatus);

    try {
      await box.put(id, jsonEncode(newOrder.toJson()));
      debugPrint('ℹ️ [ORDER LOG 1/3] Order Saved To Hive: orders/$id (${newOrder.status.name})');

      _firebase.syncDocument(collection: 'orders', docId: id, data: newOrder.toJson());
      debugPrint('ℹ️ [ORDER LOG 2/3] Order Synced To Firestore: orders/$id');

      // If driver selected during order creation -> automatically execute assignDelivery()
      if (newOrder.assignedDriverId != null && newOrder.assignedDriverId!.isNotEmpty) {
        debugPrint('ℹ️ [ORDER LOG 3/3] Driver selected on creation: ${newOrder.assignedDriverId}. Executing assignDelivery...');
        await assignDelivery(
          orderId: id,
          driverId: newOrder.assignedDriverId!,
          driverName: newOrder.assignedDriverName ?? '',
        );
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> assignDelivery({
    required String orderId,
    required String driverId,
    required String driverName,
  }) async {
    try {
      final now = DateTime.now();
      final orderBox = HiveService.getBox(AppConstants.orderBoxName);
      final orderStr = orderBox.get(orderId);
      if (orderStr == null) {
        debugPrint('⚠️ Cannot assign delivery: Order $orderId not found in Hive');
        return false;
      }

      final order = OrderModel.fromJson(jsonDecode(orderStr));
      final previousDriverId = order.assignedDriverId;

      // 1. Update OrderModel in Hive & Firestore
      final updatedOrder = order.copyWith(
        assignedDriverId: driverId,
        assignedDriverName: driverName,
        status: OrderStatus.assigned,
      );
      await orderBox.put(orderId, jsonEncode(updatedOrder.toJson()));
      _firebase.syncDocument(collection: 'orders', docId: orderId, data: updatedOrder.toJson());

      // 2. Find or Create DeliveryModel
      final deliveryBox = HiveService.getBox(AppConstants.deliveryBoxName);
      final deliveryId = 'DEL-$orderId';
      final existingDeliveryStr = deliveryBox.get(deliveryId);

      DeliveryModel delivery;
      if (existingDeliveryStr != null) {
        final existing = DeliveryModel.fromJson(jsonDecode(existingDeliveryStr));
        delivery = existing.copyWith(
          employeeId: driverId,
          employeeName: driverName,
          deliveryStatus: 'assigned',
          updatedAt: now,
        );
      } else {
        delivery = DeliveryModel(
          deliveryId: deliveryId,
          orderId: orderId,
          customerId: order.customerId,
          customerName: order.customerName,
          phone: order.phone,
          address: order.address,
          employeeId: driverId,
          employeeName: driverName,
          deliveryStatus: 'assigned',
          deliveryDate: order.createdAt,
          quantity: order.quantity,
          unitPrice: order.unitPrice,
          totalAmount: order.totalAmount,
          createdAt: now,
          updatedAt: now,
        );
      }

      // Save DeliveryModel into Hive & Sync to Firestore
      await deliveryBox.put(deliveryId, jsonEncode(delivery.toJson()));
      _firebase.syncDocument(collection: 'deliveries', docId: deliveryId, data: delivery.toJson());

      // 3. Write Order Timeline & Audit Log
      final currentUser = _firebase.currentUser;
      final performedBy = currentUser?.email ?? driverName;
      final timelineId = 'TL-${now.millisecondsSinceEpoch}';
      final timelineData = {
        'event': (previousDriverId != null && previousDriverId.isNotEmpty) ? 'Driver Reassigned' : 'Driver Assigned',
        'previousDriverId': previousDriverId ?? '',
        'newDriverId': driverId,
        'driverName': driverName,
        'performedBy': performedBy,
        'timestamp': now.toIso8601String(),
      };
      _firebase.syncDocument(collection: 'orders/$orderId/timeline', docId: timelineId, data: timelineData);

      final auditId = 'AUD-${now.millisecondsSinceEpoch}';
      final auditLog = AuditLogModel(
        id: auditId,
        module: 'Orders',
        recordId: orderId,
        action: (previousDriverId != null && previousDriverId.isNotEmpty) ? 'REASSIGN_DRIVER' : 'ASSIGN_DRIVER',
        performedBy: performedBy,
        performedRole: 'Admin',
        oldData: {'assignedDriverId': previousDriverId},
        newData: {'assignedDriverId': driverId, 'assignedDriverName': driverName},
        createdAt: now,
      );
      _firebase.syncDocument(collection: 'audit_logs', docId: auditId, data: auditLog.toJson());

      debugPrint('✅ [DRIVER ASSIGNMENT SUCCESS] Order: $orderId assigned to $driverName ($driverId)');
      return true;
    } catch (e) {
      debugPrint('❌ Error assigning delivery: $e');
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
    final orderBox = HiveService.getBox(AppConstants.orderBoxName);
    final jsonStr = orderBox.get(orderId);
    if (jsonStr == null) return false;

    final order = OrderModel.fromJson(jsonDecode(jsonStr));

    // State machine check: Delivered or Cancelled orders are terminal
    if (order.status == OrderStatus.delivered || order.status == OrderStatus.cancelled) {
      debugPrint('⚠️ Order $orderId is already in terminal state ${order.status.name}. Update skipped.');
      return false;
    }

    final targetDriverId = driverId ?? order.assignedDriverId;
    final targetDriverName = driverName ?? order.assignedDriverName;

    final updated = order.copyWith(
      status: status,
      assignedDriverId: targetDriverId,
      assignedDriverName: targetDriverName,
      emptyCansCollected: emptyCansCollected > 0 ? emptyCansCollected : order.emptyCansCollected,
      damagedCansReported: damagedCansReported > 0 ? damagedCansReported : order.damagedCansReported,
      paymentStatus: paymentStatus ?? order.paymentStatus,
      paymentMode: paymentMode ?? order.paymentMode,
      deliveredAt: status == OrderStatus.delivered ? DateTime.now() : order.deliveredAt,
    );

    try {
      // 1. Update Order in Hive & Firestore
      await orderBox.put(orderId, jsonEncode(updated.toJson()));
      _firebase.syncDocument(collection: 'orders', docId: orderId, data: updated.toJson());

      // 2. If driver is set, ensure DeliveryModel is synced as well
      if (targetDriverId != null && targetDriverId.isNotEmpty) {
        final deliveryBox = HiveService.getBox(AppConstants.deliveryBoxName);
        final deliveryId = 'DEL-$orderId';
        final deliveryStr = deliveryBox.get(deliveryId);

        if (deliveryStr != null) {
          final existingDelivery = DeliveryModel.fromJson(jsonDecode(deliveryStr));
          final updatedDelivery = existingDelivery.copyWith(
            employeeId: targetDriverId,
            employeeName: targetDriverName ?? existingDelivery.employeeName,
            deliveryStatus: status.name,
            updatedAt: DateTime.now(),
          );
          await deliveryBox.put(deliveryId, jsonEncode(updatedDelivery.toJson()));
          _firebase.syncDocument(collection: 'deliveries', docId: deliveryId, data: updatedDelivery.toJson());
        } else {
          final newDelivery = DeliveryModel(
            deliveryId: deliveryId,
            orderId: orderId,
            customerId: order.customerId,
            customerName: order.customerName,
            phone: order.phone,
            address: order.address,
            employeeId: targetDriverId,
            employeeName: targetDriverName ?? '',
            deliveryStatus: status.name,
            deliveryDate: order.createdAt,
            quantity: order.quantity,
            unitPrice: order.unitPrice,
            totalAmount: order.totalAmount,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await deliveryBox.put(deliveryId, jsonEncode(newDelivery.toJson()));
          _firebase.syncDocument(collection: 'deliveries', docId: deliveryId, data: newDelivery.toJson());
        }
      }

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
      _firebase.deleteDocument(collection: 'orders', docId: id);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // --- DELIVERY MANAGEMENT MODULE ---
  List<DeliveryModel> getDeliveries() {
    try {
      final items = HiveService.getAll(AppConstants.deliveryBoxName);
      if (items.isEmpty) {
        // Build initial delivery models from orders if delivery box is empty
        final orders = getOrders();
        return orders.map((o) => DeliveryModel(
          deliveryId: 'DEL-${o.id}',
          orderId: o.id,
          customerId: o.customerId,
          customerName: o.customerName,
          phone: o.phone,
          address: o.address,
          employeeId: o.assignedDriverId ?? '',
          employeeName: o.assignedDriverName ?? '',
          deliveryStatus: o.status.name,
          deliveryDate: o.createdAt,
          quantity: o.quantity,
          unitPrice: o.unitPrice,
          totalAmount: o.totalAmount,
        )).toList();
      }
      final list = items.map((item) {
        return DeliveryModel.fromJson(jsonDecode(item as String));
      }).toList();
      list.sort((a, b) => b.deliveryDate.compareTo(a.deliveryDate));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveDelivery(DeliveryModel delivery) async {
    final box = HiveService.getBox(AppConstants.deliveryBoxName);
    try {
      await box.put(delivery.deliveryId, jsonEncode(delivery.toJson()));
      _firebase.syncDocument(collection: 'deliveries', docId: delivery.deliveryId, data: delivery.toJson());
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> executeDeliveryStatusAction({
    required DeliveryModel delivery,
    required String newStatus,
    required String reason,
    required String remarks,
    required String updatedBy,
    required String updatedRole,
    DateTime? rescheduledDate,
    int emptyCansCollected = 0,
    int damagedCansReported = 0,
    String paymentMode = 'Cash',
  }) async {
    try {
      final oldStatus = delivery.deliveryStatus;
      final now = DateTime.now();

      final updatedDelivery = delivery.copyWith(
        deliveryStatus: newStatus,
        reason: reason,
        remarks: remarks,
        updatedBy: updatedBy,
        updatedAt: now,
        completedAt: newStatus == 'delivered' ? now : delivery.completedAt,
        rescheduledDate: rescheduledDate ?? delivery.rescheduledDate,
        emptyCansCollected: emptyCansCollected > 0 ? emptyCansCollected : delivery.emptyCansCollected,
        damagedCansReported: damagedCansReported > 0 ? damagedCansReported : delivery.damagedCansReported,
        paymentMode: paymentMode,
      );

      // 1. Update Hive local storage
      final box = HiveService.getBox(AppConstants.deliveryBoxName);
      await box.put(delivery.deliveryId, jsonEncode(updatedDelivery.toJson()));

      // 2. Prepare History subcollection data: customers/{customerId}/history
      final historyMap = {
        'action': newStatus.toUpperCase(),
        'status': newStatus,
        'reason': reason,
        'remarks': remarks,
        'updatedBy': updatedBy,
        'createdAt': now.toIso8601String(),
        'date': now.toIso8601String(),
      };

      // 3. Prepare Audit Log data: audit_logs
      final auditLog = AuditLogModel(
        id: 'AUD-${now.millisecondsSinceEpoch}',
        module: 'Deliveries',
        recordId: delivery.deliveryId,
        action: 'UPDATE_DELIVERY_STATUS',
        performedBy: updatedBy,
        performedRole: updatedRole,
        oldData: {'status': oldStatus},
        newData: {'status': newStatus, 'reason': reason, 'remarks': remarks},
        createdAt: now,
      );

      if (newStatus == 'delivered') {
        // Inventory update
        final inventory = getInventory();
        final newFilled = (inventory.filledCans - delivery.quantity).clamp(0, 99999);
        final newEmpty = (inventory.emptyCans + emptyCansCollected).clamp(0, 99999);
        final newDamaged = inventory.damagedCans + damagedCansReported;
        final newCustomerBalance = inventory.customerBalanceCans + delivery.quantity - emptyCansCollected;

        final updatedInventory = inventory.copyWith(
          filledCans: newFilled,
          emptyCans: newEmpty,
          damagedCans: newDamaged,
          customerBalanceCans: newCustomerBalance,
          lastUpdated: now,
        );
        await saveInventory(updatedInventory);

        // Customer profile & ledger update
        Map<String, dynamic> custMap = {};
        final customerBox = HiveService.getBox(AppConstants.customerBoxName);
        final custStr = customerBox.get(delivery.customerId);
        if (custStr != null) {
          final cust = CustomerModel.fromJson(jsonDecode(custStr));
          final newCustBalance = (cust.canBalance + delivery.quantity - emptyCansCollected).clamp(0, 9999);
          final newEmptyPending = (cust.emptyCansPending + delivery.quantity - emptyCansCollected).clamp(0, 9999);
          final newDues = cust.pendingDues + delivery.totalAmount;

          final updatedCust = cust.copyWith(
            canBalance: newCustBalance,
            emptyCansPending: newEmptyPending,
            pendingDues: newDues,
          );
          await customerBox.put(cust.id, jsonEncode(updatedCust.toJson()));
          custMap = updatedCust.toJson();
        }

        // Execute Atomic Delivered Transaction in Firestore
        await _firebase.executeDeliveredTransaction(
          deliveryId: delivery.deliveryId,
          customerId: delivery.customerId,
          deliveryData: updatedDelivery.toJson(),
          customerData: custMap,
          inventoryData: updatedInventory.toJson(),
          customerHistoryData: historyMap,
          auditLogData: auditLog.toJson(),
        );
      } else if (newStatus == 'cancelled') {
        // Dedicated Order Cancellation Workflow
        final orderBox = HiveService.getBox(AppConstants.orderBoxName);
        String? originalOrderStr = orderBox.get(delivery.orderId);
        OrderModel? updatedOrder;

        if (originalOrderStr != null) {
          final originalOrder = OrderModel.fromJson(jsonDecode(originalOrderStr));

          // Pre-validation: verify order is not already cancelled or delivered
          if (originalOrder.status == OrderStatus.cancelled || originalOrder.status == OrderStatus.delivered) {
            debugPrint('⚠️ Order ${originalOrder.id} is already ${originalOrder.status.name}. Skipping cancellation.');
            return false;
          }

          updatedOrder = originalOrder.copyWith(
            status: OrderStatus.cancelled,
            notes: reason.isNotEmpty ? 'Cancelled: $reason${remarks.isNotEmpty ? " ($remarks)" : ""}' : originalOrder.notes,
          );

          // 1. Update Hive Order box immediately for fast local responsiveness
          await orderBox.put(originalOrder.id, jsonEncode(updatedOrder.toJson()));
        }

        // 2. Prepare Order Data Map for Firestore
        final orderMap = updatedOrder != null ? updatedOrder.toJson() : {
          'id': delivery.orderId,
          'status': 'cancelled',
          'cancelReason': reason,
          'cancelledByName': updatedBy,
          'cancelledByRole': updatedRole,
          'cancelledAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'updatedBy': updatedBy,
        };

        // Add additional tracking fields
        orderMap['cancelReason'] = reason;
        orderMap['cancelledByName'] = updatedBy;
        orderMap['cancelledByRole'] = updatedRole;
        orderMap['cancelledAt'] = now.toIso8601String();
        orderMap['updatedAt'] = now.toIso8601String();
        orderMap['updatedBy'] = updatedBy;

        // 3. Prepare Customer History Data Map
        final custHistoryMap = {
          'action': 'Order Cancelled',
          'status': 'cancelled',
          'orderId': delivery.orderId,
          'reason': reason,
          'remarks': remarks,
          'employeeName': updatedBy,
          'employeeId': delivery.employeeId,
          'timestamp': now.toIso8601String(),
          'createdAt': now.toIso8601String(),
          'date': now.toIso8601String(),
        };

        // 4. Prepare Timeline Data Map
        final timelineMap = {
          'event': 'Order Cancelled',
          'status': 'cancelled',
          'reason': reason,
          'remarks': remarks,
          'performedBy': updatedBy,
          'performedRole': updatedRole,
          'timestamp': now.toIso8601String(),
        };

        // 5. Prepare Audit Log Data Map
        final auditMap = {
          'module': 'Orders',
          'recordId': delivery.orderId,
          'action': 'Cancel',
          'performedBy': updatedBy,
          'performedRole': updatedRole,
          'reason': reason,
          'remarks': remarks,
          'timestamp': now.toIso8601String(),
          'createdAt': now.toIso8601String(),
        };

        try {
          // Execute Atomic Firestore WriteBatch Transaction
          await _firebase.executeOrderCancellationTransaction(
            orderId: delivery.orderId,
            deliveryId: delivery.deliveryId,
            customerId: delivery.customerId,
            orderData: orderMap,
            deliveryData: updatedDelivery.toJson(),
            customerHistoryData: custHistoryMap,
            timelineData: timelineMap,
            auditLogData: auditMap,
          );
          debugPrint('ℹ️ [CANCELLATION LOG 8/8] Cancellation Completed Successfully for Order: ${delivery.orderId}');
        } catch (e) {
          // Rollback Hive order box if Firestore batch fails
          if (originalOrderStr != null && updatedOrder != null) {
            await orderBox.put(updatedOrder.id, originalOrderStr);
          }
          rethrow;
        }
      } else {
        // Execute Atomic Delivery Action Transaction in Firestore for other non-delivered actions (Reschedule, Not Available, Skip)
        await _firebase.executeDeliveryActionTransaction(
          deliveryId: delivery.deliveryId,
          customerId: delivery.customerId,
          deliveryData: updatedDelivery.toJson(),
          customerHistoryData: historyMap,
          auditLogData: auditLog.toJson(),
        );
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error executing delivery status action: $e');
      }
      return false;
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
      final newEmptyPending = (cust.emptyCansPending + order.quantity - order.emptyCansCollected).clamp(0, 9999);
      final newDues = order.paymentStatus == PaymentStatus.paid
          ? cust.pendingDues
          : cust.pendingDues + order.totalAmount;

      final updatedCust = cust.copyWith(
        canBalance: newCustBalance,
        emptyCansPending: newEmptyPending,
        pendingDues: newDues,
      );
      await customerBox.put(cust.id, jsonEncode(updatedCust.toJson()));
      _firebase.syncDocument(collection: 'customers', docId: cust.id, data: updatedCust.toJson());
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
      _firebase.syncDocument(collection: 'inventory', docId: 'current', data: inventory.toJson());
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
      _firebase.syncDocument(collection: 'water_purchases', docId: id, data: item.toJson());

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
      _firebase.syncDocument(collection: 'employees', docId: id, data: emp.toJson());
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteEmployee(String id) async {
    try {
      final box = HiveService.getBoxSafe(AppConstants.employeeBoxName);
      if (box != null) await box.delete(id);
      _firebase.deleteDocument(collection: 'employees', docId: id);
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
      _firebase.syncDocument(collection: 'salaries', docId: id, data: item.toJson());

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
      _firebase.syncDocument(collection: 'expenses', docId: id, data: item.toJson());
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
      _firebase.syncDocument(collection: 'payments', docId: id, data: item.toJson());

      // Deduct pending dues from customer record
      final custBox = HiveService.getBoxSafe(AppConstants.customerBoxName);
      if (custBox != null) {
        final custStr = custBox.get(payment.customerId);
        if (custStr != null) {
          final cust = CustomerModel.fromJson(jsonDecode(custStr));
          final updatedDues = (cust.pendingDues - payment.amount).clamp(0.0, 999999.0);
          final updatedCust = cust.copyWith(pendingDues: updatedDues);
          await custBox.put(cust.id, jsonEncode(updatedCust.toJson()));
          _firebase.syncDocument(collection: 'customers', docId: cust.id, data: updatedCust.toJson());
        }
      }
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // --- SETTINGS MODULE ---
  SettingsModel getSettings() {
    try {
      final box = HiveService.getBoxSafe(AppConstants.settingsBoxName);
      if (box != null) {
        final str = box.get('app_settings');
        if (str != null) {
          return SettingsModel.fromJson(jsonDecode(str));
        }
      }
    } catch (_) {}
    return SettingsModel();
  }

  Future<bool> saveSettings(SettingsModel settings) async {
    try {
      final box = HiveService.getBoxSafe(AppConstants.settingsBoxName);
      if (box != null) {
        await box.put('app_settings', jsonEncode(settings.toJson()));
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }
}
