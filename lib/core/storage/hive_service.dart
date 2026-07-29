import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';

class HiveService {
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();
    } catch (e) {
      debugPrint('Hive initFlutter exception: $e');
    }
    
    // Open default boxes safely
    await _openBoxSafe(AppConstants.authBoxName);
    await _openBoxSafe(AppConstants.customerBoxName);
    await _openBoxSafe(AppConstants.orderBoxName);
    await _openBoxSafe(AppConstants.inventoryBoxName);
    await _openBoxSafe(AppConstants.waterPurchaseBoxName);
    await _openBoxSafe(AppConstants.deliveryBoxName);
    await _openBoxSafe(AppConstants.employeeBoxName);
    await _openBoxSafe(AppConstants.salaryBoxName);
    await _openBoxSafe(AppConstants.expenseBoxName);
    await _openBoxSafe(AppConstants.paymentBoxName);
    await _openBoxSafe(AppConstants.settingsBoxName);

    _isInitialized = true;
  }

  static Future<void> _openBoxSafe(String boxName) async {
    try {
      if (!Hive.isBoxOpen(boxName)) {
        await Hive.openBox(boxName);
      }
    } catch (e) {
      debugPrint('Hive openBox exception for $boxName: $e. Attempting box reset recovery...');
      try {
        await Hive.deleteBoxFromDisk(boxName);
        await Hive.openBox(boxName);
      } catch (recoveryError) {
        debugPrint('Hive box recovery failed for $boxName: $recoveryError');
      }
    }
  }

  static bool isBoxOpen(String boxName) {
    return Hive.isBoxOpen(boxName);
  }

  static Box? getBoxSafe(String boxName) {
    try {
      if (Hive.isBoxOpen(boxName)) {
        return Hive.box(boxName);
      }
    } catch (e) {
      debugPrint('Hive getBoxSafe exception for $boxName: $e');
    }
    return null;
  }

  static Box getBox(String boxName) {
    final safeBox = getBoxSafe(boxName);
    if (safeBox != null) return safeBox;
    return Hive.box(boxName);
  }

  static Future<void> saveData(String boxName, String key, dynamic value) async {
    try {
      if (!Hive.isBoxOpen(boxName)) {
        await _openBoxSafe(boxName);
      }
      final box = getBoxSafe(boxName);
      if (box != null) {
        await box.put(key, value);
      }
    } catch (e) {
      debugPrint('Hive saveData error for $boxName: $e');
    }
  }

  static dynamic getData(String boxName, String key, {dynamic defaultValue}) {
    try {
      final box = getBoxSafe(boxName);
      if (box != null) {
        return box.get(key, defaultValue: defaultValue);
      }
    } catch (e) {
      debugPrint('Hive getData error for $boxName: $e');
    }
    return defaultValue;
  }

  static List<dynamic> getAll(String boxName) {
    try {
      final box = getBoxSafe(boxName);
      if (box != null) {
        return box.values.toList();
      }
    } catch (e) {
      debugPrint('Hive getAll error for $boxName: $e');
    }
    return [];
  }

  static Future<void> deleteData(String boxName, String key) async {
    try {
      final box = getBoxSafe(boxName);
      if (box != null) {
        await box.delete(key);
      }
    } catch (e) {
      debugPrint('Hive deleteData error for $boxName: $e');
    }
  }
}
