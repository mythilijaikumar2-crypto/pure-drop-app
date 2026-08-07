import 'dart:convert';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../storage/hive_service.dart';

class ExportService {
  /// Convert list of Map JSON objects into valid CSV format
  static String convertToCSV(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return 'No data available';

    // Extract all unique headers across items
    final Set<String> headersSet = {};
    for (var item in items) {
      headersSet.addAll(item.keys);
    }
    final headers = headersSet.toList();
    final buffer = StringBuffer();

    // Write Column Headers
    buffer.writeln(headers.map((h) => '"${h.replaceAll('"', '""')}"').join(','));

    // Write Data Rows
    for (var item in items) {
      final row = headers.map((h) {
        final val = item[h];
        if (val == null) return '""';
        final str = val.toString().replaceAll('"', '""');
        return '"$str"';
      }).join(',');
      buffer.writeln(row);
    }

    return buffer.toString();
  }

  /// Generate complete multi-collection CSV export
  static String generateCompleteERPExportCSV(Map<String, List<Map<String, dynamic>>> collectionsData) {
    final buffer = StringBuffer();
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    buffer.writeln('PURE DROP AQUA - COMPLETE DATABASE EXPORT');
    buffer.writeln('Export Timestamp: ${formatter.format(DateTime.now())}');
    buffer.writeln('Database Engine: Hive Local Storage');
    buffer.writeln('----------------------------------------------------');
    buffer.writeln('');

    collectionsData.forEach((collectionName, items) {
      buffer.writeln('====================================================');
      buffer.writeln('COLLECTION: ${collectionName.toUpperCase()} (${items.length} Records)');
      buffer.writeln('====================================================');
      if (items.isNotEmpty) {
        buffer.writeln(convertToCSV(items));
      } else {
        buffer.writeln('No records in collection.');
      }
      buffer.writeln('');
    });

    return buffer.toString();
  }

  /// Fetch all collection data from Hive boxes for offline-first export
  static Map<String, List<Map<String, dynamic>>> getALLCollectionsData() {
    Map<String, List<Map<String, dynamic>>> data = {};

    final Map<String, String> boxMap = {
      'customers': AppConstants.customerBoxName,
      'orders': AppConstants.orderBoxName,
      'inventory': AppConstants.inventoryBoxName,
      'payments': AppConstants.paymentBoxName,
      'expenses': AppConstants.expenseBoxName,
      'employees': AppConstants.employeeBoxName,
      'water_purchases': AppConstants.waterPurchaseBoxName,
      'salary': AppConstants.salaryBoxName,
      'attendance': AppConstants.attendanceBoxName,
      'settings': AppConstants.settingsBoxName,
    };

    boxMap.forEach((name, boxName) {
      final rawItems = HiveService.getAll(boxName);
      final list = rawItems.map((item) {
        try {
          if (item is String) {
            return Map<String, dynamic>.from(jsonDecode(item));
          } else if (item is Map) {
            return Map<String, dynamic>.from(item);
          }
        } catch (_) {}
        return <String, dynamic>{};
      }).where((m) => m.isNotEmpty).toList();
      data[name] = list;
    });

    return data;
  }
}
