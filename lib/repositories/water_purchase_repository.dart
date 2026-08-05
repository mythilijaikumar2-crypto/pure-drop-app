import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/app_enums.dart';
import '../core/storage/hive_service.dart';
import '../core/utils/result.dart';
import '../models/expense_model.dart';
import '../models/inventory_model.dart';
import '../models/water_purchase_model.dart';
import 'base_repository.dart';

class WaterPurchaseRepository extends BaseRepository {
  final Uuid _uuid = const Uuid();

  Future<Result<List<WaterPurchaseModel>>> getWaterPurchases() async {
    try {
      final items = HiveService.getAll(AppConstants.waterPurchaseBoxName);
      final list = items.map((item) {
        return WaterPurchaseModel.fromJson(jsonDecode(item as String));
      }).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return Success(list);
    } catch (e, stack) {
      return Failure('Failed to fetch water purchases: $e', e, stack);
    }
  }

  Future<Result<WaterPurchaseModel>> addWaterPurchase(WaterPurchaseModel purchase) async {
    try {
      final box = HiveService.getBoxSafe(AppConstants.waterPurchaseBoxName);
      final id = purchase.id.isEmpty ? 'WP-${_uuid.v4().substring(0, 5).toUpperCase()}' : purchase.id;
      final item = purchase.copyWith(id: id);

      if (box != null) await box.put(id, jsonEncode(item.toJson()));
      await enqueueSync(
        collection: 'water_purchases',
        docId: id,
        action: 'set',
        data: item.toJson(),
      );

      // 1. Update Inventory Stock
      final invBox = HiveService.getBoxSafe(AppConstants.inventoryBoxName);
      InventoryModel inv = InventoryModel.initial();
      if (invBox != null) {
        final str = invBox.get('current');
        if (str != null) inv = InventoryModel.fromJson(jsonDecode(str));
      }

      final updatedInv = inv.copyWith(
        filledCans: inv.filledCans + purchase.cansPurchased,
        totalCans: inv.totalCans + (purchase.notes.contains('New Cans') ? purchase.cansPurchased : 0),
        lastUpdated: DateTime.now(),
      );

      if (invBox != null) await invBox.put('current', jsonEncode(updatedInv.toJson()));
      await enqueueSync(
        collection: 'inventory',
        docId: 'current',
        action: 'set',
        data: updatedInv.toJson(),
      );

      // 2. Log Financial Expense
      final expBox = HiveService.getBoxSafe(AppConstants.expenseBoxName);
      final expId = 'EXP-WP-$id';
      final exp = ExpenseModel(
        id: expId,
        category: ExpenseCategory.waterPurchase,
        amount: purchase.totalCost,
        description: 'Water Purchase batch from ${purchase.plantName} (${purchase.cansPurchased} Cans)',
        spentBy: 'Admin',
        date: purchase.date,
      );

      if (expBox != null) await expBox.put(expId, jsonEncode(exp.toJson()));
      await enqueueSync(
        collection: 'expenses',
        docId: expId,
        action: 'set',
        data: exp.toJson(),
      );

      return Success(item);
    } catch (e, stack) {
      return Failure('Failed to log water purchase: $e', e, stack);
    }
  }
}
