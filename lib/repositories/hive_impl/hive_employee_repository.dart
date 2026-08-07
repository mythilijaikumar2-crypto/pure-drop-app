import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/storage/hive_service.dart';
import '../../models/employee_model.dart';
import '../interfaces/i_employee_repository.dart';

class HiveEmployeeRepository implements IEmployeeRepository {
  final Uuid _uuid = const Uuid();

  @override
  Future<List<EmployeeModel>> getEmployees() async {
    try {
      final items = HiveService.getAll(AppConstants.employeeBoxName);
      return items.map((item) {
        final Map<String, dynamic> json = jsonDecode(item as String);
        return EmployeeModel.fromJson(json);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<EmployeeModel?> getEmployeeById(String id) async {
    try {
      final box = HiveService.getBox(AppConstants.employeeBoxName);
      final raw = box.get(id);
      if (raw == null) return null;
      return EmployeeModel.fromJson(jsonDecode(raw as String));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<EmployeeModel>> getEmployeesByArea(String area) async {
    final all = await getEmployees();
    return all.where((e) => e.assignedArea.toLowerCase() == area.toLowerCase()).toList();
  }

  @override
  Future<bool> saveEmployee(EmployeeModel employee) async {
    final box = HiveService.getBox(AppConstants.employeeBoxName);
    final id = employee.id.isEmpty
        ? 'EMP-${_uuid.v4().substring(0, 5).toUpperCase()}'
        : employee.id;
    final updated = employee.copyWith(id: id);

    try {
      await box.put(id, jsonEncode(updated.toJson()));
      return true;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> deleteEmployee(String id) async {
    final box = HiveService.getBox(AppConstants.employeeBoxName);
    try {
      await box.delete(id);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> generateNextEmployeeId() async {
    final box = HiveService.getBox(AppConstants.employeeBoxName);
    final count = box.length + 1;
    return 'EMP-${count.toString().padLeft(4, '0')}';
  }
}
