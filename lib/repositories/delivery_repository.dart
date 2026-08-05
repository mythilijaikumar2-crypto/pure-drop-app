import 'dart:convert';
import '../core/constants/app_constants.dart';
import '../core/constants/app_enums.dart';
import '../core/storage/hive_service.dart';
import '../core/utils/result.dart';
import '../models/order_model.dart';
import 'base_repository.dart';

class DeliveryRepository extends BaseRepository {
  Future<Result<List<OrderModel>>> getActiveDeliveries({String? driverId}) async {
    try {
      final items = HiveService.getAll(AppConstants.orderBoxName);
      final list = items.map((item) {
        return OrderModel.fromJson(jsonDecode(item as String));
      }).where((o) {
        final isActive = o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled;
        if (driverId != null && driverId.isNotEmpty) {
          return isActive && o.assignedDriverId == driverId;
        }
        return isActive;
      }).toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Success(list);
    } catch (e, stack) {
      return Failure('Failed to fetch active deliveries: $e', e, stack);
    }
  }

  Future<Result<List<OrderModel>>> getCompletedDeliveries({String? driverId}) async {
    try {
      final items = HiveService.getAll(AppConstants.orderBoxName);
      final list = items.map((item) {
        return OrderModel.fromJson(jsonDecode(item as String));
      }).where((o) {
        final isDone = o.status == OrderStatus.delivered;
        if (driverId != null && driverId.isNotEmpty) {
          return isDone && o.assignedDriverId == driverId;
        }
        return isDone;
      }).toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Success(list);
    } catch (e, stack) {
      return Failure('Failed to fetch completed deliveries: $e', e, stack);
    }
  }
}
