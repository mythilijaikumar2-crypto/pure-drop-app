import '../../models/audit_log_model.dart';

abstract class IAuditRepository {
  Future<void> logAudit(AuditLogModel audit);
  Future<List<AuditLogModel>> getAuditLogs({String? entityName, String? entityId, int limit = 50});
}
