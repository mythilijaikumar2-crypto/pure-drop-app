import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/app_enums.dart';
import '../core/exceptions/app_exception.dart';
import '../core/logger/app_logger.dart';
import '../core/storage/hive_service.dart';

import '../models/attendance_model.dart';
import '../models/customer_model.dart';
import '../models/delivery_model.dart';
import '../models/employee_model.dart';
import '../models/expense_model.dart';
import '../models/inventory_model.dart';
import '../models/order_model.dart';
import '../models/payment_model.dart';
import '../models/product_model.dart';
import '../models/salary_model.dart';
import '../models/settings_model.dart';
import '../models/timeline_model.dart';
import '../models/user_model.dart';
import '../models/water_purchase_model.dart';

import '../core/services/auth_service.dart';
import '../core/services/connectivity_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/storage_service.dart';
import '../core/services/sync_service.dart';

import '../core/services/automation/automation_engine.dart';
import '../core/services/automation/customer_automation.dart';
import '../core/services/automation/dashboard_automation.dart';
import '../core/services/automation/employee_automation.dart';
import '../core/services/automation/inventory_automation.dart';
import '../core/services/automation/notification_automation.dart';
import '../core/services/automation/order_automation.dart';
import '../core/services/automation/payment_automation.dart';
import '../core/services/automation/report_automation.dart';
import '../core/services/automation/timeline_automation.dart';

import '../repositories/app_repository.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/delivery_repository.dart';
import '../repositories/inventory_repository.dart';
import '../repositories/report_repository.dart';
import '../repositories/salary_repository.dart';
import '../repositories/water_purchase_repository.dart';

import '../repositories/interfaces/i_customer_repository.dart';
import '../repositories/interfaces/i_employee_repository.dart';
import '../repositories/interfaces/i_expense_repository.dart';
import '../repositories/interfaces/i_order_repository.dart';
import '../repositories/interfaces/i_payment_repository.dart';
import '../repositories/interfaces/i_product_repository.dart';
import '../repositories/interfaces/i_settings_repository.dart';
import '../repositories/interfaces/i_timeline_repository.dart';

import '../repositories/hive_impl/hive_customer_repository.dart';
import '../repositories/hive_impl/hive_employee_repository.dart';
import '../repositories/hive_impl/hive_expense_repository.dart';
import '../repositories/hive_impl/hive_order_repository.dart';
import '../repositories/hive_impl/hive_payment_repository.dart';
import '../repositories/hive_impl/hive_product_repository.dart';
import '../repositories/hive_impl/hive_settings_repository.dart';
import '../repositories/hive_impl/hive_timeline_repository.dart';

// --- CORE SERVICE PROVIDERS ---
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());
final syncServiceProvider = Provider<SyncService>((ref) => SyncService());
final connectivityServiceProvider = Provider<ConnectivityService>((ref) => ConnectivityService());

// --- ABSTRACT REPOSITORY PROVIDERS ---
final customerRepositoryProvider = Provider<ICustomerRepository>((ref) => HiveCustomerRepository());
final orderRepositoryProvider = Provider<IOrderRepository>((ref) => HiveOrderRepository());
final employeeRepositoryProvider = Provider<IEmployeeRepository>((ref) => HiveEmployeeRepository());
final productRepositoryProvider = Provider<IProductRepository>((ref) => HiveProductRepository());
final timelineRepositoryProvider = Provider<ITimelineRepository>((ref) => HiveTimelineRepository());
final expenseRepositoryProvider = Provider<IExpenseRepository>((ref) => HiveExpenseRepository());
final paymentRepositoryProvider = Provider<IPaymentRepository>((ref) => HivePaymentRepository());
final settingsRepositoryProvider = Provider<ISettingsRepository>((ref) => HiveSettingsRepository());

// Backward-compatibility AppRepository & legacy providers
final appRepositoryProvider = Provider<AppRepository>((ref) => AppRepository());
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) => DashboardRepository());
final reportRepositoryProvider = Provider<ReportRepository>((ref) => ReportRepository());
final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) => DeliveryRepository());
final waterPurchaseRepositoryProvider = Provider<WaterPurchaseRepository>((ref) => WaterPurchaseRepository());
final salaryRepositoryProvider = Provider<SalaryRepository>((ref) => SalaryRepository());
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) => AttendanceRepository());
final inventoryRepositoryProviderLegacy = Provider<InventoryRepository>((ref) => InventoryRepository());

// --- MODULAR AUTOMATION SUB-SERVICES PROVIDERS ---
final timelineAutomationProvider = Provider<TimelineAutomation>((ref) {
  return TimelineAutomation(ref.watch(timelineRepositoryProvider));
});

final inventoryAutomationProvider = Provider<InventoryAutomation>((ref) {
  return InventoryAutomation(ref.watch(timelineAutomationProvider));
});

final employeeAutomationProvider = Provider<EmployeeAutomation>((ref) {
  return EmployeeAutomation(
    ref.watch(employeeRepositoryProvider),
    ref.watch(orderRepositoryProvider),
    ref.watch(timelineAutomationProvider),
  );
});

final orderAutomationProvider = Provider<OrderAutomation>((ref) {
  return OrderAutomation(
    ref.watch(customerRepositoryProvider),
    ref.watch(orderRepositoryProvider),
    ref.watch(settingsRepositoryProvider),
    ref.watch(employeeAutomationProvider),
    ref.watch(timelineAutomationProvider),
  );
});

final customerAutomationProvider = Provider<CustomerAutomation>((ref) {
  return CustomerAutomation(
    ref.watch(customerRepositoryProvider),
    ref.watch(orderRepositoryProvider),
    ref.watch(employeeAutomationProvider),
    ref.watch(orderAutomationProvider),
    ref.watch(timelineAutomationProvider),
  );
});

final paymentAutomationProvider = Provider<PaymentAutomation>((ref) {
  return PaymentAutomation(
    ref.watch(paymentRepositoryProvider),
    ref.watch(customerRepositoryProvider),
    ref.watch(timelineAutomationProvider),
  );
});

final reportAutomationProvider = Provider<ReportAutomation>((ref) => ReportAutomation());
final notificationAutomationProvider = Provider<NotificationAutomation>((ref) => NotificationAutomation());

// --- MAIN BUSINESS AUTOMATION ENGINE PROVIDER ---
final automationEngineProvider = Provider<AutomationEngine>((ref) {
  return AutomationEngine(
    customerAutomation: ref.watch(customerAutomationProvider),
    orderAutomation: ref.watch(orderAutomationProvider),
    employeeAutomation: ref.watch(employeeAutomationProvider),
    paymentAutomation: ref.watch(paymentAutomationProvider),
    inventoryAutomation: ref.watch(inventoryAutomationProvider),
    timelineAutomation: ref.watch(timelineAutomationProvider),
    reportAutomation: ref.watch(reportAutomationProvider),
    notificationAutomation: ref.watch(notificationAutomationProvider),
    customerRepo: ref.watch(customerRepositoryProvider),
    orderRepo: ref.watch(orderRepositoryProvider),
    employeeRepo: ref.watch(employeeRepositoryProvider),
    expenseRepo: ref.watch(expenseRepositoryProvider),
    paymentRepo: ref.watch(paymentRepositoryProvider),
  );
});

// --- AUTH PROVIDER ---
class AuthState {
  final UserModel? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
  });
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();

  AuthNotifier() : super(AuthState(isLoading: true)) {
    _initSession();
  }

  Future<void> _initSession() async {
    try {
      final box = HiveService.getBox(AppConstants.authBoxName);
      final userJson = box.get('currentUser');

      if (userJson != null) {
        final userMap = Map<String, dynamic>.from(userJson as Map);
        final user = UserModel.fromJson(userMap);
        if (user.status == 'Active') {
          debugPrint('✅ LOCAL AUTH: Session restored from Hive cache for user ${user.id} (${user.role.name})');
          state = AuthState(user: user, isAuthenticated: true);
          return;
        }
      }
      state = AuthState(user: null, isAuthenticated: false);
    } catch (e) {
      debugPrint('❌ LOCAL AUTH: Session init error: $e');
      state = AuthState(user: null, isAuthenticated: false);
    }
  }

  Future<void> checkSavedSession() => _initSession();

  Future<bool> loginWithUsernameOrEmployeeId({
    required String identifier,
    required String password,
    required bool rememberMe,
  }) async {
    final cleanId = identifier.trim();
    final cleanPassword = password.trim();

    if (cleanId.isEmpty || cleanPassword.isEmpty) {
      state = AuthState(
        isAuthenticated: false,
        isLoading: false,
        errorMessage: 'Username/Employee ID and Password are required.',
      );
      return false;
    }

    state = AuthState(isLoading: true);

    try {
      final profileData = await _authService.signIn(cleanId, cleanPassword);
      final user = UserModel.fromJson(profileData);

      if (user.status != 'Active') {
        await _authService.signOut();
        state = AuthState(
          isAuthenticated: false,
          isLoading: false,
          errorMessage: 'Your account is INACTIVE. Please contact Administrator.',
        );
        return false;
      }

      final sessionUser = user.copyWith(loginTimestamp: DateTime.now());
      await _saveSession(sessionUser, rememberMe);
      return true;
    } on AuthException catch (e) {
      state = AuthState(
        isAuthenticated: false,
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = AuthState(
        isAuthenticated: false,
        isLoading: false,
        errorMessage: 'Authentication error. Please check credentials.',
      );
      return false;
    }
  }

  Future<void> _saveSession(UserModel user, bool rememberMe) async {
    await HiveService.saveData(AppConstants.authBoxName, 'currentUser', user.toJson());
    await HiveService.saveData(AppConstants.authBoxName, 'rememberMe', rememberMe);
    await HiveService.saveData(AppConstants.authBoxName, 'loginTimestamp', DateTime.now().toIso8601String());
    await HiveService.deleteData(AppConstants.authBoxName, 'savedPassword');

    state = AuthState(
      user: user,
      isAuthenticated: true,
      isLoading: false,
    );
  }

  Future<void> _clearHiveSession() async {
    await HiveService.deleteData(AppConstants.authBoxName, 'currentUser');
    await HiveService.deleteData(AppConstants.authBoxName, 'rememberMe');
    await HiveService.deleteData(AppConstants.authBoxName, 'loginTimestamp');
    await HiveService.deleteData(AppConstants.authBoxName, 'savedPassword');
  }

  void logout() {
    _authService.signOut();
    _clearHiveSession();
    state = AuthState(user: null, isAuthenticated: false);
  }

  void switchRole(UserRole role) {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(
        role: role,
        employeeType: role == UserRole.admin ? 'Admin' : 'Delivery Staff',
      );
      HiveService.saveData(AppConstants.authBoxName, 'currentUser', updatedUser.toJson());
      state = AuthState(user: updatedUser, isAuthenticated: true);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

void refreshAllErpModules(Ref ref) {
  try {
    ref.read(customerProvider.notifier).refresh();
    ref.read(orderProvider.notifier).refresh();
    ref.read(deliveryProvider.notifier).refresh();
    ref.read(inventoryProvider.notifier).refresh();
    ref.read(employeeProvider.notifier).refresh();
    ref.read(paymentProvider.notifier).refresh();
    ref.read(expenseProvider.notifier).refresh();
    ref.read(timelineProvider.notifier).refresh();
  } catch (e) {
    AppLogger.error('Failed to refresh ERP modules', e, null, 'ERP_SYNC');
  }
}

// --- CUSTOMER PROVIDER (AUTOMATION INTEGRATED) ---
class CustomerNotifier extends StateNotifier<List<CustomerModel>> {
  final ICustomerRepository _repo;
  final AutomationEngine _engine;
  final Ref _ref;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  CustomerNotifier(this._repo, this._engine, this._ref) : super([]) {
    refresh();
  }

  Future<void> refresh() async {
    state = await _repo.getCustomers();
  }

  Future<bool> addOrUpdate(CustomerModel customer) async {
    _isLoading = true;
    _errorMessage = null;
    try {
      bool success;
      if (customer.id.isEmpty) {
        success = await _engine.handleCustomerCreation(customer);
      } else {
        success = await _engine.handleCustomerEdit(customer);
      }
      if (success) {
        await refresh();
        refreshAllErpModules(_ref);
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<bool> pauseCustomer(String customerId) async {
    final success = await _engine.handleCustomerPause(customerId);
    if (success) {
      await refresh();
      refreshAllErpModules(_ref);
    }
    return success;
  }

  Future<bool> resumeCustomer(String customerId) async {
    final success = await _engine.handleCustomerResume(customerId);
    if (success) {
      await refresh();
      refreshAllErpModules(_ref);
    }
    return success;
  }

  Future<bool> cancelCustomer(String customerId) async {
    final success = await _engine.handleCustomerCancel(customerId);
    if (success) {
      await refresh();
      refreshAllErpModules(_ref);
    }
    return success;
  }

  Future<bool> delete(String id) async {
    _isLoading = true;
    _errorMessage = null;
    try {
      final success = await _repo.deleteCustomer(id);
      if (success) {
        await refresh();
        refreshAllErpModules(_ref);
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
    }
  }
}

final customerProvider = StateNotifierProvider<CustomerNotifier, List<CustomerModel>>((ref) {
  return CustomerNotifier(
    ref.watch(customerRepositoryProvider),
    ref.watch(automationEngineProvider),
    ref,
  );
});

// --- ORDER PROVIDER (AUTOMATION INTEGRATED) ---
class OrderNotifier extends StateNotifier<List<OrderModel>> {
  final IOrderRepository _repo;
  final AutomationEngine _engine;
  final Ref _ref;

  OrderNotifier(this._repo, this._engine, this._ref) : super([]) {
    refresh();
  }

  Future<void> refresh() async {
    state = await _repo.getOrders();
  }

  Future<bool> createOrder(OrderModel order) async {
    try {
      final success = await _repo.createOrder(order);
      if (success) {
        await refresh();
        refreshAllErpModules(_ref);
      }
      return success;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> markDelivered({
    required String orderId,
    required int emptyCansCollected,
    required int damagedCansReported,
    required PaymentMode paymentMode,
    required bool isPaid,
  }) async {
    final success = await _engine.handleDeliveryCompleted(
      orderId: orderId,
      emptyCansCollected: emptyCansCollected,
      damagedCansReported: damagedCansReported,
      paymentMode: paymentMode,
      isPaid: isPaid,
    );
    if (success) {
      await refresh();
      refreshAllErpModules(_ref);
    }
    return success;
  }

  Future<bool> assignDelivery({
    required String orderId,
    required String driverId,
    required String driverName,
  }) async {
    try {
      final success = await _repo.updateOrderStatus(
        orderId,
        OrderStatus.assigned,
        driverId: driverId,
        driverName: driverName,
      );
      if (success) {
        await refresh();
        refreshAllErpModules(_ref);
      }
      return success;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateStatus(
    String orderId,
    OrderStatus status, {
    String? driverId,
    String? driverName,
    int emptyCansCollected = 0,
    int damagedCansReported = 0,
    PaymentStatus? paymentStatus,
    PaymentMode? paymentMode,
  }) async {
    if (status == OrderStatus.delivered) {
      return markDelivered(
        orderId: orderId,
        emptyCansCollected: emptyCansCollected,
        damagedCansReported: damagedCansReported,
        paymentMode: paymentMode ?? PaymentMode.cash,
        isPaid: paymentStatus == PaymentStatus.paid,
      );
    }
    final success = await _repo.updateOrderStatus(
      orderId,
      status,
      driverId: driverId,
      driverName: driverName,
      emptyCansCollected: emptyCansCollected,
      damagedCansReported: damagedCansReported,
      paymentStatus: paymentStatus,
      paymentMode: paymentMode,
    );
    if (success) {
      await refresh();
      refreshAllErpModules(_ref);
    }
    return success;
  }

  Future<bool> deleteOrder(String id) async {
    try {
      final success = await _repo.deleteOrder(id);
      if (success) {
        await refresh();
        refreshAllErpModules(_ref);
      }
      return success;
    } catch (e) {
      rethrow;
    }
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, List<OrderModel>>((ref) {
  return OrderNotifier(
    ref.watch(orderRepositoryProvider),
    ref.watch(automationEngineProvider),
    ref,
  );
});

final ordersStreamProvider = StreamProvider<List<OrderModel>>((ref) {
  final orders = ref.watch(orderProvider);
  return Stream.value(orders);
});

// --- DELIVERY MANAGEMENT PROVIDER ---
class DeliveryNotifier extends StateNotifier<List<DeliveryModel>> {
  final AppRepository _repo;
  final Ref _ref;

  DeliveryNotifier(this._repo, this._ref) : super([]) {
    refresh();
  }

  void refresh() {
    state = _repo.getDeliveries();
  }

  Future<bool> executeAction({
    required DeliveryModel delivery,
    required String newStatus,
    required String reason,
    required String remarks,
    required String updatedBy,
    required String updatedRole,
    DateTime? rescheduledDate,
    int emptyCansCollected = 0,
    int damagedCansReported = 0,
    String paymentMode = 'Cash',
  }) async {
    final success = await _repo.executeDeliveryStatusAction(
      delivery: delivery,
      newStatus: newStatus,
      reason: reason,
      remarks: remarks,
      updatedBy: updatedBy,
      updatedRole: updatedRole,
      rescheduledDate: rescheduledDate,
      emptyCansCollected: emptyCansCollected,
      damagedCansReported: damagedCansReported,
      paymentMode: paymentMode,
    );

    if (success) {
      refresh();
      refreshAllErpModules(_ref);
    }
    return success;
  }

  Future<bool> undoLastAction(String deliveryId) async {
    final success = await _repo.undoLastDeliveryAction(deliveryId);
    if (success) {
      refresh();
      refreshAllErpModules(_ref);
    }
    return success;
  }

  Future<bool> shiftSlot(String deliveryId, String newSlot) async {
    final success = await _repo.shiftDeliverySlot(deliveryId, newSlot);
    if (success) {
      refresh();
      refreshAllErpModules(_ref);
    }
    return success;
  }

  Future<bool> changeQuantity(String deliveryId, int newQuantity) async {
    final success = await _repo.changeDeliveryQuantity(deliveryId, newQuantity);
    if (success) {
      refresh();
      refreshAllErpModules(_ref);
    }
    return success;
  }

  Future<bool> collectPayment({
    required String deliveryId,
    required double amount,
    required String paymentMode,
  }) async {
    final success = await _repo.collectPayment(
      deliveryId: deliveryId,
      amount: amount,
      paymentMode: paymentMode,
    );
    if (success) {
      refresh();
      refreshAllErpModules(_ref);
    }
    return success;
  }
}

final deliveryProvider = StateNotifierProvider<DeliveryNotifier, List<DeliveryModel>>((ref) {
  return DeliveryNotifier(ref.watch(appRepositoryProvider), ref);
});

// --- EMPLOYEES PROVIDER ---
class EmployeeNotifier extends StateNotifier<List<EmployeeModel>> {
  final IEmployeeRepository _repo;
  final AutomationEngine _engine;
  final Ref _ref;

  EmployeeNotifier(this._repo, this._engine, this._ref) : super([]) {
    refresh();
  }

  Future<void> refresh() async {
    state = await _repo.getEmployees();
  }

  Future<bool> save(EmployeeModel employee) async {
    try {
      bool success;
      if (employee.id.isEmpty) {
        success = await _engine.handleEmployeeCreation(employee);
      } else {
        success = await _repo.saveEmployee(employee);
      }
      if (success) {
        await refresh();
        refreshAllErpModules(_ref);
      }
      return success;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateArea(String employeeId, String newArea) async {
    final success = await _engine.handleEmployeeAreaChange(employeeId, newArea);
    if (success) {
      await refresh();
      refreshAllErpModules(_ref);
    }
    return success;
  }

  Future<bool> delete(String id) async {
    try {
      final success = await _repo.deleteEmployee(id);
      if (success) {
        await refresh();
        refreshAllErpModules(_ref);
      }
      return success;
    } catch (e) {
      rethrow;
    }
  }
}

final employeeProvider = StateNotifierProvider<EmployeeNotifier, List<EmployeeModel>>((ref) {
  return EmployeeNotifier(
    ref.watch(employeeRepositoryProvider),
    ref.watch(automationEngineProvider),
    ref,
  );
});

// --- PRODUCT PROVIDER ---
class ProductNotifier extends StateNotifier<List<ProductModel>> {
  final IProductRepository _repo;

  ProductNotifier(this._repo) : super([]) {
    refresh();
  }

  Future<void> refresh() async {
    state = await _repo.getProducts();
  }

  Future<bool> saveProduct(ProductModel product) async {
    final success = await _repo.saveProduct(product);
    if (success) await refresh();
    return success;
  }

  Future<bool> deleteProduct(String id) async {
    final success = await _repo.deleteProduct(id);
    if (success) await refresh();
    return success;
  }
}

final productProvider = StateNotifierProvider<ProductNotifier, List<ProductModel>>((ref) {
  return ProductNotifier(ref.watch(productRepositoryProvider));
});

// --- TIMELINE PROVIDER ---
class TimelineNotifier extends StateNotifier<List<TimelineModel>> {
  final ITimelineRepository _repo;

  TimelineNotifier(this._repo) : super([]) {
    refresh();
  }

  Future<void> refresh({String? category}) async {
    state = await _repo.getTimelineEvents(category: category);
  }
}

final timelineProvider = StateNotifierProvider<TimelineNotifier, List<TimelineModel>>((ref) {
  return TimelineNotifier(ref.watch(timelineRepositoryProvider));
});

// --- INVENTORY PROVIDER ---
class InventoryNotifier extends StateNotifier<InventoryModel> {
  final InventoryAutomation _automation;

  InventoryNotifier(this._automation) : super(_automation.getInventory());

  void refresh() {
    state = _automation.getInventory();
  }

  Future<bool> update(InventoryModel inventory) async {
    final success = await _automation.saveInventory(inventory);
    if (success) refresh();
    return success;
  }
}

final inventoryProvider = StateNotifierProvider<InventoryNotifier, InventoryModel>((ref) {
  return InventoryNotifier(ref.watch(inventoryAutomationProvider));
});

// --- EXPENSE PROVIDER ---
class ExpenseNotifier extends StateNotifier<List<ExpenseModel>> {
  final IExpenseRepository _repo;
  final AutomationEngine _engine;
  final Ref _ref;

  ExpenseNotifier(this._repo, this._engine, this._ref) : super([]) {
    refresh();
  }

  Future<void> refresh() async {
    state = await _repo.getExpenses();
  }

  Future<bool> addExpense(ExpenseModel expense) async {
    final success = await _engine.handleExpenseAdded(expense);
    if (success) {
      await refresh();
      refreshAllErpModules(_ref);
    }
    return success;
  }
}

final expenseProvider = StateNotifierProvider<ExpenseNotifier, List<ExpenseModel>>((ref) {
  return ExpenseNotifier(
    ref.watch(expenseRepositoryProvider),
    ref.watch(automationEngineProvider),
    ref,
  );
});

// --- PAYMENT PROVIDER ---
class PaymentNotifier extends StateNotifier<List<PaymentModel>> {
  final IPaymentRepository _repo;
  final AutomationEngine _engine;
  final Ref _ref;

  PaymentNotifier(this._repo, this._engine, this._ref) : super([]) {
    refresh();
  }

  Future<void> refresh() async {
    state = await _repo.getPayments();
  }

  Future<bool> recordPayment(
    dynamic paymentOrCustomerId, {
    String? customerName,
    double? amount,
    PaymentMode? paymentMode,
    String referenceNumber = '',
  }) async {
    bool success = false;
    if (paymentOrCustomerId is PaymentModel) {
      success = await _engine.handlePaymentCollected(
        customerId: paymentOrCustomerId.customerId,
        customerName: paymentOrCustomerId.customerName,
        amount: paymentOrCustomerId.amount,
        paymentMode: paymentOrCustomerId.paymentMode,
        referenceNumber: paymentOrCustomerId.referenceNo,
      );
    } else if (paymentOrCustomerId is String && customerName != null && amount != null && paymentMode != null) {
      success = await _engine.handlePaymentCollected(
        customerId: paymentOrCustomerId,
        customerName: customerName,
        amount: amount,
        paymentMode: paymentMode,
        referenceNumber: referenceNumber,
      );
    }

    if (success) {
      await refresh();
      refreshAllErpModules(_ref);
    }
    return success;
  }
}

final paymentProvider = StateNotifierProvider<PaymentNotifier, List<PaymentModel>>((ref) {
  return PaymentNotifier(
    ref.watch(paymentRepositoryProvider),
    ref.watch(automationEngineProvider),
    ref,
  );
});

// --- WATER PURCHASE & SALARY PROVIDERS ---
final waterPurchaseProvider = StateNotifierProvider<WaterPurchaseNotifier, List<WaterPurchaseModel>>((ref) {
  return WaterPurchaseNotifier(ref.watch(appRepositoryProvider), ref);
});

class WaterPurchaseNotifier extends StateNotifier<List<WaterPurchaseModel>> {
  final AppRepository _repo;
  final Ref _ref;

  WaterPurchaseNotifier(this._repo, this._ref) : super([]) {
    refresh();
  }

  void refresh() {
    state = _repo.getWaterPurchases();
  }

  Future<bool> addPurchase(WaterPurchaseModel item) async {
    final success = await _repo.addWaterPurchase(item);
    if (success) {
      refresh();
      refreshAllErpModules(_ref);
    }
    return success;
  }
}

final salaryProvider = StateNotifierProvider<SalaryNotifier, List<SalaryModel>>((ref) {
  return SalaryNotifier(ref.watch(appRepositoryProvider), ref);
});

class SalaryNotifier extends StateNotifier<List<SalaryModel>> {
  final AppRepository _repo;
  final Ref _ref;

  SalaryNotifier(this._repo, this._ref) : super([]) {
    refresh();
  }

  void refresh() {
    state = _repo.getSalaries();
  }

  Future<bool> addSalary(SalaryModel item) async {
    final success = await _repo.addSalary(item);
    if (success) {
      refresh();
      _ref.read(expenseProvider.notifier).refresh();
    }
    return success;
  }
}

final attendanceProvider = StateNotifierProvider<AttendanceNotifier, List<AttendanceModel>>((ref) {
  return AttendanceNotifier(ref.watch(attendanceRepositoryProvider));
});

class AttendanceNotifier extends StateNotifier<List<AttendanceModel>> {
  final AttendanceRepository _repo;

  AttendanceNotifier(this._repo) : super([]) {
    refresh();
  }

  Future<void> refresh() async {
    final result = await _repo.getAttendance();
    if (result.isSuccess) {
      state = result.dataOrNull ?? [];
    }
  }
}

// --- SETTINGS PROVIDER ---
class SettingsNotifier extends StateNotifier<SettingsModel> {
  final ISettingsRepository _repo;

  SettingsNotifier(this._repo) : super(SettingsModel()) {
    _load();
  }

  Future<void> _load() async {
    state = await _repo.getSettings();
  }

  Future<bool> updateSettings(SettingsModel newSettings) async {
    final success = await _repo.saveSettings(newSettings);
    if (success) state = newSettings;
    return success;
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsModel>((ref) {
  return SettingsNotifier(ref.watch(settingsRepositoryProvider));
});

// --- GRANULAR ISOLATED DASHBOARD METRICS PROVIDERS ---
final customerMetricsProvider = Provider<CustomerMetrics>((ref) {
  final customers = ref.watch(customerProvider);
  return CustomerMetrics.fromList(customers);
});

final orderMetricsProvider = Provider<OrderMetrics>((ref) {
  final orders = ref.watch(orderProvider);
  return OrderMetrics.fromList(orders);
});

final expenseMetricsProvider = Provider<ExpenseMetrics>((ref) {
  final expenses = ref.watch(expenseProvider);
  return ExpenseMetrics.fromList(expenses);
});

final employeeMetricsProvider = Provider<EmployeeMetrics>((ref) {
  final employees = ref.watch(employeeProvider);
  return EmployeeMetrics.fromList(employees);
});

final revenueMetricsProvider = Provider<RevenueMetrics>((ref) {
  final orders = ref.watch(orderProvider);
  final payments = ref.watch(paymentProvider);
  final customers = ref.watch(customerProvider);
  final expenseMetrics = ref.watch(expenseMetricsProvider);

  return RevenueMetrics.calculate(
    orders: orders,
    payments: payments,
    customers: customers,
    totalExpenses: expenseMetrics.totalExpenses,
  );
});

// Backward-compatible legacy dashboard metrics
final dashboardMetricsProvider = Provider<DashboardMetrics>((ref) {
  final orderMetrics = ref.watch(orderMetricsProvider);
  final revenueMetrics = ref.watch(revenueMetricsProvider);
  final expenseMetrics = ref.watch(expenseMetricsProvider);
  final inventory = ref.watch(inventoryProvider);

  final orders = ref.watch(orderProvider);
  final expenses = ref.watch(expenseProvider);
  final today = DateTime.now();

  bool isSameDay(DateTime d1, DateTime d2) =>
      d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  final List<DailyTrendPoint> dailyTrends = List.generate(7, (index) {
    final date = today.subtract(Duration(days: 6 - index));
    final label = DateFormat('E').format(date);

    final dayRevenue = orders
        .where((o) => (o.status == OrderStatus.delivered || o.status == OrderStatus.pending) && isSameDay(o.createdAt, date))
        .fold<double>(0.0, (acc, o) => acc + o.totalAmount);

    final dayExpense = expenses
        .where((e) => isSameDay(e.date, date))
        .fold<double>(0.0, (acc, e) => acc + e.amount);

    return DailyTrendPoint(
      dayLabel: label,
      revenue: dayRevenue,
      expense: dayExpense,
    );
  });

  return DashboardMetrics(
    todayOrdersCount: orderMetrics.todayOrdersCount,
    todayRevenue: revenueMetrics.todayRevenue,
    totalIncome: revenueMetrics.totalIncome,
    totalExpenses: expenseMetrics.totalExpenses,
    netProfit: revenueMetrics.netProfit,
    filledCans: inventory.filledCans,
    emptyCans: inventory.emptyCans,
    damagedCans: inventory.damagedCans,
    customerBalanceCans: inventory.customerBalanceCans,
    pendingPaymentsTotal: revenueMetrics.totalPendingDues,
    completedDeliveriesCount: orderMetrics.totalDeliveredCount,
    dailyTrends: dailyTrends,
  );
});

class DailyTrendPoint {
  final String dayLabel;
  final double revenue;
  final double expense;

  DailyTrendPoint({
    required this.dayLabel,
    required this.revenue,
    required this.expense,
  });
}

class DashboardMetrics {
  final int todayOrdersCount;
  final double todayRevenue;
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final int filledCans;
  final int emptyCans;
  final int damagedCans;
  final int customerBalanceCans;
  final double pendingPaymentsTotal;
  final int completedDeliveriesCount;
  final List<DailyTrendPoint> dailyTrends;

  DashboardMetrics({
    required this.todayOrdersCount,
    required this.todayRevenue,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
    required this.filledCans,
    required this.emptyCans,
    required this.damagedCans,
    required this.customerBalanceCans,
    required this.pendingPaymentsTotal,
    required this.completedDeliveriesCount,
    required this.dailyTrends,
  });
}
