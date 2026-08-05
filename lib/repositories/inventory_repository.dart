import 'dart:convert';
import '../core/constants/app_constants.dart';
import '../core/storage/hive_service.dart';
import '../core/utils/result.dart';
import '../models/inventory_model.dart';
import 'base_repository.dart';

class InventoryRepository extends BaseRepository {
  Future<Result<InventoryModel>> getInventory() async {
    try {
      final box = HiveService.getBoxSafe(AppConstants.inventoryBoxName);
      if (box != null) {
        final str = box.get('current');
        if (str != null) {
          return Success(InventoryModel.fromJson(jsonDecode(str)));
        }
      }
      return Success(InventoryModel.initial());
    } catch (e, stack) {
      return Failure('Failed to load inventory: $e', e, stack);
    }
  }

  Future<Result<InventoryModel>> saveInventory(InventoryModel inventory) async {
    try {
      final box = HiveService.getBox(AppConstants.inventoryBoxName);
      await box.put('current', jsonEncode(inventory.toJson()));
      await enqueueSync(
        collection: 'inventory',
        docId: 'current',
        action: 'set',
        data: inventory.toJson(),
      );
      return Success(inventory);
    } catch (e, stack) {
      return Failure('Failed to save inventory: $e', e, stack);
    }
  }
}
