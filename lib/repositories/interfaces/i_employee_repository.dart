import '../../models/employee_model.dart';

abstract class IEmployeeRepository {
  Future<List<EmployeeModel>> getEmployees();
  Future<EmployeeModel?> getEmployeeById(String id);
  Future<List<EmployeeModel>> getEmployeesByArea(String area);
  Future<bool> saveEmployee(EmployeeModel employee);
  Future<bool> deleteEmployee(String id);
  Future<String> generateNextEmployeeId();
}
