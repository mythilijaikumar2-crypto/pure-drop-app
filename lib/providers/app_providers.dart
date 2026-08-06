import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/exceptions/app_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/app_enums.dart';
import '../core/storage/hive_service.dart';
import '../models/attendance_model.dart';
import '../models/customer_model.dart';
import '../models/employee_model.dart';
import '../models/expense_model.dart';
import '../models/inventory_model.dart';
import '../models/order_model.dart';
import '../models/payment_model.dart';
import '../models/salary_model.dart';
import '../models/user_model.dart';
import '../models/settings_model.dart';
import '../models/water_purchase_model.dart';
import '../models/delivery_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/auth_service.dart';
import '../core/services/connectivity_service.dart';
import '../core/services/firestore_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/storage_service.dart';
import '../core/services/sync_service.dart';
import '../repositories/app_repository.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/delivery_repository.dart';
import '../repositories/employee_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/inventory_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/payment_repository.dart';
import '../repositories/report_repository.dart';
import '../repositories/salary_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/water_purchase_repository.dart';

// --- CORE SERVICE PROVIDERS ---
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());
final syncServiceProvider = Provider<SyncService>((ref) => SyncService());
final connectivityServiceProvider = Provider<ConnectivityService>((ref) => ConnectivityService());

// --- CORE REPOSITORY PROVIDERS ---
final appRepositoryProvider = Provider<AppRepository>((ref) => AppRepository());
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) => DashboardRepository());
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) => SettingsRepository());
final reportRepositoryProvider = Provider<ReportRepository>((ref) => ReportRepository());

final customerRepositoryProvider = Provider<CustomerRepository>((ref) => CustomerRepository());
final orderRepositoryProvider = Provider<OrderRepository>((ref) => OrderRepository());
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) => InventoryRepository());
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) => PaymentRepository());
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) => ExpenseRepository());
final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) => EmployeeRepository());
final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) => DeliveryRepository());
final waterPurchaseRepositoryProvider = Provider<WaterPurchaseRepository>((ref) => WaterPurchaseRepository());
final salaryRepositoryProvider = Provider<SalaryRepository>((ref) => SalaryRepository());
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) => AttendanceRepository());

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
    // Async session check — starts as loading until Firebase confirms session
    _initSession();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SESSION INIT (on app start / restart)
  //
  // Rule: FirebaseAuth.currentUser is the ONLY source of truth.
  // Hive is only used as a profile cache after Firebase confirms auth.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _initSession() async {
    try {
      // Step 1: Check Firebase Auth — Firebase persists tokens automatically
      final firebaseUser = _authService.currentUser;

      if (firebaseUser == null) {
        // No active Firebase session → must log in
        debugPrint('ℹ️ AUTH: No Firebase session. Redirecting to Login.');
        state = AuthState(user: null, isAuthenticated: false);
        return;
      }

      debugPrint('✅ AUTH: Firebase session active — uid=${firebaseUser.uid}');

      // Step 2: Restore user profile from Hive cache (fast path)
      final box = HiveService.getBox(AppConstants.authBoxName);
      final userJson = box.get('currentUser');

      if (userJson != null) {
        final userMap = Map<String, dynamic>.from(userJson as Map);
        // Verify the cached UID matches the Firebase session UID (security check)
        if (userMap['uid'] == firebaseUser.uid) {
          final user = UserModel.fromJson(userMap);
          if (user.status == 'Active') {
            debugPrint('✅ AUTH: Session restored from Hive cache for uid=${user.id}');
            state = AuthState(user: user, isAuthenticated: true);
            return;
          }
        }
        // UID mismatch or inactive — clear stale Hive cache
        await _clearHiveSession();
      }

      // Step 3: Hive cache miss or stale — fetch fresh profile from Firestore
      debugPrint('ℹ️ AUTH: Hive cache miss. Fetching profile from Firestore...');
      final profileData = await _authService.fetchUserProfileByUid(firebaseUser.uid);

      if (profileData != null) {
        final user = UserModel.fromJson(profileData);
        if (user.status == 'Active') {
          await HiveService.saveData(AppConstants.authBoxName, 'currentUser', user.toJson());
          state = AuthState(user: user, isAuthenticated: true);
          debugPrint('✅ AUTH: Session restored from Firestore for uid=${user.id}');
          return;
        }
      }

      // Firestore profile not found or inactive — sign out
      debugPrint('⚠️ AUTH: No valid Firestore profile. Signing out.');
      await _authService.signOut();
      await _clearHiveSession();
      state = AuthState(user: null, isAuthenticated: false);
    } catch (e) {
      debugPrint('❌ AUTH: Session init error: $e');
      state = AuthState(user: null, isAuthenticated: false);
    }
  }

  /// Public alias for _initSession — called by SplashScreen after bootstrap
  Future<void> checkSavedSession() => _initSession();

  // ─────────────────────────────────────────────────────────────────────────
  // LOGIN
  //
  // Firebase Auth is MANDATORY. No local fallbacks.
  // If Firebase fails → show error → stay on Login screen.
  // ─────────────────────────────────────────────────────────────────────────
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
      // ── Step 1: Firebase Authentication (mandatory) ───────────────────────
      final UserCredential credential;
      try {
        credential = await _authService.signIn(cleanId, cleanPassword);
      } on AuthException catch (e) {
        state = AuthState(
          isAuthenticated: false,
          isLoading: false,
          errorMessage: e.message,
        );
        return false;
      }

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        state = AuthState(
          isAuthenticated: false,
          isLoading: false,
          errorMessage: 'Authentication failed. Please try again.',
        );
        return false;
      }

      debugPrint('✅ AUTH: Firebase Auth success — uid=${firebaseUser.uid} email=${firebaseUser.email}');

      // ── Step 2: Load user profile from Firestore ──────────────────────────
      final profileData = await _authService.fetchUserProfileByUid(firebaseUser.uid);

      final UserModel user;
      if (profileData != null) {
        user = UserModel.fromJson(profileData);
      } else {
        // Profile not in Firestore yet (e.g. admin after fresh bootstrap race condition)
        // Create profile from Firebase Auth data
        final isAdminId = cleanId.toLowerCase() == 'admin';
        final email = AuthService.syntheticEmail(cleanId);
        user = UserModel(
          id: firebaseUser.uid,
          employeeId: isAdminId ? 'PDAEMP-000' : cleanId.toUpperCase().startsWith('PDAEMP-') ? cleanId.toUpperCase() : 'EMP-001',
          name: isAdminId ? 'Pure Drop Admin' : cleanId,
          username: cleanId.toLowerCase(),
          firebaseEmail: email,
          role: isAdminId ? UserRole.admin : UserRole.deliveryBoy,
          employeeType: isAdminId ? 'Admin' : 'Delivery Staff',
          status: 'Active',
        );
        // Seed Firestore document so future logins work correctly
        await _authService.saveUserProfile(firebaseUser.uid, {
          ...user.toJson(),
          'uid': firebaseUser.uid,
          'role': user.role.name,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      // ── Step 3: Validate account ──────────────────────────────────────────
      if (user.status != 'Active') {
        await _authService.signOut();
        state = AuthState(
          isAuthenticated: false,
          isLoading: false,
          errorMessage: 'Your account is INACTIVE. Please contact Administrator.',
        );
        return false;
      }

      // ── Step 4: Persist session in Hive (profile cache, NO password) ──────
      final sessionUser = user.copyWith(
        id: firebaseUser.uid, // Always use Firebase UID as canonical id
        loginTimestamp: DateTime.now(),
      );

      await _saveSession(sessionUser, rememberMe);
      debugPrint('✅ AUTH: Login complete. uid=${sessionUser.id} role=${sessionUser.role.name}');
      return true;
    } catch (e) {
      debugPrint('❌ AUTH: Login error: $e');
      state = AuthState(
        isAuthenticated: false,
        isLoading: false,
        errorMessage: 'Authentication error. Please try again.',
      );
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SAVE SESSION TO HIVE (no passwords ever stored)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _saveSession(UserModel user, bool rememberMe) async {
    await HiveService.saveData(AppConstants.authBoxName, 'currentUser', user.toJson());
    await HiveService.saveData(AppConstants.authBoxName, 'rememberMe', rememberMe);
    await HiveService.saveData(
      AppConstants.authBoxName,
      'loginTimestamp',
      DateTime.now().toIso8601String(),
    );
    // Explicitly remove any previously saved password (security hygiene)
    await HiveService.deleteData(AppConstants.authBoxName, 'savedPassword');

    state = AuthState(
      user: user,
      isAuthenticated: true,
      isLoading: false,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CLEAR HIVE SESSION DATA
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _clearHiveSession() async {
    await HiveService.deleteData(AppConstants.authBoxName, 'currentUser');
    await HiveService.deleteData(AppConstants.authBoxName, 'rememberMe');
    await HiveService.deleteData(AppConstants.authBoxName, 'loginTimestamp');
    await HiveService.deleteData(AppConstants.authBoxName, 'savedPassword');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOGOUT
  // Always signs out from Firebase first, then clears Hive.
  // ─────────────────────────────────────────────────────────────────────────
  void logout() {
    _authService.signOut(); // Firebase session cleared
    _clearHiveSession();    // Hive cache cleared
    state = AuthState(user: null, isAuthenticated: false);
    debugPrint('🔓 AUTH: User logged out. Firebase session cleared.');
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


// --- CUSTOMER PROVIDER ---
class CustomerNotifier extends StateNotifier<List<CustomerModel>> {
  final AppRepository _repo;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  CustomerNotifier(this._repo) : super([]) {
    state = _repo.getCustomers();
  }

  void refresh() {
    state = _repo.getCustomers();
  }

  Future<bool> addOrUpdate(CustomerModel customer) async {
    _isLoading = true;
    _errorMessage = null;
    try {
      final success = await _repo.saveCustomer(customer);
      if (success) {
        refresh();
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
        refresh();
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
  }

  void refresh() {
    state = _repo.getOrders();
  }

  Future<bool> createOrder(OrderModel order) async {
    try {
      final success = await _repo.createOrder(order);
      if (success) {
        refresh();
        _ref.read(deliveryProvider.notifier).refresh();
        _ref.read(inventoryProvider.notifier).refresh();
        _ref.read(customerProvider.notifier).refresh();
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> assignDelivery({
    required String orderId,
    required String driverId,
    required String driverName,
  }) async {
    try {
      final success = await _repo.assignDelivery(
        orderId: orderId,
        driverId: driverId,
        driverName: driverName,
      );
      if (success) {
        refresh();
        _ref.read(deliveryProvider.notifier).refresh();
        _ref.read(customerProvider.notifier).refresh();
        _ref.read(employeeProvider.notifier).refresh();
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
        refresh();
        _ref.read(deliveryProvider.notifier).refresh();
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
        refresh();
        _ref.read(deliveryProvider.notifier).refresh();
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

final ordersStreamProvider = StreamProvider<List<OrderModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('orders')
      .snapshots(includeMetadataChanges: true)
      .map((snapshot) {
    final list = snapshot.docs.map((doc) => OrderModel.fromJson(doc.data())).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    Future.microtask(() async {
      final orderBox = HiveService.getBox(AppConstants.orderBoxName);
      for (final item in list) {
        await orderBox.put(item.id, jsonEncode(item.toJson()));
      }
      ref.read(orderProvider.notifier).refresh();
    });

    return list;
  });
});

// --- DELIVERY MANAGEMENT PROVIDER & REALTIME SNAPSHOT STREAM ---
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
    try {
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
        _ref.read(customerProvider.notifier).refresh();
        _ref.read(inventoryProvider.notifier).refresh();
        _ref.read(orderProvider.notifier).refresh();
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }
}

final deliveryProvider = StateNotifierProvider<DeliveryNotifier, List<DeliveryModel>>((ref) {
  return DeliveryNotifier(ref.watch(appRepositoryProvider), ref);
});

final deliveriesStreamProvider = StreamProvider<List<DeliveryModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('deliveries')
      .snapshots(includeMetadataChanges: true)
      .map((snapshot) {
    final list = snapshot.docs.map((doc) => DeliveryModel.fromJson(doc.data())).toList();
    list.sort((a, b) => b.deliveryDate.compareTo(a.deliveryDate));

    Future.microtask(() async {
      final deliveryBox = HiveService.getBox(AppConstants.deliveryBoxName);
      for (final item in list) {
        await deliveryBox.put(item.deliveryId, jsonEncode(item.toJson()));
      }
      ref.read(deliveryProvider.notifier).refresh();
      ref.read(customerProvider.notifier).refresh();
      ref.read(inventoryProvider.notifier).refresh();
    });

    return list;
  });
});

// --- INVENTORY PROVIDER ---
class InventoryNotifier extends StateNotifier<InventoryModel> {
  final AppRepository _repo;

  InventoryNotifier(this._repo) : super(InventoryModel.initial()) {
    state = _repo.getInventory();
  }

  void refresh() {
    state = _repo.getInventory();
  }

  Future<bool> update(InventoryModel inventory) async {
    try {
      final success = await _repo.saveInventory(inventory);
      if (success) {
        refresh();
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
  }

  void refresh() {
    state = _repo.getWaterPurchases();
  }

  Future<bool> addPurchase(WaterPurchaseModel item) async {
    try {
      final success = await _repo.addWaterPurchase(item);
      if (success) {
        refresh();
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
  }

  void refresh() {
    state = _repo.getEmployees();
  }

  Future<bool> save(EmployeeModel employee) async {
    try {
      final success = await _repo.saveEmployee(employee);
      if (success) {
        refresh();
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
        refresh();
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
  }

  void refresh() {
    state = _repo.getSalaries();
  }

  Future<bool> addSalary(SalaryModel item) async {
    try {
      final success = await _repo.addSalary(item);
      if (success) {
        refresh();
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
  }

  void refresh() {
    state = _repo.getExpenses();
  }

  Future<bool> addExpense(ExpenseModel expense) async {
    try {
      final success = await _repo.addExpense(expense);
      if (success) {
        refresh();
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
  }

  void refresh() {
    state = _repo.getPayments();
  }

  Future<bool> recordPayment(PaymentModel payment) async {
    try {
      final success = await _repo.recordPayment(payment);
      if (success) {
        refresh();
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
      .fold<double>(0.0, (acc, item) => acc + item.totalAmount);

  final totalOrderRevenue = completedDeliveries.fold<double>(
      0.0, (acc, item) => acc + item.totalAmount);

  final totalPaymentIncome = payments.fold<double>(
      0.0, (acc, item) => acc + item.amount);

  final totalIncome = totalOrderRevenue + totalPaymentIncome;

  final totalExpenses = expenses.fold<double>(
      0.0, (acc, item) => acc + item.amount);

  final pendingPaymentsTotal = customers.fold<double>(
      0.0, (acc, item) => acc + item.pendingDues);

  final netProfit = totalIncome - totalExpenses;

  // Calculate real-time 7 days daily trends
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

// --- ATTENDANCE PROVIDER ---
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

  Future<bool> markAttendance(AttendanceModel attendance) async {
    final result = await _repo.markAttendance(attendance);
    if (result.isSuccess) {
      await refresh();
      return true;
    }
    return false;
  }
}

final attendanceProvider = StateNotifierProvider<AttendanceNotifier, List<AttendanceModel>>((ref) {
  return AttendanceNotifier(ref.watch(attendanceRepositoryProvider));
});

// --- SETTINGS PROVIDER ---
class SettingsNotifier extends StateNotifier<SettingsModel> {
  final AppRepository _repo;

  SettingsNotifier(this._repo) : super(_repo.getSettings());

  void refresh() {
    state = _repo.getSettings();
  }

  Future<bool> updateSettings(SettingsModel newSettings) async {
    try {
      final success = await _repo.saveSettings(newSettings);
      if (success) {
        state = newSettings;
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsModel>((ref) {
  return SettingsNotifier(ref.watch(appRepositoryProvider));
});
