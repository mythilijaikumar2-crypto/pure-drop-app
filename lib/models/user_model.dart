import '../core/constants/app_enums.dart';

class UserModel {
  final String id; // Firebase Auth UID
  final String employeeId; // e.g. PDAEMP-001 or PDAEMP-000
  final String name;
  final String username;
  final String firebaseEmail; // Synthetic email used in Firebase Auth
  final UserRole role;
  final String employeeType; // Delivery Staff / Admin
  final String phone;
  final String address;
  final String status; // Active / Inactive
  final bool firstLogin;
  final DateTime? loginTimestamp; // Last successful login time
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.username,
    String? firebaseEmail,
    required this.role,
    this.employeeType = 'Delivery Staff',
    this.phone = '',
    this.address = '',
    this.status = 'Active',
    this.firstLogin = false,
    this.loginTimestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : firebaseEmail = firebaseEmail ?? '${username.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\-]'), '')}@puredropaqua.com',
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'uid': id,
        'employeeId': employeeId,
        'name': name,
        'username': username,
        'firebaseEmail': firebaseEmail,
        'role': role.name,
        'employeeType': employeeType,
        'phone': phone,
        'address': address,
        'status': status,
        'firstLogin': firstLogin,
        'loginTimestamp': loginTimestamp?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    UserRole parsedRole = UserRole.admin;
    final rStr = (json['role'] ?? '').toString().toLowerCase();
    if (rStr == 'deliveryboy' || rStr == 'employee' || rStr == 'driver') {
      parsedRole = UserRole.deliveryBoy;
    } else if (rStr == 'officestaff' || rStr == 'office') {
      parsedRole = UserRole.officeStaff;
    }

    final uid = json['uid'] ?? json['id'] ?? json['employeeId'] ?? '';
    final username = json['username'] ?? '';

    return UserModel(
      id: uid,
      employeeId: json['employeeId'] ?? json['id'] ?? '',
      name: json['name'] ?? json['EmployeeName'] ?? '',
      username: username,
      firebaseEmail: json['firebaseEmail'] ??
          '${username.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\-]'), '')}@puredropaqua.com',
      role: parsedRole,
      employeeType: json['employeeType'] ?? 'Delivery Staff',
      phone: json['phone'] ?? json['Phone'] ?? '',
      address: json['address'] ?? json['Address'] ?? '',
      status: json['status'] ?? 'Active',
      firstLogin: json['firstLogin'] ?? false,
      loginTimestamp: json['loginTimestamp'] != null
          ? DateTime.tryParse(json['loginTimestamp'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  UserModel copyWith({
    String? id,
    String? employeeId,
    String? name,
    String? username,
    String? firebaseEmail,
    UserRole? role,
    String? employeeType,
    String? phone,
    String? address,
    String? status,
    bool? firstLogin,
    DateTime? loginTimestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      name: name ?? this.name,
      username: username ?? this.username,
      firebaseEmail: firebaseEmail ?? this.firebaseEmail,
      role: role ?? this.role,
      employeeType: employeeType ?? this.employeeType,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      status: status ?? this.status,
      firstLogin: firstLogin ?? this.firstLogin,
      loginTimestamp: loginTimestamp ?? this.loginTimestamp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
