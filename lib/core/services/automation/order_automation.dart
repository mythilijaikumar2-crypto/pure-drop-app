import '../../../models/customer_model.dart';
import '../../../models/order_model.dart';
import '../../../repositories/interfaces/i_customer_repository.dart';
import '../../../repositories/interfaces/i_order_repository.dart';
import '../../../repositories/interfaces/i_settings_repository.dart';
import '../../../core/constants/app_enums.dart';
import 'employee_automation.dart';
import 'timeline_automation.dart';

class OrderAutomation {
  final ICustomerRepository _customerRepo;
  final IOrderRepository _orderRepo;
  final ISettingsRepository _settingsRepo;
  final EmployeeAutomation _employeeAutomation;
  final TimelineAutomation _timelineAutomation;

  OrderAutomation(
    this._customerRepo,
    this._orderRepo,
    this._settingsRepo,
    this._employeeAutomation,
    this._timelineAutomation,
  );

  bool isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Future<bool> shouldGenerateOrderForCustomer({
    required CustomerModel customer,
    required DateTime targetDate,
  }) async {
    // 1. Status Guard: Must be Active
    if (!customer.isActive || customer.status != CustomerStatus.active) {
      return false;
    }

    // 2. Vacation Guard
    if (customer.isVacationActive) {
      return false;
    }
    if (customer.vacationStartDate != null && customer.vacationEndDate != null) {
      if (targetDate.isAfter(customer.vacationStartDate!.subtract(const Duration(days: 1))) &&
          targetDate.isBefore(customer.vacationEndDate!.add(const Duration(days: 1)))) {
        return false;
      }
    }

    // 3. Company Holiday Guard
    final settings = await _settingsRepo.getSettings();
    final isHoliday = settings.deliveryOffDays.any((d) => isSameDay(d, targetDate));
    if (isHoliday) {
      return false;
    }

    // 4. Frequency & Schedule Match
    final freq = customer.subscriptionFrequency.toLowerCase();
    bool scheduleMatches = false;

    if (freq.contains('daily')) {
      scheduleMatches = true;
    } else if (freq.contains('alternate')) {
      final start = customer.createdAt ?? targetDate;
      final diff = targetDate.difference(DateTime(start.year, start.month, start.day)).inDays;
      scheduleMatches = diff % 2 == 0;
    } else if (freq.contains('weekly')) {
      // Default weekly on Monday or match weekday
      scheduleMatches = targetDate.weekday == 1;
    } else if (freq.contains('monthly')) {
      scheduleMatches = targetDate.day == 1;
    } else {
      scheduleMatches = true;
    }

    if (!scheduleMatches) return false;

    // 5. Duplicate Order Protection Guard
    final existingOrders = await _orderRepo.getOrdersByCustomer(customer.id);
    final hasDuplicateForDate = existingOrders.any((o) => isSameDay(o.createdAt, targetDate));

    return !hasDuplicateForDate;
  }

  Future<OrderModel?> generateOrderForCustomer({
    required CustomerModel customer,
    DateTime? targetDate,
  }) async {
    final date = targetDate ?? DateTime.now();
    final canGenerate = await shouldGenerateOrderForCustomer(
      customer: customer,
      targetDate: date,
    );

    if (!canGenerate) return null;

    // Auto-assign best employee based on area, status, and workload capacity
    final driver = await _employeeAutomation.getBestEmployeeForArea(customer.area);

    final quantity = customer.quantityPerDelivery > 0 ? customer.quantityPerDelivery : 1;
    final unitPrice = customer.canPrice > 0 ? customer.canPrice : 35.0;
    final totalAmount = quantity * unitPrice;

    final order = OrderModel(
      id: '',
      customerId: customer.id,
      customerName: customer.name,
      phone: customer.phone,
      address: customer.address,
      quantity: quantity,
      unitPrice: unitPrice,
      totalAmount: totalAmount,
      status: driver != null ? OrderStatus.assigned : OrderStatus.pending,
      paymentStatus: PaymentStatus.pending,
      assignedDriverId: driver?.id,
      assignedDriverName: driver?.name,
      createdAt: date,
      isRecurring: true,
      recurringFrequency: customer.subscriptionFrequency,
    );

    final success = await _orderRepo.createOrder(order);
    if (!success) return null;

    // Calculate next delivery date for customer
    DateTime nextDate = date.add(const Duration(days: 1));
    if (customer.subscriptionFrequency.toLowerCase().contains('alternate')) {
      nextDate = date.add(const Duration(days: 2));
    } else if (customer.subscriptionFrequency.toLowerCase().contains('weekly')) {
      nextDate = date.add(const Duration(days: 7));
    } else if (customer.subscriptionFrequency.toLowerCase().contains('monthly')) {
      nextDate = DateTime(date.year, date.month + 1, date.day);
    }

    final updatedCust = customer.copyWith(
      nextDeliveryDate: nextDate,
      assignedEmployeeId: driver?.id ?? customer.assignedEmployeeId,
      assignedEmployeeName: driver?.name ?? customer.assignedEmployeeName,
    );
    await _customerRepo.saveCustomer(updatedCust);

    return order;
  }

  Future<int> checkAndGenerateDailyOrders({DateTime? forDate}) async {
    final date = forDate ?? DateTime.now();
    final customers = await _customerRepo.getCustomers();
    int generatedCount = 0;

    for (final customer in customers) {
      final created = await generateOrderForCustomer(
        customer: customer,
        targetDate: date,
      );
      if (created != null) {
        generatedCount++;
      }
    }

    if (generatedCount > 0) {
      await _timelineAutomation.logEvent(
        title: 'Daily Scheduled Orders Generated',
        description: 'Auto-generated $generatedCount delivery orders for ${date.day}/${date.month}/${date.year}',
        category: 'Order',
        metadata: {'count': generatedCount, 'date': date.toIso8601String()},
      );
    }

    return generatedCount;
  }
}
