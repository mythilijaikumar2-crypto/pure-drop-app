import 'dart:convert';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_enums.dart';
import '../../core/storage/hive_service.dart';
import '../../models/order_model.dart';
import '../interfaces/i_order_repository.dart';

class HiveOrderRepository implements IOrderRepository {
  @override
  Future<List<OrderModel>> getOrders() async {
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

  @override
  Future<OrderModel?> getOrderById(String id) async {
    try {
      final box = HiveService.getBox(AppConstants.orderBoxName);
      final raw = box.get(id);
      if (raw == null) return null;
      return OrderModel.fromJson(jsonDecode(raw as String));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> createOrder(OrderModel order) async {
    final box = HiveService.getBox(AppConstants.orderBoxName);
    final id = order.id.isEmpty ? 'ORD-${1000 + box.length + 1}' : order.id;
    final initialStatus = (order.assignedDriverId != null && order.assignedDriverId!.isNotEmpty)
        ? OrderStatus.assigned
        : OrderStatus.pending;

    final newOrder = order.copyWith(id: id, status: initialStatus, updatedAt: DateTime.now());

    try {
      await box.put(id, jsonEncode(newOrder.toJson()));
      return true;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> updateOrder(OrderModel order) async {
    final box = HiveService.getBox(AppConstants.orderBoxName);
    final updated = order.copyWith(updatedAt: DateTime.now());
    try {
      await box.put(order.id, jsonEncode(updated.toJson()));
      return true;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> deleteOrder(String id) async {
    final box = HiveService.getBox(AppConstants.orderBoxName);
    try {
      await box.delete(id);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<OrderModel>> getOrdersByCustomer(String customerId) async {
    final all = await getOrders();
    return all.where((o) => o.customerId == customerId).toList();
  }

  @override
  Future<List<OrderModel>> getOrdersByDriver(String driverId) async {
    final all = await getOrders();
    return all.where((o) => o.assignedDriverId == driverId).toList();
  }

  @override
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
    final order = await getOrderById(orderId);
    if (order == null) return false;

    final updated = order.copyWith(
      status: status,
      assignedDriverId: driverId ?? order.assignedDriverId,
      assignedDriverName: driverName ?? order.assignedDriverName,
      emptyCansCollected: emptyCansCollected > 0 ? emptyCansCollected : order.emptyCansCollected,
      damagedCansReported: damagedCansReported > 0 ? damagedCansReported : order.damagedCansReported,
      paymentStatus: paymentStatus ?? order.paymentStatus,
      paymentMode: paymentMode ?? order.paymentMode,
      deliveredAt: status == OrderStatus.delivered ? DateTime.now() : order.deliveredAt,
      updatedAt: DateTime.now(),
    );

    return updateOrder(updated);
  }
}
