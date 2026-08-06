import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/app_enums.dart';
import '../core/storage/hive_service.dart';
import '../models/user_model.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/customer/presentation/customer_profile_screen.dart';
import '../features/customer/presentation/customer_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/delivery/presentation/delivery_screen.dart';
import '../features/employee/presentation/employee_dashboard_screen.dart';
import '../features/employee/presentation/employee_screen.dart';
import '../features/expense/presentation/expense_screen.dart';
import '../features/inventory/presentation/inventory_screen.dart';
import '../features/order/presentation/order_screen.dart';
import '../features/payment/presentation/payment_screen.dart';
import '../features/report/presentation/report_screen.dart';
import '../features/salary/presentation/salary_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/water_purchase/presentation/water_purchase_screen.dart';
import '../features/more/presentation/more_screen.dart';
import '../features/shell/main_shell_screen.dart';

CustomTransitionPage<void> _buildAnimatedPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
  );
}

CustomTransitionPage<void> _buildFastShellPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 120),
    reverseTransitionDuration: const Duration(milliseconds: 100),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
        child: child,
      );
    },
  );
}

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      try {
        final userJson = HiveService.getData(AppConstants.authBoxName, 'currentUser');
        if (userJson != null) {
          final Map<String, dynamic> map = Map<String, dynamic>.from(userJson);
          final user = UserModel.fromJson(map);

          // Enforce RBAC Route Guards for Employee / Delivery Boy Account
          if (user.role == UserRole.deliveryBoy) {
            final loc = state.uri.toString();
            final adminOnlyRoutes = [
              '/water-purchase',
              '/employees',
              '/salary',
              '/reports',
              '/settings',
            ];
            if (adminOnlyRoutes.any((r) => loc.startsWith(r))) {
              return '/delivery';
            }
          }
        }
      } catch (e) {
        debugPrint('AppRouter redirect exception: $e');
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => _buildAnimatedPage(
          context: context,
          state: state,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        pageBuilder: (context, state) => _buildAnimatedPage(
          context: context,
          state: state,
          child: const AuthScreen(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainShellScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            pageBuilder: (context, state) {
              bool isEmployee = false;
              try {
                final userJson = HiveService.getData(AppConstants.authBoxName, 'currentUser');
                if (userJson != null) {
                  final map = Map<String, dynamic>.from(userJson);
                  final u = UserModel.fromJson(map);
                  isEmployee = u.role == UserRole.deliveryBoy;
                }
              } catch (_) {}

              return _buildFastShellPage(
                context: context,
                state: state,
                child: isEmployee ? const EmployeeDashboardScreen() : const DashboardScreen(),
              );
            },
          ),
          GoRoute(
            path: '/customers',
            name: 'customers',
            pageBuilder: (context, state) => _buildFastShellPage(
              context: context,
              state: state,
              child: const CustomerScreen(),
            ),
          ),
          GoRoute(
            path: '/customer/profile/:id',
            name: 'customerProfile',
            pageBuilder: (context, state) => _buildFastShellPage(
              context: context,
              state: state,
              child: CustomerProfileScreen(
                customerId: state.pathParameters['id'] ?? '',
              ),
            ),
          ),
          GoRoute(
            path: '/orders',
            name: 'orders',
            pageBuilder: (context, state) => _buildFastShellPage(
              context: context,
              state: state,
              child: const OrderScreen(),
            ),
          ),
          GoRoute(
            path: '/delivery',
            name: 'delivery',
            pageBuilder: (context, state) => _buildFastShellPage(
              context: context,
              state: state,
              child: const DeliveryScreen(),
            ),
          ),
          GoRoute(
            path: '/inventory',
            name: 'inventory',
            pageBuilder: (context, state) => _buildFastShellPage(
              context: context,
              state: state,
              child: const InventoryScreen(),
            ),
          ),
          GoRoute(
            path: '/water-purchase',
            name: 'waterPurchase',
            pageBuilder: (context, state) => _buildFastShellPage(
              context: context,
              state: state,
              child: const WaterPurchaseScreen(),
            ),
          ),
          GoRoute(
            path: '/employees',
            name: 'employees',
            pageBuilder: (context, state) => _buildFastShellPage(
              context: context,
              state: state,
              child: const EmployeeScreen(),
            ),
          ),
          GoRoute(
            path: '/salary',
            name: 'salary',
            pageBuilder: (context, state) => _buildFastShellPage(
              context: context,
              state: state,
              child: const SalaryScreen(),
            ),
          ),
          GoRoute(
            path: '/expenses',
            name: 'expenses',
            pageBuilder: (context, state) => _buildFastShellPage(
              context: context,
              state: state,
              child: const ExpenseScreen(),
            ),
          ),
          GoRoute(
            path: '/payments',
            name: 'payments',
            pageBuilder: (context, state) => _buildFastShellPage(
              context: context,
              state: state,
              child: const PaymentScreen(),
            ),
          ),
          GoRoute(
            path: '/reports',
            name: 'reports',
            pageBuilder: (context, state) => _buildFastShellPage(
              context: context,
              state: state,
              child: const ReportScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => _buildFastShellPage(
              context: context,
              state: state,
              child: const SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/more',
            name: 'more',
            pageBuilder: (context, state) => _buildFastShellPage(
              context: context,
              state: state,
              child: const MoreScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}
