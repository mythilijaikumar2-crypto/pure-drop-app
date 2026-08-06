import '../models/delivery_model.dart';

/// Abstract Delivery Repository Interface.
///
/// Ensures Clean Architecture decoupling. In offline mode, implemented by Hive
/// (`AppRepository`). For future Firebase integration, replace only the
/// repository implementation without modifying UI or Riverpod providers.
abstract class IDeliveryRepository {
  List<DeliveryModel> getDeliveries();

  Future<bool> saveDelivery(DeliveryModel delivery);

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
  });

  Future<bool> undoLastDeliveryAction(String deliveryId);

  Future<bool> shiftDeliverySlot(String deliveryId, String newSlot);

  Future<bool> changeDeliveryQuantity(String deliveryId, int newQuantity);

  Future<bool> collectPayment({
    required String deliveryId,
    required double amount,
    required String paymentMode,
  });
}
