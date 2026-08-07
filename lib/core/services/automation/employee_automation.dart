import '../../../models/employee_model.dart';
import '../../../repositories/interfaces/i_employee_repository.dart';
import '../../../repositories/interfaces/i_order_repository.dart';
import '../../../core/constants/app_enums.dart';
import 'timeline_automation.dart';

class EmployeeAutomation {
  final IEmployeeRepository _employeeRepo;
  final IOrderRepository _orderRepo;
  final TimelineAutomation _timelineAutomation;

  EmployeeAutomation(
    this._employeeRepo,
    this._orderRepo,
    this._timelineAutomation,
  );

  Future<EmployeeModel?> getBestEmployeeForArea(String area) async {
    final employees = await _employeeRepo.getEmployeesByArea(area);
    final available = employees.where((e) => e.isAvailableForAssignment).toList();

    if (available.isEmpty) {
      // Fallback: check any active delivery boy if area employee is full/absent
      final allEmployees = await _employeeRepo.getEmployees();
      final fallbacks = allEmployees.where((e) => e.role == UserRole.deliveryBoy && e.isAvailableForAssignment).toList();
      if (fallbacks.isNotEmpty) {
        fallbacks.sort((a, b) => a.activeOrderCount.compareTo(b.activeOrderCount));
        return fallbacks.first;
      }
      return null;
    }

    // Sort by lowest active workload
    available.sort((a, b) => a.activeOrderCount.compareTo(b.activeOrderCount));
    return available.first;
  }

  Future<bool> createEmployee(EmployeeModel employee) async {
    final existing = await _employeeRepo.getEmployees();
    final isDuplicate = existing.any((e) => e.phone == employee.phone && employee.phone.isNotEmpty);
    if (isDuplicate) {
      throw Exception('An employee with mobile number ${employee.phone} already exists!');
    }

    final success = await _employeeRepo.saveEmployee(employee);
    if (success) {
      await _timelineAutomation.logEvent(
        title: 'Employee Created',
        description: 'New employee: ${employee.name} (Area: ${employee.assignedArea})',
        category: 'Employee',
        recordId: employee.id,
      );
    }
    return success;
  }

  Future<bool> updateEmployeeArea(String employeeId, String newArea) async {
    final employee = await _employeeRepo.getEmployeeById(employeeId);
    if (employee == null) return false;

    final oldArea = employee.assignedArea;
    final updated = employee.copyWith(assignedArea: newArea);
    await _employeeRepo.saveEmployee(updated);

    // Auto-reassign pending orders in the new area to this employee
    final orders = await _orderRepo.getOrders();
    final pendingInArea = orders.where((o) =>
        (o.status == OrderStatus.pending || o.status == OrderStatus.assigned) &&
        o.address.toLowerCase().contains(newArea.toLowerCase())).toList();

    int count = 0;
    for (final order in pendingInArea) {
      if (count >= updated.maxDailyCapacity) break;
      await _orderRepo.updateOrderStatus(
        order.id,
        OrderStatus.assigned,
        driverId: employee.id,
        driverName: employee.name,
      );
      count++;
    }

    await _timelineAutomation.logEvent(
      title: 'Employee Area Changed',
      description: '${employee.name} area updated: $oldArea -> $newArea ($count orders reassigned)',
      category: 'Employee',
      recordId: employeeId,
    );

    return true;
  }

  Future<void> handleEmployeeLeaveOrDeactivation(String employeeId) async {
    final employee = await _employeeRepo.getEmployeeById(employeeId);
    if (employee == null) return;

    // Find all pending orders assigned to this employee
    final orders = await _orderRepo.getOrdersByDriver(employeeId);
    final pending = orders.where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.assigned).toList();

    for (final order in pending) {
      // Find replacement employee
      final replacement = await getBestEmployeeForArea(employee.assignedArea);
      if (replacement != null) {
        await _orderRepo.updateOrderStatus(
          order.id,
          OrderStatus.assigned,
          driverId: replacement.id,
          driverName: replacement.name,
        );
      } else {
        await _orderRepo.updateOrderStatus(
          order.id,
          OrderStatus.pending,
          driverId: '',
          driverName: '',
        );
      }
    }

    await _timelineAutomation.logEvent(
      title: 'Employee Leave Route Reassigned',
      description: 'Pending orders for ${employee.name} reassigned due to leave/inactivity',
      category: 'Employee',
      recordId: employeeId,
    );
  }
}
