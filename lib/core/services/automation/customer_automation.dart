import '../../../models/customer_model.dart';
import '../../../models/order_model.dart';
import '../../../repositories/interfaces/i_customer_repository.dart';
import '../../../repositories/interfaces/i_order_repository.dart';
import '../../../core/constants/app_enums.dart';
import 'employee_automation.dart';
import 'order_automation.dart';
import 'timeline_automation.dart';

class CustomerAutomation {
  final ICustomerRepository _customerRepo;
  final IOrderRepository _orderRepo;
  final EmployeeAutomation _employeeAutomation;
  final OrderAutomation _orderAutomation;
  final TimelineAutomation _timelineAutomation;

  CustomerAutomation(
    this._customerRepo,
    this._orderRepo,
    this._employeeAutomation,
    this._orderAutomation,
    this._timelineAutomation,
  );

  Future<bool> createCustomer(CustomerModel customer) async {
    // 1. Duplicate Mobile Check Guard
    final existing = await _customerRepo.getCustomers();
    final isDuplicate = existing.any((c) => c.phone.trim() == customer.phone.trim() && customer.phone.isNotEmpty);
    if (isDuplicate) {
      throw Exception('A customer with mobile number "${customer.phone}" already exists!');
    }

    // 2. Auto-assign employee based on Area Match & Workload Capacity
    final bestDriver = await _employeeAutomation.getBestEmployeeForArea(customer.area);
    final nextDelivery = DateTime.now();

    final preparedCustomer = customer.copyWith(
      assignedEmployeeId: bestDriver?.id,
      assignedEmployeeName: bestDriver?.name,
      nextDeliveryDate: nextDelivery,
      status: CustomerStatus.active,
      isActive: true,
      createdAt: DateTime.now(),
    );

    // 3. Save Customer Profile to Hive
    final saved = await _customerRepo.saveCustomer(preparedCustomer);
    if (!saved) return false;

    // 4. Log Timeline Audit Entries
    await _timelineAutomation.logEvent(
      title: 'Customer Profile Created',
      description: 'Customer ${preparedCustomer.name} registered (Zone: ${preparedCustomer.area})',
      category: 'Customer',
      recordId: preparedCustomer.id,
    );

    if (bestDriver != null) {
      await _timelineAutomation.logEvent(
        title: 'Delivery Boy Assigned',
        description: 'Assigned ${bestDriver.name} to ${preparedCustomer.name} based on area (${preparedCustomer.area})',
        category: 'Employee',
        recordId: preparedCustomer.id,
      );
    }

    // 5. Generate Initial Scheduled Order
    await _orderAutomation.generateOrderForCustomer(
      customer: preparedCustomer,
      targetDate: nextDelivery,
    );

    return true;
  }

  Future<bool> updateCustomer(CustomerModel customer) async {
    final old = await _customerRepo.getCustomerById(customer.id);
    final saved = await _customerRepo.saveCustomer(customer);
    if (!saved) return false;

    // If area changed, update employee assignment & pending orders
    if (old != null && old.area.toLowerCase() != customer.area.toLowerCase()) {
      final newDriver = await _employeeAutomation.getBestEmployeeForArea(customer.area);
      if (newDriver != null) {
        final updatedWithDriver = customer.copyWith(
          assignedEmployeeId: newDriver.id,
          assignedEmployeeName: newDriver.name,
        );
        await _customerRepo.saveCustomer(updatedWithDriver);
      }
    }

    await _timelineAutomation.logEvent(
      title: 'Customer Profile Updated',
      description: 'Updated details for ${customer.name}',
      category: 'Customer',
      recordId: customer.id,
    );

    return true;
  }

  Future<bool> pauseCustomer(String customerId) async {
    final customer = await _customerRepo.getCustomerById(customerId);
    if (customer == null) return false;

    final updated = customer.copyWith(
      status: CustomerStatus.inactive,
      isActive: false,
    );
    await _customerRepo.saveCustomer(updated);

    // Suppress pending future orders
    final orders = await _orderRepo.getOrdersByCustomer(customerId);
    final pending = orders.where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.assigned).toList();
    for (final o in pending) {
      await _orderRepo.updateOrderStatus(o.id, OrderStatus.cancelled);
    }

    await _timelineAutomation.logEvent(
      title: 'Customer Subscription Paused',
      description: 'Paused delivery subscription for ${customer.name}. Pending orders cancelled.',
      category: 'Customer',
      recordId: customerId,
    );

    return true;
  }

  Future<bool> resumeCustomer(String customerId) async {
    final customer = await _customerRepo.getCustomerById(customerId);
    if (customer == null) return false;

    final bestDriver = await _employeeAutomation.getBestEmployeeForArea(customer.area);
    final nextDelivery = DateTime.now();

    final updated = customer.copyWith(
      status: CustomerStatus.active,
      isActive: true,
      nextDeliveryDate: nextDelivery,
      assignedEmployeeId: bestDriver?.id ?? customer.assignedEmployeeId,
      assignedEmployeeName: bestDriver?.name ?? customer.assignedEmployeeName,
    );

    await _customerRepo.saveCustomer(updated);

    // Generate upcoming order
    await _orderAutomation.generateOrderForCustomer(
      customer: updated,
      targetDate: nextDelivery,
    );

    await _timelineAutomation.logEvent(
      title: 'Customer Subscription Resumed',
      description: 'Resumed delivery schedule for ${customer.name}',
      category: 'Customer',
      recordId: customerId,
    );

    return true;
  }

  Future<bool> cancelCustomer(String customerId) async {
    final customer = await _customerRepo.getCustomerById(customerId);
    if (customer == null) return false;

    final updated = customer.copyWith(
      status: CustomerStatus.blocked,
      isActive: false,
      assignedEmployeeId: '',
      assignedEmployeeName: '',
    );
    await _customerRepo.saveCustomer(updated);

    // Cancel all unfulfilled orders
    final orders = await _orderRepo.getOrdersByCustomer(customerId);
    final pending = orders.where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.assigned).toList();
    for (final o in pending) {
      await _orderRepo.updateOrderStatus(o.id, OrderStatus.cancelled);
    }

    await _timelineAutomation.logEvent(
      title: 'Customer Cancelled & Account Closed',
      description: 'Cancelled customer account for ${customer.name}',
      category: 'Customer',
      recordId: customerId,
    );

    return true;
  }

  Future<bool> setVacationMode({
    required String customerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final customer = await _customerRepo.getCustomerById(customerId);
    if (customer == null) return false;

    final updated = customer.copyWith(
      vacationStartDate: startDate,
      vacationEndDate: endDate,
    );
    await _customerRepo.saveCustomer(updated);

    await _timelineAutomation.logEvent(
      title: 'Customer Vacation Configured',
      description: '${customer.name} vacation set: ${startDate.day}/${startDate.month} to ${endDate.day}/${endDate.month}',
      category: 'Customer',
      recordId: customerId,
    );

    return true;
  }
}
