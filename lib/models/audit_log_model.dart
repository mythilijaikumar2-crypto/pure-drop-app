class AuditLogModel {
  final String id;
  final String module;
  final String recordId;
  final String action;
  final String performedBy;
  final String performedRole;
  final Map<String, dynamic> oldData;
  final Map<String, dynamic> newData;
  final DateTime createdAt;

  AuditLogModel({
    required this.id,
    required this.module,
    required this.recordId,
    required this.action,
    required this.performedBy,
    required this.performedRole,
    this.oldData = const {},
    this.newData = const {},
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'module': module,
        'recordId': recordId,
        'action': action,
        'performedBy': performedBy,
        'performedRole': performedRole,
        'oldData': oldData,
        'newData': newData,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AuditLogModel.fromJson(Map<String, dynamic> json) => AuditLogModel(
        id: json['id'] ?? '',
        module: json['module'] ?? 'Deliveries',
        recordId: json['recordId'] ?? '',
        action: json['action'] ?? '',
        performedBy: json['performedBy'] ?? '',
        performedRole: json['performedRole'] ?? 'Admin',
        oldData: Map<String, dynamic>.from(json['oldData'] ?? {}),
        newData: Map<String, dynamic>.from(json['newData'] ?? {}),
        createdAt: json['createdAt'] != null
            ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
            : DateTime.now(),
      );
}
