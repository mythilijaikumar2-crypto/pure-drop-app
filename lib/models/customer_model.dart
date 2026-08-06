import '../core/constants/app_enums.dart';

class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String whatsappNumber;
  final String address;
  final double canPrice;
  final int canBalance; // Active water cans held by customer
  final int emptyCansPending; // Empty cans customer owes back
  final double pendingDues;
  final double securityDeposit; // Default ₹160 stored inside customer profile
  final double latitude;
  final double longitude;
  final CustomerStatus status;
  final bool isActive;
  final String notes;
  final DateTime? createdAt;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.whatsappNumber = '',
    required this.address,
    this.canPrice = 35.0,
    this.canBalance = 0,
    this.emptyCansPending = 0,
    this.pendingDues = 0.0,
    this.securityDeposit = 160.0,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.status = CustomerStatus.active,
    this.isActive = true,
    this.notes = '',
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'whatsappNumber': whatsappNumber,
        'address': address,
        'canPrice': canPrice,
        'canBalance': canBalance,
        'emptyCansPending': emptyCansPending,
        'pendingDues': pendingDues,
        'securityDeposit': securityDeposit,
        'latitude': latitude,
        'longitude': longitude,
        'status': status.name,
        'isActive': isActive,
        'notes': notes,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
        id: json['id'] ?? json['CustomerID'] ?? '',
        name: json['name'] ?? json['CustomerName'] ?? '',
        phone: json['phone'] ?? json['MobileNumber'] ?? '',
        whatsappNumber: json['whatsappNumber'] ?? json['AlternativeNumber'] ?? json['whatsapp'] ?? '',
        address: json['address'] ?? json['Address'] ?? '',
        canPrice: (json['canPrice'] as num?)?.toDouble() ?? 35.0,
        canBalance: (json['canBalance'] as num?)?.toInt() ?? (json['FilledCanBalance'] as num?)?.toInt() ?? 0,
        emptyCansPending: (json['emptyCansPending'] as num?)?.toInt() ?? (json['EmptyCanPending'] as num?)?.toInt() ?? (json['EmptyCanBalance'] as num?)?.toInt() ?? 0,
        pendingDues: (json['pendingDues'] as num?)?.toDouble() ?? (json['PendingAmount'] as num?)?.toDouble() ?? 0.0,
        securityDeposit: (json['securityDeposit'] as num?)?.toDouble() ?? 160.0,
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
        status: CustomerStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => CustomerStatus.active,
        ),
        isActive: json['isActive'] ?? true,
        notes: json['notes'] ?? '',
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      );

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? whatsappNumber,
    String? address,
    double? canPrice,
    int? canBalance,
    int? emptyCansPending,
    double? pendingDues,
    double? securityDeposit,
    double? latitude,
    double? longitude,
    CustomerStatus? status,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      address: address ?? this.address,
      canPrice: canPrice ?? this.canPrice,
      canBalance: canBalance ?? this.canBalance,
      emptyCansPending: emptyCansPending ?? this.emptyCansPending,
      pendingDues: pendingDues ?? this.pendingDues,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
