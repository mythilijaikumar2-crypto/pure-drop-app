import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/app_enums.dart';
import '../core/network/dio_client.dart';
import '../core/storage/hive_service.dart';
import '../models/customer_model.dart';
import '../models/employee_model.dart';
import '../models/expense_model.dart';
import '../models/inventory_model.dart';
import '../models/order_model.dart';
import '../models/payment_model.dart';
import '../models/salary_model.dart';
import '../models/user_model.dart';
import '../models/water_purchase_model.dart';
import '../repositories/app_repository.dart';

// --- CORE SERVICE PROVIDERS ---
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

final appRepositoryProvider = Provider<AppRepository>((ref) {
  return AppRepository(ref.watch(dioClientProvider));
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
  AuthNotifier() : super(AuthState()) {
    checkSavedSession();
  }

  void checkSavedSession() {
    try {
      final box = HiveService.getBox(AppConstants.authBoxName);
      final userJson = box.get('currentUser');
      final rememberMe = box.get('rememberMe', defaultValue: false);

      if (userJson != null && rememberMe == true) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(userJson);
        final user = UserModel.fromJson(map);
        state = AuthState(user: user, isAuthenticated: true);
      } else {
        state = AuthState(user: null, isAuthenticated: false);
      }
    } catch (e) {
      debugPrint('AuthNotifier session check exception: $e');
      state = AuthState(user: null, isAuthenticated: false);
    }
  }

  Future<bool> loginWithUsernamePassword({
    required String username,
    required String password,
    required bool rememberMe,
  }) async {
    state = AuthState(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 600)); // Smooth UX transition

    final cleanUsername = username.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanUsername.length < 4) {
      state = AuthState(
        isAuthenticated: false,
        errorMessage: 'Username must be at least 4 characters long.',
      );
      return false;
    }

    if (cleanPassword.length < 6) {
      state = AuthState(
        isAuthenticated: false,
        errorMessage: 'Password must be at least 6 characters long.',
      );
      return false;
    }

    UserModel? authenticatedUser;

    // Check Admin Credentials
    if ((cleanUsername == 'admin' || cleanUsername == 'puredrop') && cleanPassword == 'admin123') {
      authenticatedUser = UserModel(
        id: 'EMP-ADM-01',
        employeeId: 'ADM-001',
        name: 'Pure Drop Admin',
        username: 'admin',
        phone: '9876543210',
        role: UserRole.admin,
        status: 'Active',
      );
    }
    // Check Delivery Boy Credentials
    else if ((cleanUsername == 'driver' || cleanUsername == 'ramesh') && cleanPassword == 'driver123') {
      authenticatedUser = UserModel(
        id: 'EMP-DRV-01',
        employeeId: 'DRV-101',
        name: 'Ramesh Kumar',
        username: 'driver',
        phone: '9876001122',
        role: UserRole.deliveryBoy,
        status: 'Active',
      );
    }

    if (authenticatedUser != null) {
      await HiveService.saveData(AppConstants.authBoxName, 'currentUser', authenticatedUser.toJson());
      await HiveService.saveData(AppConstants.authBoxName, 'rememberMe', rememberMe);

      state = AuthState(
        user: authenticatedUser,
        isAuthenticated: true,
        isLoading: false,
      );
      return true;
    } else {
      state = AuthState(
        isAuthenticated: false,
        isLoading: false,
        errorMessage: 'Invalid Username or Password. Please try again.',
      );
      return false;
    }
  }

  void loginAsAdmin() {
    final admin = UserModel(
      id: 'EMP-ADM-01',
      employeeId: 'ADM-001',
      name: 'Pure Drop Admin',
      username: 'admin',
      phone: '9876543210',
      role: UserRole.admin,
      status: 'Active',
    );
    HiveService.saveData(AppConstants.authBoxName, 'currentUser', admin.toJson());
    HiveService.saveData(AppConstants.authBoxName, 'rememberMe', true);
    state = AuthState(user: admin, isAuthenticated: true);
  }

  void loginAsDeliveryBoy(String name, String phone) {
    final driver = UserModel(
      id: 'EMP-DRV-01',
      employeeId: 'DRV-101',
      name: name.isEmpty ? 'Ramesh Kumar' : name,
      username: 'driver',
      phone: phone.isEmpty ? '9876001122' : phone,
      role: UserRole.deliveryBoy,
      status: 'Active',
    );
    HiveService.saveData(AppConstants.authBoxName, 'currentUser', driver.toJson());
    HiveService.saveData(AppConstants.authBoxName, 'rememberMe', true);
    state = AuthState(user: driver, isAuthenticated: true);
  }

  void switchRole(UserRole role) {
    if (role == UserRole.admin) {
      loginAsAdmin();
    } else {
      loginAsDeliveryBoy('Ramesh Kumar', '9876001122');
    }
  }

  void logout() {
    HiveService.deleteData(AppConstants.authBoxName, 'currentUser');
    HiveService.deleteData(AppConstants.authBoxName, 'rememberMe');
    state = AuthState(user: null, isAuthenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// --- CUSTOMER PROVIDER ---
class CustomerNotifier extends StateNotifier<List<CustomerModel>> {
  final AppRepository _repo;

  CustomerNotifier(this._repo) : super([]) {
    refresh();
  }

  void refresh() {
    state = _repo.getCustomers();
  }

  Future<void> addOrUpdate(CustomerModel customer) async {
    await _repo.saveCustomer(customer);
    refresh();
  }

  Future<void> delete(String id) async {
    await _repo.deleteCustomer(id);
    refresh();
  }
}

final customerProvider = StateNotifierProvider<CustomerNotifier, List<CustomerModel>>((ref) {
  return CustomerNotifier(ref.watch(appRepositoryProvider));
});

// --- ORDER PROVIDER ---
class OrderNotifier extends StateNotifier<List<OrderModel>> {
  final AppRepository _repo;
  final Ref _ref;

  OrderNotifier(this._repo, this._ref) : super([]) {
    refresh();
  }

  void refresh() {
    state = _repo.getOrders();
  }

  Future<void> createOrder(OrderModel order) async {
    await _repo.createOrder(order);
    refresh();
    _ref.read(inventoryProvider.notifier).refresh();
    _ref.read(customerProvider.notifier).refresh();
  }

  Future<void> updateStatus(
    String orderId,
    OrderStatus status, {
    String? driverId,
    String? driverName,
    int emptyCansCollected = 0,
    int damagedCansReported = 0,
    PaymentStatus? paymentStatus,
    PaymentMode? paymentMode,
  }) async {
    await _repo.updateOrderStatus(
      orderId,
      status,
      driverId: driverId,
      driverName: driverName,
      emptyCansCollected: emptyCansCollected,
      damagedCansReported: damagedCansReported,
      paymentStatus: paymentStatus,
      paymentMode: paymentMode,
    );
    refresh();
    _ref.read(inventoryProvider.notifier).refresh();
    _ref.read(customerProvider.notifier).refresh();
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, List<OrderModel>>((ref) {
  return OrderNotifier(ref.watch(appRepositoryProvider), ref);
});

// --- INVENTORY PROVIDER ---
class InventoryNotifier extends StateNotifier<InventoryModel> {
  final AppRepository _repo;

  InventoryNotifier(this._repo) : super(InventoryModel.initial()) {
    refresh();
  }

  void refresh() {
    state = _repo.getInventory();
  }

  Future<void> update(InventoryModel inventory) async {
    await _repo.saveInventory(inventory);
    refresh();
  }
}

final inventoryProvider = StateNotifierProvider<InventoryNotifier, InventoryModel>((ref) {
  return InventoryNotifier(ref.watch(appRepositoryProvider));
});

// --- WATER PURCHASE PROVIDER ---
class WaterPurchaseNotifier extends StateNotifier<List<WaterPurchaseModel>> {
  final AppRepository _repo;
  final Ref _ref;

  WaterPurchaseNotifier(this._repo, this._ref) : super([]) {
    refresh();
  }

  void refresh() {
    state = _repo.getWaterPurchases();
  }

  Future<void> addPurchase(WaterPurchaseModel item) async {
    await _repo.addWaterPurchase(item);
    refresh();
    _ref.read(inventoryProvider.notifier).refresh();
    _ref.read(expenseProvider.notifier).refresh();
  }
}

final waterPurchaseProvider =
    StateNotifierProvider<WaterPurchaseNotifier, List<WaterPurchaseModel>>((ref) {
  return WaterPurchaseNotifier(ref.watch(appRepositoryProvider), ref);
});

// --- EMPLOYEES PROVIDER ---
class EmployeeNotifier extends StateNotifier<List<EmployeeModel>> {
  final AppRepository _repo;

  EmployeeNotifier(this._repo) : super([]) {
    refresh();
  }

  void refresh() {
    state = _repo.getEmployees();
  }

  Future<void> save(EmployeeModel employee) async {
    await _repo.saveEmployee(employee);
    refresh();
  }
}

final employeeProvider = StateNotifierProvider<EmployeeNotifier, List<EmployeeModel>>((ref) {
  return EmployeeNotifier(ref.watch(appRepositoryProvider));
});

// --- SALARY PROVIDER ---
class SalaryNotifier extends StateNotifier<List<SalaryModel>> {
  final AppRepository _repo;
  final Ref _ref;

  SalaryNotifier(this._repo, this._ref) : super([]) {
    refresh();
  }

  void refresh() {
    state = _repo.getSalaries();
  }

  Future<void> addSalary(SalaryModel item) async {
    await _repo.addSalary(item);
    refresh();
    _ref.read(expenseProvider.notifier).refresh();
  }
}

final salaryProvider = StateNotifierProvider<SalaryNotifier, List<SalaryModel>>((ref) {
  return SalaryNotifier(ref.watch(appRepositoryProvider), ref);
});

// --- EXPENSE PROVIDER ---
class ExpenseNotifier extends StateNotifier<List<ExpenseModel>> {
  final AppRepository _repo;

  ExpenseNotifier(this._repo) : super([]) {
    refresh();
  }

  void refresh() {
    state = _repo.getExpenses();
  }

  Future<void> addExpense(ExpenseModel expense) async {
    await _repo.addExpense(expense);
    refresh();
  }
}

final expenseProvider = StateNotifierProvider<ExpenseNotifier, List<ExpenseModel>>((ref) {
  return ExpenseNotifier(ref.watch(appRepositoryProvider));
});

// --- PAYMENT PROVIDER ---
class PaymentNotifier extends StateNotifier<List<PaymentModel>> {
  final AppRepository _repo;
  final Ref _ref;

  PaymentNotifier(this._repo, this._ref) : super([]) {
    refresh();
  }

  void refresh() {
    state = _repo.getPayments();
  }

  Future<void> recordPayment(PaymentModel payment) async {
    await _repo.recordPayment(payment);
    refresh();
    _ref.read(customerProvider.notifier).refresh();
  }
}

final paymentProvider = StateNotifierProvider<PaymentNotifier, List<PaymentModel>>((ref) {
  return PaymentNotifier(ref.watch(appRepositoryProvider), ref);
});

// --- DASHBOARD METRICS PROVIDER ---
class DashboardMetrics {
  final int todayOrdersCount;
  final double todayRevenue;
  final double totalExpenses;
  final double netProfit;
  final int filledCans;
  final int emptyCans;
  final int damagedCans;
  final int customerBalanceCans;
  final double pendingPaymentsTotal;
  final int completedDeliveriesCount;

  DashboardMetrics({
    required this.todayOrdersCount,
    required this.todayRevenue,
    required this.totalExpenses,
    required this.netProfit,
    required this.filledCans,
    required this.emptyCans,
    required this.damagedCans,
    required this.customerBalanceCans,
    required this.pendingPaymentsTotal,
    required this.completedDeliveriesCount,
  });
}

final dashboardMetricsProvider = Provider<DashboardMetrics>((ref) {
  final orders = ref.watch(orderProvider);
  final inventory = ref.watch(inventoryProvider);
  final expenses = ref.watch(expenseProvider);
  final customers = ref.watch(customerProvider);

  final today = DateTime.now();
  bool isToday(DateTime d) =>
      d.year == today.year && d.month == today.month && d.day == today.day;

  final todayOrders = orders.where((o) => isToday(o.createdAt)).toList();
  final completedDeliveries = orders.where((o) => o.status == OrderStatus.delivered).toList();

  final todayRevenue = completedDeliveries.fold<double>(
      0.0, (sum, item) => sum + item.totalAmount);

  final totalExpenses = expenses.fold<double>(
      0.0, (sum, item) => sum + item.amount);

  final pendingPaymentsTotal = customers.fold<double>(
      0.0, (sum, item) => sum + item.pendingDues);

  final netProfit = todayRevenue - totalExpenses;

  return DashboardMetrics(
    todayOrdersCount: todayOrders.length,
    todayRevenue: todayRevenue,
    totalExpenses: totalExpenses,
    netProfit: netProfit,
    filledCans: inventory.filledCans,
    emptyCans: inventory.emptyCans,
    damagedCans: inventory.damagedCans,
    customerBalanceCans: inventory.customerBalanceCans,
    pendingPaymentsTotal: pendingPaymentsTotal,
    completedDeliveriesCount: completedDeliveries.length,
  );
});
