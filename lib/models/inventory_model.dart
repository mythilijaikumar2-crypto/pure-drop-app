class InventoryModel {
  final int totalCans;
  final int filledCans;
  final int emptyCans;
  final int damagedCans;
  final int customerBalanceCans;
  final DateTime lastUpdated;

  InventoryModel({
    required this.totalCans,
    required this.filledCans,
    required this.emptyCans,
    required this.damagedCans,
    required this.customerBalanceCans,
    required this.lastUpdated,
  });

  factory InventoryModel.initial() => InventoryModel(
        totalCans: 500,
        filledCans: 280,
        emptyCans: 120,
        damagedCans: 10,
        customerBalanceCans: 90,
        lastUpdated: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'totalCans': totalCans,
        'filledCans': filledCans,
        'emptyCans': emptyCans,
        'damagedCans': damagedCans,
        'customerBalanceCans': customerBalanceCans,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory InventoryModel.fromJson(Map<String, dynamic> json) => InventoryModel(
        totalCans: (json['totalCans'] as num?)?.toInt() ?? 500,
        filledCans: (json['filledCans'] as num?)?.toInt() ?? 280,
        emptyCans: (json['emptyCans'] as num?)?.toInt() ?? 120,
        damagedCans: (json['damagedCans'] as num?)?.toInt() ?? 10,
        customerBalanceCans: (json['customerBalanceCans'] as num?)?.toInt() ?? 90,
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.parse(json['lastUpdated'])
            : DateTime.now(),
      );

  InventoryModel copyWith({
    int? totalCans,
    int? filledCans,
    int? emptyCans,
    int? damagedCans,
    int? customerBalanceCans,
    DateTime? lastUpdated,
  }) {
    return InventoryModel(
      totalCans: totalCans ?? this.totalCans,
      filledCans: filledCans ?? this.filledCans,
      emptyCans: emptyCans ?? this.emptyCans,
      damagedCans: damagedCans ?? this.damagedCans,
      customerBalanceCans: customerBalanceCans ?? this.customerBalanceCans,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }
}
