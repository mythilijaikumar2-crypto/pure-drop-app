import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
      await HiveService.saveData(AppConstants.authBoxName, 'savedUsername', cleanUsername);
      await HiveService.saveData(AppConstants.authBoxName, 'savedPassword', cleanPassword);

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
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  CustomerNotifier(this._repo) : super([]) {
    state = _repo.getCustomers();
    fetchLive();
  }

  Future<void> fetchLive() async {
    _isLoading = true;
    _errorMessage = null;
    try {
      final liveList = await _repo.fetchCustomers();
      state = liveList;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
    }
  }

  void refresh() {
    state = _repo.getCustomers();
    fetchLive();
  }

  Future<bool> addOrUpdate(CustomerModel customer) async {
    _isLoading = true;
    _errorMessage = null;
    try {
      final success = await _repo.saveCustomer(customer);
      if (success) {
        await fetchLive();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<bool> delete(String id) async {
    _isLoading = true;
    _errorMessage = null;
    try {
      final success = await _repo.deleteCustomer(id);
      if (success) {
        await fetchLive();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
    }
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
    state = _repo.getOrders();
    fetchLive();
  }

  Future<void> fetchLive() async {
    try {
      final liveList = await _repo.fetchOrders();
      state = liveList;
    } catch (_) {}
  }

  void refresh() {
    state = _repo.getOrders();
    fetchLive();
  }

  Future<bool> createOrder(OrderModel order) async {
    try {
      final success = await _repo.createOrder(order);
      if (success) {
        await fetchLive();
        _ref.read(inventoryProvider.notifier).refresh();
        _ref.read(customerProvider.notifier).refresh();
        return true;
      }
      return false;
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
    try {
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
        await fetchLive();
        _ref.read(inventoryProvider.notifier).refresh();
        _ref.read(customerProvider.notifier).refresh();
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteOrder(String id) async {
    try {
      final success = await _repo.deleteOrder(id);
      if (success) {
        await fetchLive();
        _ref.read(inventoryProvider.notifier).refresh();
        _ref.read(customerProvider.notifier).refresh();
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, List<OrderModel>>((ref) {
  return OrderNotifier(ref.watch(appRepositoryProvider), ref);
});

// --- INVENTORY PROVIDER ---
class InventoryNotifier extends StateNotifier<InventoryModel> {
  final AppRepository _repo;

  InventoryNotifier(this._repo) : super(InventoryModel.initial()) {
    state = _repo.getInventory();
    fetchLive();
  }

  Future<void> fetchLive() async {
    try {
      final liveInv = await _repo.fetchInventory();
      state = liveInv;
    } catch (_) {}
  }

  void refresh() {
    state = _repo.getInventory();
    fetchLive();
  }

  Future<bool> update(InventoryModel inventory) async {
    try {
      final success = await _repo.saveInventory(inventory);
      if (success) {
        await fetchLive();
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
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
    state = _repo.getWaterPurchases();
    fetchLive();
  }

  Future<void> fetchLive() async {
    try {
      final liveList = await _repo.fetchWaterPurchases();
      state = liveList;
    } catch (_) {}
  }

  void refresh() {
    state = _repo.getWaterPurchases();
    fetchLive();
  }

  Future<bool> addPurchase(WaterPurchaseModel item) async {
    try {
      final success = await _repo.addWaterPurchase(item);
      if (success) {
        await fetchLive();
        _ref.read(inventoryProvider.notifier).refresh();
        _ref.read(expenseProvider.notifier).refresh();
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
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
    state = _repo.getEmployees();
    fetchLive();
  }

  Future<void> fetchLive() async {
    try {
      final liveList = await _repo.fetchEmployees();
      state = liveList;
    } catch (_) {}
  }

  void refresh() {
    state = _repo.getEmployees();
    fetchLive();
  }

  Future<bool> save(EmployeeModel employee) async {
    try {
      final success = await _repo.saveEmployee(employee);
      if (success) {
        await fetchLive();
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> delete(String id) async {
    try {
      final success = await _repo.deleteEmployee(id);
      if (success) {
        await fetchLive();
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
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
    state = _repo.getSalaries();
    fetchLive();
  }

  Future<void> fetchLive() async {
    try {
      state = _repo.getSalaries();
    } catch (_) {}
  }

  void refresh() {
    state = _repo.getSalaries();
    fetchLive();
  }

  Future<bool> addSalary(SalaryModel item) async {
    try {
      final success = await _repo.addSalary(item);
      if (success) {
        await fetchLive();
        _ref.read(expenseProvider.notifier).refresh();
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }
}

final salaryProvider = StateNotifierProvider<SalaryNotifier, List<SalaryModel>>((ref) {
  return SalaryNotifier(ref.watch(appRepositoryProvider), ref);
});

// --- EXPENSE PROVIDER ---
class ExpenseNotifier extends StateNotifier<List<ExpenseModel>> {
  final AppRepository _repo;

  ExpenseNotifier(this._repo) : super([]) {
    state = _repo.getExpenses();
    fetchLive();
  }

  Future<void> fetchLive() async {
    try {
      final liveList = await _repo.fetchExpenses();
      state = liveList;
    } catch (_) {}
  }

  void refresh() {
    state = _repo.getExpenses();
    fetchLive();
  }

  Future<bool> addExpense(ExpenseModel expense) async {
    try {
      final success = await _repo.addExpense(expense);
      if (success) {
        await fetchLive();
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
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
    state = _repo.getPayments();
    fetchLive();
  }

  Future<void> fetchLive() async {
    try {
      final liveList = await _repo.fetchPayments();
      state = liveList;
    } catch (_) {}
  }

  void refresh() {
    state = _repo.getPayments();
    fetchLive();
  }

  Future<bool> recordPayment(PaymentModel payment) async {
    try {
      final success = await _repo.recordPayment(payment);
      if (success) {
        await fetchLive();
        _ref.read(customerProvider.notifier).refresh();
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }
}

final paymentProvider = StateNotifierProvider<PaymentNotifier, List<PaymentModel>>((ref) {
  return PaymentNotifier(ref.watch(appRepositoryProvider), ref);
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

// --- DASHBOARD METRICS PROVIDER ---
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

final dashboardMetricsProvider = Provider<DashboardMetrics>((ref) {
  final orders = ref.watch(orderProvider);
  final inventory = ref.watch(inventoryProvider);
  final expenses = ref.watch(expenseProvider);
  final customers = ref.watch(customerProvider);
  final payments = ref.watch(paymentProvider);

  final today = DateTime.now();
  bool isToday(DateTime d) =>
      d.year == today.year && d.month == today.month && d.day == today.day;

  bool isSameDay(DateTime d1, DateTime d2) =>
      d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  final todayOrders = orders.where((o) => isToday(o.createdAt)).toList();
  final completedDeliveries = orders.where((o) => o.status == OrderStatus.delivered).toList();

  final todayRevenue = completedDeliveries
      .where((o) => isToday(o.createdAt))
      .fold<double>(0.0, (sum, item) => sum + item.totalAmount);

  final totalOrderRevenue = completedDeliveries.fold<double>(
      0.0, (sum, item) => sum + item.totalAmount);

  final totalPaymentIncome = payments.fold<double>(
      0.0, (sum, item) => sum + item.amount);

  final totalIncome = totalOrderRevenue + totalPaymentIncome;

  final totalExpenses = expenses.fold<double>(
      0.0, (sum, item) => sum + item.amount);

  final pendingPaymentsTotal = customers.fold<double>(
      0.0, (sum, item) => sum + item.pendingDues);

  final netProfit = totalIncome - totalExpenses;

  // Calculate real-time 7 days daily trends
  final List<DailyTrendPoint> dailyTrends = List.generate(7, (index) {
    final date = today.subtract(Duration(days: 6 - index));
    final label = DateFormat('E').format(date);

    final dayRevenue = orders
        .where((o) => (o.status == OrderStatus.delivered || o.status == OrderStatus.pending) && isSameDay(o.createdAt, date))
        .fold<double>(0.0, (sum, o) => sum + o.totalAmount);

    final dayExpense = expenses
        .where((e) => isSameDay(e.date, date))
        .fold<double>(0.0, (sum, e) => sum + e.amount);

    return DailyTrendPoint(
      dayLabel: label,
      revenue: dayRevenue,
      expense: dayExpense,
    );
  });

  return DashboardMetrics(
    todayOrdersCount: todayOrders.length,
    todayRevenue: todayRevenue,
    totalIncome: totalIncome,
    totalExpenses: totalExpenses,
    netProfit: netProfit,
    filledCans: inventory.filledCans,
    emptyCans: inventory.emptyCans,
    damagedCans: inventory.damagedCans,
    customerBalanceCans: inventory.customerBalanceCans,
    pendingPaymentsTotal: pendingPaymentsTotal,
    completedDeliveriesCount: completedDeliveries.length,
    dailyTrends: dailyTrends,
  );
});
