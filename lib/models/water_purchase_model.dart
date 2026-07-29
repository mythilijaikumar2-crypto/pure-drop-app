import '../core/constants/app_enums.dart';

class WaterPurchaseModel {
  final String id;
  final String plantName;
  final int cansPurchased;
  final double costPerCan;
  final double totalCost;
  final PaymentStatus paymentStatus;
  final DateTime date;
  final String notes;

  WaterPurchaseModel({
    required this.id,
    required this.plantName,
    required this.cansPurchased,
    required this.costPerCan,
    required this.totalCost,
    this.paymentStatus = PaymentStatus.paid,
    required this.date,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'plantName': plantName,
        'cansPurchased': cansPurchased,
        'costPerCan': costPerCan,
        'totalCost': totalCost,
        'paymentStatus': paymentStatus.name,
        'date': date.toIso8601String(),
        'notes': notes,
      };

  factory WaterPurchaseModel.fromJson(Map<String, dynamic> json) =>
      WaterPurchaseModel(
        id: json['id'] ?? '',
        plantName: json['plantName'] ?? '',
        cansPurchased: (json['cansPurchased'] as num?)?.toInt() ?? 0,
        costPerCan: (json['costPerCan'] as num?)?.toDouble() ?? 15.0,
        totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0.0,
        paymentStatus: PaymentStatus.values.firstWhere(
          (e) => e.name == json['paymentStatus'],
          orElse: () => PaymentStatus.paid,
        ),
        date: json['date'] != null
            ? DateTime.parse(json['date'])
            : DateTime.now(),
        notes: json['notes'] ?? '',
      );
}
