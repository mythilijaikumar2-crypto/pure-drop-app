import '../core/constants/app_enums.dart';

class PaymentModel {
  final String id;
  final String customerId;
  final String customerName;
  final double amount;
  final PaymentMode paymentMode;
  final String referenceNo;
  final DateTime date;
  final String notes;

  PaymentModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.paymentMode,
    this.referenceNo = '',
    required this.date,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'customerName': customerName,
        'amount': amount,
        'paymentMode': paymentMode.name,
        'referenceNo': referenceNo,
        'date': date.toIso8601String(),
        'notes': notes,
      };

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        id: json['id'] ?? '',
        customerId: json['customerId'] ?? '',
        customerName: json['customerName'] ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        paymentMode: PaymentMode.values.firstWhere(
          (e) => e.name == json['paymentMode'],
          orElse: () => PaymentMode.cash,
        ),
        referenceNo: json['referenceNo'] ?? '',
        date: json['date'] != null
            ? DateTime.parse(json['date'])
            : DateTime.now(),
        notes: json['notes'] ?? '',
      );

  PaymentModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    double? amount,
    PaymentMode? paymentMode,
    String? referenceNo,
    DateTime? date,
    String? notes,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      amount: amount ?? this.amount,
      paymentMode: paymentMode ?? this.paymentMode,
      referenceNo: referenceNo ?? this.referenceNo,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }
}
