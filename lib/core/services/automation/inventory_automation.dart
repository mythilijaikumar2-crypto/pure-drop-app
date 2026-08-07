import 'dart:convert';
import '../../constants/app_constants.dart';
import '../../storage/hive_service.dart';
import '../../../models/inventory_model.dart';
import 'timeline_automation.dart';

class InventoryAutomation {
  final TimelineAutomation _timelineAutomation;

  InventoryAutomation(this._timelineAutomation);

  InventoryModel getInventory() {
    try {
      final box = HiveService.getBox(AppConstants.inventoryBoxName);
      final raw = box.get('current');
      if (raw == null) {
        final initial = InventoryModel.initial();
        saveInventory(initial);
        return initial;
      }
      return InventoryModel.fromJson(jsonDecode(raw as String));
    } catch (_) {
      return InventoryModel.initial();
    }
  }

  Future<bool> saveInventory(InventoryModel inventory) async {
    try {
      final box = HiveService.getBox(AppConstants.inventoryBoxName);
      await box.put('current', jsonEncode(inventory.toJson()));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> processDeliveryCompleted({
    required int filledCansDelivered,
    required int emptyCansReturned,
    required int damagedCansReported,
  }) async {
    final current = getInventory();

    final newFilled = (current.filledCans - filledCansDelivered).clamp(0, 99999);
    final newEmpty = (current.emptyCans + emptyCansReturned).clamp(0, 99999);
    final newDamaged = current.damagedCans + damagedCansReported;
    final newCustBalance = current.customerBalanceCans + filledCansDelivered - emptyCansReturned;

    final updated = current.copyWith(
      filledCans: newFilled,
      emptyCans: newEmpty,
      damagedCans: newDamaged,
      customerBalanceCans: newCustBalance.clamp(0, 99999),
      lastUpdated: DateTime.now(),
    );

    await saveInventory(updated);

    await _timelineAutomation.logEvent(
      title: 'Inventory Updated',
      description: 'Delivered: $filledCansDelivered, Empty Returned: $emptyCansReturned, Damaged: $damagedCansReported',
      category: 'Delivery',
    );
  }

  Future<void> processWaterPurchase({required int filledCansPurchased}) async {
    final current = getInventory();
    final updated = current.copyWith(
      filledCans: current.filledCans + filledCansPurchased,
      emptyCans: (current.emptyCans - filledCansPurchased).clamp(0, 99999),
      lastUpdated: DateTime.now(),
    );
    await saveInventory(updated);

    await _timelineAutomation.logEvent(
      title: 'Water Purchase Recorded',
      description: 'Stock added: +$filledCansPurchased filled cans',
      category: 'Expense',
    );
  }
}
