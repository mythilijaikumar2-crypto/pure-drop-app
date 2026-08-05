import '../core/constants/app_enums.dart';

class EmployeeModel {
  final String id; // e.g. PDAEMP-001
  final String name;
  final String username;
  final String phone;
  final String address;
  final UserRole role;
  final String employeeType; // Delivery Staff
  final double baseSalary;
  final DateTime joiningDate;
  final bool isActive;

  EmployeeModel({
    required this.id,
    required this.name,
    this.username = '',
    required this.phone,
    this.address = '',
    required this.role,
    this.employeeType = 'Delivery Staff',
    required this.baseSalary,
    required this.joiningDate,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': id,
        'name': name,
        'username': username,
        'phone': phone,
        'address': address,
        'role': role.name,
        'employeeType': employeeType,
        'baseSalary': baseSalary,
        'joiningDate': joiningDate.toIso8601String(),
        'isActive': isActive,
        'status': isActive ? 'Active' : 'Inactive',
      };

  factory EmployeeModel.fromJson(Map<String, dynamic> json) => EmployeeModel(
        id: json['id'] ?? json['employeeId'] ?? '',
        name: json['name'] ?? '',
        username: json['username'] ?? '',
        phone: json['phone'] ?? '',
        address: json['address'] ?? '',
        role: UserRole.values.firstWhere(
          (e) => e.name == json['role'],
          orElse: () => UserRole.deliveryBoy,
        ),
        employeeType: json['employeeType'] ?? 'Delivery Staff',
        baseSalary: (json['baseSalary'] as num?)?.toDouble() ?? 15000.0,
        joiningDate: json['joiningDate'] != null
            ? DateTime.parse(json['joiningDate'])
            : DateTime.now(),
        isActive: json['isActive'] ?? (json['status'] == 'Active'),
      );

  EmployeeModel copyWith({
    String? id,
    String? name,
    String? username,
    String? phone,
    String? address,
    UserRole? role,
    String? employeeType,
    double? baseSalary,
    DateTime? joiningDate,
    bool? isActive,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      role: role ?? this.role,
      employeeType: employeeType ?? this.employeeType,
      baseSalary: baseSalary ?? this.baseSalary,
      joiningDate: joiningDate ?? this.joiningDate,
      isActive: isActive ?? this.isActive,
    );
  }
}
