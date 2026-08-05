class DeliveryModel {
  final String deliveryId;
  final String orderId;
  final String customerId;
  final String customerName;
  final String phone;
  final String address;
  final String employeeId;
  final String employeeName;
  final String deliveryStatus; // pending, delivered, cancelled, rescheduled, customerNotAvailable, skipped
  final DateTime deliveryDate;
  final String deliveryTime;
  final DateTime? completedAt;
  final DateTime? rescheduledDate;
  final String reason;
  final String remarks;
  final String updatedBy;
  final DateTime updatedAt;
  final DateTime createdAt;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final int emptyCansCollected;
  final int damagedCansReported;
  final String paymentMode;

  DeliveryModel({
    required this.deliveryId,
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.phone,
    required this.address,
    this.employeeId = '',
    this.employeeName = '',
    this.deliveryStatus = 'pending',
    required this.deliveryDate,
    this.deliveryTime = '10:00 AM',
    this.completedAt,
    this.rescheduledDate,
    this.reason = '',
    this.remarks = '',
    this.updatedBy = '',
    DateTime? updatedAt,
    DateTime? createdAt,
    this.quantity = 1,
    this.unitPrice = 35.0,
    this.totalAmount = 35.0,
    this.emptyCansCollected = 0,
    this.damagedCansReported = 0,
    this.paymentMode = 'Cash',
  })  : updatedAt = updatedAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'deliveryId': deliveryId,
        'id': deliveryId,
        'orderId': orderId,
        'customerId': customerId,
        'customerName': customerName,
        'phone': phone,
        'address': address,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'deliveryStatus': deliveryStatus,
        'deliveryDate': deliveryDate.toIso8601String(),
        'deliveryTime': deliveryTime,
        'completedAt': completedAt?.toIso8601String(),
        'rescheduledDate': rescheduledDate?.toIso8601String(),
        'reason': reason,
        'remarks': remarks,
        'updatedBy': updatedBy,
        'updatedAt': updatedAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalAmount': totalAmount,
        'emptyCansCollected': emptyCansCollected,
        'damagedCansReported': damagedCansReported,
        'paymentMode': paymentMode,
      };

  factory DeliveryModel.fromJson(Map<String, dynamic> json) => DeliveryModel(
        deliveryId: json['deliveryId'] ?? json['id'] ?? '',
        orderId: json['orderId'] ?? '',
        customerId: json['customerId'] ?? json['CustomerID'] ?? '',
        customerName: json['customerName'] ?? json['CustomerName'] ?? '',
        phone: json['phone'] ?? json['Phone'] ?? '',
        address: json['address'] ?? json['Address'] ?? '',
        employeeId: json['employeeId'] ?? json['assignedDriverId'] ?? '',
        employeeName: json['employeeName'] ?? json['assignedDriverName'] ?? '',
        deliveryStatus: (json['deliveryStatus'] ?? json['status'] ?? 'pending').toString().toLowerCase(),
        deliveryDate: json['deliveryDate'] != null
            ? (DateTime.tryParse(json['deliveryDate'].toString()) ?? DateTime.now())
            : DateTime.now(),
        deliveryTime: json['deliveryTime'] ?? '10:00 AM',
        completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt'].toString()) : null,
        rescheduledDate: json['rescheduledDate'] != null ? DateTime.tryParse(json['rescheduledDate'].toString()) : null,
        reason: json['reason'] ?? '',
        remarks: json['remarks'] ?? json['notes'] ?? '',
        updatedBy: json['updatedBy'] ?? '',
        updatedAt: json['updatedAt'] != null
            ? (DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now())
            : DateTime.now(),
        createdAt: json['createdAt'] != null
            ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
            : DateTime.now(),
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 35.0,
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 35.0,
        emptyCansCollected: (json['emptyCansCollected'] as num?)?.toInt() ?? 0,
        damagedCansReported: (json['damagedCansReported'] as num?)?.toInt() ?? 0,
        paymentMode: json['paymentMode'] ?? 'Cash',
      );

  DeliveryModel copyWith({
    String? deliveryId,
    String? orderId,
    String? customerId,
    String? customerName,
    String? phone,
    String? address,
    String? employeeId,
    String? employeeName,
    String? deliveryStatus,
    DateTime? deliveryDate,
    String? deliveryTime,
    DateTime? completedAt,
    DateTime? rescheduledDate,
    String? reason,
    String? remarks,
    String? updatedBy,
    DateTime? updatedAt,
    DateTime? createdAt,
    int? quantity,
    double? unitPrice,
    double? totalAmount,
    int? emptyCansCollected,
    int? damagedCansReported,
    String? paymentMode,
  }) {
    return DeliveryModel(
      deliveryId: deliveryId ?? this.deliveryId,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      completedAt: completedAt ?? this.completedAt,
      rescheduledDate: rescheduledDate ?? this.rescheduledDate,
      reason: reason ?? this.reason,
      remarks: remarks ?? this.remarks,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      emptyCansCollected: emptyCansCollected ?? this.emptyCansCollected,
      damagedCansReported: damagedCansReported ?? this.damagedCansReported,
      paymentMode: paymentMode ?? this.paymentMode,
    );
  }
}
