import '../core/constants/app_enums.dart';

class EmployeeModel {
  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final double baseSalary;
  final DateTime joiningDate;
  final bool isActive;

  EmployeeModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.baseSalary,
    required this.joiningDate,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'role': role.name,
        'baseSalary': baseSalary,
        'joiningDate': joiningDate.toIso8601String(),
        'isActive': isActive,
      };

  factory EmployeeModel.fromJson(Map<String, dynamic> json) => EmployeeModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        role: UserRole.values.firstWhere(
          (e) => e.name == json['role'],
          orElse: () => UserRole.deliveryBoy,
        ),
        baseSalary: (json['baseSalary'] as num?)?.toDouble() ?? 15000.0,
        joiningDate: json['joiningDate'] != null
            ? DateTime.parse(json['joiningDate'])
            : DateTime.now(),
        isActive: json['isActive'] ?? true,
      );
}
