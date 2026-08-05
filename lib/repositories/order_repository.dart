import 'dart:convert';
import '../core/constants/app_constants.dart';
import '../core/constants/app_enums.dart';
import '../core/storage/hive_service.dart';
import '../core/utils/result.dart';
import '../models/customer_model.dart';
import '../models/inventory_model.dart';
import '../models/order_model.dart';
import 'base_repository.dart';

class OrderRepository extends BaseRepository {
  Future<Result<List<OrderModel>>> getOrders() async {
    try {
      final items = HiveService.getAll(AppConstants.orderBoxName);
      final list = items.map((item) {
        final Map<String, dynamic> json = jsonDecode(item as String);
        return OrderModel.fromJson(json);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Success(list);
    } catch (e, stack) {
      return Failure('Failed to fetch orders: $e', e, stack);
    }
  }

  Future<Result<OrderModel>> createOrder(OrderModel order, {UserRole? role}) async {
    try {
      if (role != null && role != UserRole.admin) {
        return const Failure('Unauthorized: Order creation requires Admin privilege.');
      }
      final box = HiveService.getBox(AppConstants.orderBoxName);
      final id = order.id.isEmpty ? 'ORD-${1000 + box.length + 1}' : order.id;
      final newOrder = order.copyWith(id: id);

      await box.put(id, jsonEncode(newOrder.toJson()));
      await enqueueSync(
        collection: 'orders',
        docId: id,
        action: 'set',
        data: newOrder.toJson(),
      );

      return Success(newOrder);
    } catch (e, stack) {
      return Failure('Failed to create order: $e', e, stack);
    }
  }

  Future<Result<OrderModel>> updateOrderStatus(
    String orderId,
    OrderStatus status, {
    String? driverId,
    String? driverName,
    int emptyCansCollected = 0,
    int damagedCansReported = 0,
    PaymentStatus? paymentStatus,
    PaymentMode? paymentMode,
  }) async {
    try {
      final box = HiveService.getBox(AppConstants.orderBoxName);
      final jsonStr = box.get(orderId);
      if (jsonStr == null) return Failure('Order $orderId not found');

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
      await enqueueSync(
        collection: 'orders',
        docId: orderId,
        action: 'set',
        data: updated.toJson(),
      );

      if (status == OrderStatus.delivered) {
        await _onOrderDelivered(updated);
      }

      return Success(updated);
    } catch (e, stack) {
      return Failure('Failed to update order status: $e', e, stack);
    }
  }

  Future<Result<bool>> deleteOrder(String id, {UserRole? role}) async {
    try {
      if (role != null && role != UserRole.admin) {
        return const Failure('Unauthorized: Order deletion requires Admin privilege.');
      }
      final box = HiveService.getBox(AppConstants.orderBoxName);
      await box.delete(id);
      await enqueueSync(
        collection: 'orders',
        docId: id,
        action: 'delete',
        data: {},
      );
      return const Success(true);
    } catch (e, stack) {
      return Failure('Failed to delete order: $e', e, stack);
    }
  }

  Future<void> _onOrderDelivered(OrderModel order) async {
    // 1. Update Inventory Stock
    final invBox = HiveService.getBoxSafe(AppConstants.inventoryBoxName);
    InventoryModel inventory = InventoryModel.initial();
    if (invBox != null) {
      final str = invBox.get('current');
      if (str != null) inventory = InventoryModel.fromJson(jsonDecode(str));
    }

    final newFilled = (inventory.filledCans - order.quantity).clamp(0, 99999);
    final newEmpty = (inventory.emptyCans + order.emptyCansCollected).clamp(0, 99999);
    final newDamaged = inventory.damagedCans + order.damagedCansReported;
    final newCustBalance = inventory.customerBalanceCans + order.quantity - order.emptyCansCollected;

    final updatedInv = inventory.copyWith(
      filledCans: newFilled,
      emptyCans: newEmpty,
      damagedCans: newDamaged,
      customerBalanceCans: newCustBalance,
      lastUpdated: DateTime.now(),
    );

    if (invBox != null) await invBox.put('current', jsonEncode(updatedInv.toJson()));
    await enqueueSync(
      collection: 'inventory',
      docId: 'current',
      action: 'set',
      data: updatedInv.toJson(),
    );

    // 2. Update Customer Balance & Pending Dues
    final custBox = HiveService.getBoxSafe(AppConstants.customerBoxName);
    if (custBox != null) {
      final custStr = custBox.get(order.customerId);
      if (custStr != null) {
        final cust = CustomerModel.fromJson(jsonDecode(custStr));
        final newCansHeld = (cust.canBalance + order.quantity - order.emptyCansCollected).clamp(0, 9999);
        final newDues = order.paymentStatus == PaymentStatus.paid
            ? cust.pendingDues
            : cust.pendingDues + order.totalAmount;

        final updatedCust = cust.copyWith(
          canBalance: newCansHeld,
          pendingDues: newDues,
        );
        await custBox.put(cust.id, jsonEncode(updatedCust.toJson()));
        await enqueueSync(
          collection: 'customers',
          docId: cust.id,
          action: 'set',
          data: updatedCust.toJson(),
        );
      }
    }
  }
}
