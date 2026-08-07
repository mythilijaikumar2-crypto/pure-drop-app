class AuditLogModel {
  final String id;
  final String entityName;
  final String entityId;
  final String action;
  final String performedBy;
  final DateTime timestamp;
  final Map<String, dynamic> oldData;
  final Map<String, dynamic> newData;
  final String tenantId;
  final String branchId;

  AuditLogModel({
    required this.id,
    required this.entityName,
    required this.entityId,
    required this.action,
    required this.performedBy,
    required this.timestamp,
    this.oldData = const {},
    this.newData = const {},
    this.tenantId = 'TENANT_DEFAULT',
    this.branchId = 'BRANCH_MAIN',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'entityName': entityName,
        'entityId': entityId,
        'action': action,
        'performedBy': performedBy,
        'timestamp': timestamp.toIso8601String(),
        'oldData': oldData,
        'newData': newData,
        'tenantId': tenantId,
        'branchId': branchId,
      };

  factory AuditLogModel.fromJson(Map<String, dynamic> json) => AuditLogModel(
        id: json['id'] ?? '',
        entityName: json['entityName'] ?? '',
        entityId: json['entityId'] ?? '',
        action: json['action'] ?? '',
        performedBy: json['performedBy'] ?? 'Admin',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'])
            : DateTime.now(),
        oldData: Map<String, dynamic>.from(json['oldData'] ?? {}),
        newData: Map<String, dynamic>.from(json['newData'] ?? {}),
        tenantId: json['tenantId'] ?? 'TENANT_DEFAULT',
        branchId: json['branchId'] ?? 'BRANCH_MAIN',
      );
}
