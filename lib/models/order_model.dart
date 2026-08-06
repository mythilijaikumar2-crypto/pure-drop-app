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
  final bool isRecurring;
  final String recurringFrequency;
  final OrderPriority priority;
  final String proofType;
  final String otpCode;
  final String? deliveryProofUrl;
  final String? customerSignatureUrl;
  final String signatureProofPath;
  final DateTime updatedAt;

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
    DateTime? updatedAt,
    this.deliveredAt,
    this.emptyCansCollected = 0,
    this.damagedCansReported = 0,
    this.notes = '',
    this.isRecurring = false,
    this.recurringFrequency = 'Daily',
    this.priority = OrderPriority.normal,
    this.proofType = 'OTP',
    this.otpCode = '1234',
    this.deliveryProofUrl,
    this.customerSignatureUrl,
    this.signatureProofPath = '',
  }) : updatedAt = updatedAt ?? DateTime.now();

  bool get isPriority => priority == OrderPriority.high || priority == OrderPriority.urgent;

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
        'updatedAt': updatedAt.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
        'emptyCansCollected': emptyCansCollected,
        'damagedCansReported': damagedCansReported,
        'notes': notes,
        'isRecurring': isRecurring,
        'recurringFrequency': recurringFrequency,
        'priority': priority.name,
        'proofType': proofType,
        'otpCode': otpCode,
        'deliveryProofUrl': deliveryProofUrl,
        'customerSignatureUrl': customerSignatureUrl,
        'signatureProofPath': signatureProofPath,
      };

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] ?? json['DeliveryStatus'] ?? '').toString().toLowerCase();
    final paymentStatusStr = (json['paymentStatus'] ?? json['PaymentStatus'] ?? '').toString().toLowerCase();
    final paymentModeStr = (json['paymentMode'] ?? json['PaymentMode'] ?? '').toString().toLowerCase();

    OrderStatus parsedStatus = OrderStatus.pending;
    if (statusStr.contains('deliver')) {
      parsedStatus = OrderStatus.delivered;
    } else if (statusStr.contains('cancel')) {
      parsedStatus = OrderStatus.cancelled;
    } else if (statusStr.contains('transit') || statusStr.contains('out')) {
      parsedStatus = OrderStatus.inTransit;
    } else if (statusStr.contains('assign')) {
      parsedStatus = OrderStatus.assigned;
    }

    PaymentStatus parsedPaymentStatus = PaymentStatus.pending;
    if (paymentStatusStr.contains('paid')) {
      parsedPaymentStatus = PaymentStatus.paid;
    } else if (paymentStatusStr.contains('part')) {
      parsedPaymentStatus = PaymentStatus.partiallyPaid;
    }

    PaymentMode parsedPaymentMode = PaymentMode.cash;
    if (paymentModeStr.contains('upi')) {
      parsedPaymentMode = PaymentMode.upi;
    } else if (paymentModeStr.contains('bank') || paymentModeStr.contains('card')) {
      parsedPaymentMode = PaymentMode.bankTransfer;
    } else if (paymentModeStr.contains('credit')) {
      parsedPaymentMode = PaymentMode.credit;
    }

    return OrderModel(
      id: json['id'] ?? json['OrderID'] ?? '',
      customerId: json['customerId'] ?? json['CustomerID'] ?? '',
      customerName: json['customerName'] ?? json['CustomerName'] ?? '',
      phone: json['phone'] ?? json['Phone'] ?? '',
      address: json['address'] ?? json['Address'] ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? (json['FilledCans'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? (json['PricePerCan'] as num?)?.toDouble() ?? 35.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? (json['TotalAmount'] as num?)?.toDouble() ?? 35.0,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => parsedStatus,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == json['paymentStatus'],
        orElse: () => parsedPaymentStatus,
      ),
      paymentMode: PaymentMode.values.firstWhere(
        (e) => e.name == json['paymentMode'],
        orElse: () => parsedPaymentMode,
      ),
      assignedDriverId: json['assignedDriverId'],
      assignedDriverName: json['assignedDriverName'] ?? json['AssignedDriver'],
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : (json['OrderDate'] != null ? (DateTime.tryParse(json['OrderDate'].toString()) ?? DateTime.now()) : DateTime.now()),
      updatedAt: json['updatedAt'] != null
          ? (DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'].toString())
          : (json['DeliveryDate'] != null ? DateTime.tryParse(json['DeliveryDate'].toString()) : null),
      emptyCansCollected: (json['emptyCansCollected'] as num?)?.toInt() ?? (json['EmptyReturned'] as num?)?.toInt() ?? 0,
      damagedCansReported: (json['damagedCansReported'] as num?)?.toInt() ?? 0,
      notes: json['notes'] ?? json['Remarks'] ?? '',
      isRecurring: json['isRecurring'] ?? false,
      recurringFrequency: json['recurringFrequency'] ?? 'Daily',
      priority: OrderPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => (json['isPriority'] == true ? OrderPriority.high : OrderPriority.normal),
      ),
      proofType: json['proofType'] ?? 'OTP',
      otpCode: json['otpCode'] ?? '1234',
      deliveryProofUrl: json['deliveryProofUrl'],
      customerSignatureUrl: json['customerSignatureUrl'],
      signatureProofPath: json['signatureProofPath'] ?? '',
    );
  }

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
    DateTime? updatedAt,
    DateTime? deliveredAt,
    int? emptyCansCollected,
    int? damagedCansReported,
    String? notes,
    bool? isRecurring,
    String? recurringFrequency,
    OrderPriority? priority,
    String? proofType,
    String? otpCode,
    String? deliveryProofUrl,
    String? customerSignatureUrl,
    String? signatureProofPath,
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
      updatedAt: updatedAt ?? this.updatedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      emptyCansCollected: emptyCansCollected ?? this.emptyCansCollected,
      damagedCansReported: damagedCansReported ?? this.damagedCansReported,
      notes: notes ?? this.notes,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      priority: priority ?? this.priority,
      proofType: proofType ?? this.proofType,
      otpCode: otpCode ?? this.otpCode,
      deliveryProofUrl: deliveryProofUrl ?? this.deliveryProofUrl,
      customerSignatureUrl: customerSignatureUrl ?? this.customerSignatureUrl,
      signatureProofPath: signatureProofPath ?? this.signatureProofPath,
    );
  }
}
