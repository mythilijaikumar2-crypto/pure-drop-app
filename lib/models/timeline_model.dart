class TimelineModel {
  final String id;
  final String title;
  final String description;
  final String category; // Customer, Order, Payment, Expense, Delivery, Employee, System
  final String recordId;
  final DateTime timestamp;
  final String performedBy;
  final Map<String, dynamic> metadata;

  TimelineModel({
    required this.id,
    required this.title,
    required this.description,
    this.category = 'System',
    this.recordId = '',
    DateTime? timestamp,
    this.performedBy = 'Admin',
    this.metadata = const {},
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'recordId': recordId,
        'timestamp': timestamp.toIso8601String(),
        'performedBy': performedBy,
        'metadata': metadata,
      };

  factory TimelineModel.fromJson(Map<String, dynamic> json) => TimelineModel(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        category: json['category'] ?? 'System',
        recordId: json['recordId'] ?? '',
        timestamp: json['timestamp'] != null
            ? (DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now())
            : DateTime.now(),
        performedBy: json['performedBy'] ?? 'Admin',
        metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      );
}
