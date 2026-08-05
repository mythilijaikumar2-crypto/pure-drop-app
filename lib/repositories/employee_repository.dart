import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/app_enums.dart';
import '../core/storage/hive_service.dart';
import '../core/utils/result.dart';
import '../models/employee_model.dart';
import 'base_repository.dart';

class EmployeeRepository extends BaseRepository {
  final Uuid _uuid = const Uuid();

  Future<Result<List<EmployeeModel>>> getEmployees({UserRole? role}) async {
    try {
      if (role != null && role != UserRole.admin) {
        return const Success([]); // Return empty list for unauthorized employee roles
      }
      final items = HiveService.getAll(AppConstants.employeeBoxName);
      final list = items.map((item) {
        return EmployeeModel.fromJson(jsonDecode(item as String));
      }).toList();
      return Success(list);
    } catch (e, stack) {
      return Failure('Failed to fetch employees: $e', e, stack);
    }
  }

  Future<Result<EmployeeModel>> saveEmployee(EmployeeModel employee, {UserRole? role}) async {
    try {
      if (role != null && role != UserRole.admin) {
        return const Failure('Unauthorized: Employee management requires Admin privilege.');
      }
      final box = HiveService.getBoxSafe(AppConstants.employeeBoxName);
      final id = employee.id.isEmpty ? 'EMP-${_uuid.v4().substring(0, 4).toUpperCase()}' : employee.id;
      final emp = employee.copyWith(id: id);

      if (box != null) await box.put(id, jsonEncode(emp.toJson()));
      await enqueueSync(
        collection: 'employees',
        docId: id,
        action: 'set',
        data: emp.toJson(),
      );

      return Success(emp);
    } catch (e, stack) {
      return Failure('Failed to save employee: $e', e, stack);
    }
  }

  Future<Result<bool>> deleteEmployee(String id, {UserRole? role}) async {
    try {
      if (role != null && role != UserRole.admin) {
        return const Failure('Unauthorized: Employee deletion requires Admin privilege.');
      }
      final box = HiveService.getBoxSafe(AppConstants.employeeBoxName);
      if (box != null) await box.delete(id);
      await enqueueSync(
        collection: 'employees',
        docId: id,
        action: 'delete',
        data: {},
      );
      return const Success(true);
    } catch (e, stack) {
      return Failure('Failed to delete employee: $e', e, stack);
    }
  }

  String generateNextEmployeeId() {
    try {
      final items = HiveService.getAll(AppConstants.employeeBoxName);
      int maxId = 0;

      for (final item in items) {
        try {
          final emp = EmployeeModel.fromJson(jsonDecode(item as String));
          final clean = emp.id.replaceAll(RegExp(r'[^0-9]'), '');
          if (clean.isNotEmpty) {
            final val = int.tryParse(clean) ?? 0;
            if (val > maxId) maxId = val;
          }
        } catch (_) {}
      }

      final nextNum = maxId > 0 ? maxId + 1 : items.length + 1;
      return 'PDAEMP-${nextNum.toString().padLeft(3, '0')}';
    } catch (_) {
      return 'PDAEMP-001';
    }
  }
}
