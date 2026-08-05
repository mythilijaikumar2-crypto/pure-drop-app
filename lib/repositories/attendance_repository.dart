import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../core/storage/hive_service.dart';
import '../core/utils/result.dart';
import '../models/attendance_model.dart';
import 'base_repository.dart';

class AttendanceRepository extends BaseRepository {
  static const String attendanceBoxName = 'attendance_box';
  final Uuid _uuid = const Uuid();

  Future<Result<List<AttendanceModel>>> getAttendance() async {
    try {
      final items = HiveService.getAll(attendanceBoxName);
      final list = items.map((item) {
        return AttendanceModel.fromJson(jsonDecode(item as String));
      }).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return Success(list);
    } catch (e, stack) {
      return Failure('Failed to fetch attendance logs: $e', e, stack);
    }
  }

  Future<Result<AttendanceModel>> markAttendance(AttendanceModel attendance) async {
    try {
      final box = HiveService.getBoxSafe(attendanceBoxName);
      final id = attendance.id.isEmpty ? 'ATT-${_uuid.v4().substring(0, 5).toUpperCase()}' : attendance.id;
      final item = attendance.copyWith(id: id);

      if (box != null) await box.put(id, jsonEncode(item.toJson()));
      await enqueueSync(
        collection: 'attendance',
        docId: id,
        action: 'set',
        data: item.toJson(),
      );

      return Success(item);
    } catch (e, stack) {
      return Failure('Failed to log attendance: $e', e, stack);
    }
  }
}
