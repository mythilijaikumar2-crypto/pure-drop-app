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
        totalCans: 0,
        filledCans: 0,
        emptyCans: 0,
        damagedCans: 0,
        customerBalanceCans: 0,
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
        totalCans: (json['totalCans'] as num?)?.toInt() ?? 0,
        filledCans: (json['filledCans'] as num?)?.toInt() ?? 0,
        emptyCans: (json['emptyCans'] as num?)?.toInt() ?? 0,
        damagedCans: (json['damagedCans'] as num?)?.toInt() ?? 0,
        customerBalanceCans: (json['customerBalanceCans'] as num?)?.toInt() ?? 0,
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
