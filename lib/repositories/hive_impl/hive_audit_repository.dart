import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import '../../models/audit_log_model.dart';
import '../interfaces/i_audit_repository.dart';

class HiveAuditRepository implements IAuditRepository {
  Box<Map> get _box => Hive.box<Map>(AppConstants.timelineBoxName);

  @override
  Future<void> logAudit(AuditLogModel audit) async {
    final id = audit.id.isNotEmpty ? audit.id : 'AUDIT-${DateTime.now().millisecondsSinceEpoch}';
    final data = audit.toJson();
    data['id'] = id;
    data['isAuditLog'] = true;
    await _box.put(id, data);
  }

  @override
  Future<List<AuditLogModel>> getAuditLogs({String? entityName, String? entityId, int limit = 50}) async {
    final logs = _box.values
        .where((m) => m['isAuditLog'] == true)
        .map((m) => AuditLogModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return logs.where((l) {
      if (entityName != null && entityName.isNotEmpty && l.entityName != entityName) {
        return false;
      }
      if (entityId != null && entityId.isNotEmpty && l.entityId != entityId) {
        return false;
      }
      return true;
    }).take(limit).toList();
  }
}
