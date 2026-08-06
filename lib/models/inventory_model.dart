class InventoryModel {
  final int totalCans;
  final int filledCans;
  final int emptyCans;
  final int damagedCans;
  final int lostCans;
  final int customerBalanceCans;
  final int reorderThreshold;
  final DateTime lastUpdated;

  InventoryModel({
    required this.totalCans,
    required this.filledCans,
    required this.emptyCans,
    required this.damagedCans,
    this.lostCans = 0,
    required this.customerBalanceCans,
    this.reorderThreshold = 50,
    required this.lastUpdated,
  });

  factory InventoryModel.initial() => InventoryModel(
        totalCans: 1000,
        filledCans: 650,
        emptyCans: 200,
        damagedCans: 15,
        lostCans: 5,
        customerBalanceCans: 130,
        reorderThreshold: 50,
        lastUpdated: DateTime.now(),
      );

  bool get isLowStock => filledCans <= reorderThreshold;

  Map<String, dynamic> toJson() => {
        'totalCans': totalCans,
        'filledCans': filledCans,
        'emptyCans': emptyCans,
        'damagedCans': damagedCans,
        'lostCans': lostCans,
        'customerBalanceCans': customerBalanceCans,
        'reorderThreshold': reorderThreshold,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory InventoryModel.fromJson(Map<String, dynamic> json) => InventoryModel(
        totalCans: (json['totalCans'] as num?)?.toInt() ?? 1000,
        filledCans: (json['filledCans'] as num?)?.toInt() ?? 650,
        emptyCans: (json['emptyCans'] as num?)?.toInt() ?? 200,
        damagedCans: (json['damagedCans'] as num?)?.toInt() ?? 15,
        lostCans: (json['lostCans'] as num?)?.toInt() ?? 5,
        customerBalanceCans: (json['customerBalanceCans'] as num?)?.toInt() ?? 130,
        reorderThreshold: (json['reorderThreshold'] as num?)?.toInt() ?? 50,
        lastUpdated: json['lastUpdated'] != null
            ? (DateTime.tryParse(json['lastUpdated']) ?? DateTime.now())
            : DateTime.now(),
      );

  InventoryModel copyWith({
    int? totalCans,
    int? filledCans,
    int? emptyCans,
    int? damagedCans,
    int? lostCans,
    int? customerBalanceCans,
    int? reorderThreshold,
    DateTime? lastUpdated,
  }) {
    return InventoryModel(
      totalCans: totalCans ?? this.totalCans,
      filledCans: filledCans ?? this.filledCans,
      emptyCans: emptyCans ?? this.emptyCans,
      damagedCans: damagedCans ?? this.damagedCans,
      lostCans: lostCans ?? this.lostCans,
      customerBalanceCans: customerBalanceCans ?? this.customerBalanceCans,
      reorderThreshold: reorderThreshold ?? this.reorderThreshold,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }
}
