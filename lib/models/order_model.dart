import '../core/constants/app_enums.dart';

class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final String phone;
  final String address;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final PaymentMode paymentMode;
  final String? assignedDriverId;
  final String? assignedDriverName;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final int emptyCansCollected;
  final int damagedCansReported;
  final String notes;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    this.status = OrderStatus.pending,
    this.paymentStatus = PaymentStatus.pending,
    this.paymentMode = PaymentMode.cash,
    this.assignedDriverId,
    this.assignedDriverName,
    required this.createdAt,
    this.deliveredAt,
    this.emptyCansCollected = 0,
    this.damagedCansReported = 0,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'customerName': customerName,
        'phone': phone,
        'address': address,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalAmount': totalAmount,
        'status': status.name,
        'paymentStatus': paymentStatus.name,
        'paymentMode': paymentMode.name,
        'assignedDriverId': assignedDriverId,
        'assignedDriverName': assignedDriverName,
        'createdAt': createdAt.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
        'emptyCansCollected': emptyCansCollected,
        'damagedCansReported': damagedCansReported,
        'notes': notes,
      };

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] ?? '',
        customerId: json['customerId'] ?? '',
        customerName: json['customerName'] ?? '',
        phone: json['phone'] ?? '',
        address: json['address'] ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 35.0,
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 35.0,
        status: OrderStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => OrderStatus.pending,
        ),
        paymentStatus: PaymentStatus.values.firstWhere(
          (e) => e.name == json['paymentStatus'],
          orElse: () => PaymentStatus.pending,
        ),
        paymentMode: PaymentMode.values.firstWhere(
          (e) => e.name == json['paymentMode'],
          orElse: () => PaymentMode.cash,
        ),
        assignedDriverId: json['assignedDriverId'],
        assignedDriverName: json['assignedDriverName'],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        deliveredAt: json['deliveredAt'] != null
            ? DateTime.parse(json['deliveredAt'])
            : null,
        emptyCansCollected: (json['emptyCansCollected'] as num?)?.toInt() ?? 0,
        damagedCansReported: (json['damagedCansReported'] as num?)?.toInt() ?? 0,
        notes: json['notes'] ?? '',
      );

  OrderModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? phone,
    String? address,
    int? quantity,
    double? unitPrice,
    double? totalAmount,
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    PaymentMode? paymentMode,
    String? assignedDriverId,
    String? assignedDriverName,
    DateTime? createdAt,
    DateTime? deliveredAt,
    int? emptyCansCollected,
    int? damagedCansReported,
    String? notes,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMode: paymentMode ?? this.paymentMode,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      createdAt: createdAt ?? this.createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      emptyCansCollected: emptyCansCollected ?? this.emptyCansCollected,
      damagedCansReported: damagedCansReported ?? this.damagedCansReported,
      notes: notes ?? this.notes,
    );
  }
}
