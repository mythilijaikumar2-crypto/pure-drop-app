class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String whatsappNumber;
  final String address;
  final double canPrice;
  final int canBalance; // Cans currently held by customer
  final double pendingDues;
  final double latitude;
  final double longitude;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.whatsappNumber = '',
    required this.address,
    this.canPrice = 35.0,
    this.canBalance = 0,
    this.pendingDues = 0.0,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'whatsappNumber': whatsappNumber,
        'alternativeNumber': whatsappNumber,
        'address': address,
        'canPrice': canPrice,
        'canBalance': canBalance,
        'pendingDues': pendingDues,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
        id: json['id'] ?? json['CustomerID'] ?? '',
        name: json['name'] ?? json['CustomerName'] ?? '',
        phone: json['phone'] ?? json['MobileNumber'] ?? '',
        whatsappNumber: json['whatsappNumber'] ?? json['AlternativeNumber'] ?? json['whatsapp'] ?? '',
        address: json['address'] ?? json['Address'] ?? '',
        canPrice: (json['canPrice'] as num?)?.toDouble() ?? 35.0,
        canBalance: (json['canBalance'] as num?)?.toInt() ?? (json['FilledCanBalance'] as num?)?.toInt() ?? 0,
        pendingDues: (json['pendingDues'] as num?)?.toDouble() ?? (json['PendingAmount'] as num?)?.toDouble() ?? 0.0,
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      );

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? whatsappNumber,
    String? address,
    double? canPrice,
    int? canBalance,
    double? pendingDues,
    double? latitude,
    double? longitude,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      address: address ?? this.address,
      canPrice: canPrice ?? this.canPrice,
      canBalance: canBalance ?? this.canBalance,
      pendingDues: pendingDues ?? this.pendingDues,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
