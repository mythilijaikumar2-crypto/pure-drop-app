import '../core/constants/app_enums.dart';

class UserModel {
  final String id;
  final String employeeId;
  final String name;
  final String username;
  final String phone;
  final UserRole role;
  final String status;

  UserModel({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.username,
    required this.phone,
    required this.role,
    this.status = 'Active',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'name': name,
        'username': username,
        'phone': phone,
        'role': role.name,
        'status': status,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? '',
        employeeId: json['employeeId'] ?? json['id'] ?? '',
        name: json['name'] ?? '',
        username: json['username'] ?? '',
        phone: json['phone'] ?? '',
        role: UserRole.values.firstWhere(
          (e) => e.name == json['role'],
          orElse: () => UserRole.admin,
        ),
        status: json['status'] ?? 'Active',
      );
}
