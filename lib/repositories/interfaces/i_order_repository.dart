import '../../models/order_model.dart';
import '../../core/constants/app_enums.dart';

abstract class IOrderRepository {
  Future<List<OrderModel>> getOrders();
  Future<OrderModel?> getOrderById(String id);
  Future<bool> createOrder(OrderModel order);
  Future<bool> updateOrder(OrderModel order);
  Future<bool> deleteOrder(String id);
  Future<List<OrderModel>> getOrdersByCustomer(String customerId);
  Future<List<OrderModel>> getOrdersByDriver(String driverId);
  Future<bool> updateOrderStatus(
    String orderId,
    OrderStatus status, {
    String? driverId,
    String? driverName,
    int emptyCansCollected = 0,
    int damagedCansReported = 0,
    PaymentStatus? paymentStatus,
    PaymentMode? paymentMode,
  });
}
