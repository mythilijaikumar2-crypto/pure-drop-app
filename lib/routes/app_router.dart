import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/customer/presentation/customer_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/delivery/presentation/delivery_screen.dart';
import '../features/employee/presentation/employee_screen.dart';
import '../features/expense/presentation/expense_screen.dart';
import '../features/inventory/presentation/inventory_screen.dart';
import '../features/order/presentation/order_screen.dart';
import '../features/payment/presentation/payment_screen.dart';
import '../features/report/presentation/report_screen.dart';
import '../features/salary/presentation/salary_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/water_purchase/presentation/water_purchase_screen.dart';
import '../features/shell/main_shell_screen.dart';

CustomTransitionPage<void> _buildAnimatedPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.03, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );
    },
  );
}

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
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
            pageBuilder: (context, state) => _buildAnimatedPage(
              context: context,
              state: state,
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/customers',
            name: 'customers',
            pageBuilder: (context, state) => _buildAnimatedPage(
              context: context,
              state: state,
              child: const CustomerScreen(),
            ),
          ),
          GoRoute(
            path: '/orders',
            name: 'orders',
            pageBuilder: (context, state) => _buildAnimatedPage(
              context: context,
              state: state,
              child: const OrderScreen(),
            ),
          ),
          GoRoute(
            path: '/delivery',
            name: 'delivery',
            pageBuilder: (context, state) => _buildAnimatedPage(
              context: context,
              state: state,
              child: const DeliveryScreen(),
            ),
          ),
          GoRoute(
            path: '/inventory',
            name: 'inventory',
            pageBuilder: (context, state) => _buildAnimatedPage(
              context: context,
              state: state,
              child: const InventoryScreen(),
            ),
          ),
          GoRoute(
            path: '/water-purchase',
            name: 'waterPurchase',
            pageBuilder: (context, state) => _buildAnimatedPage(
              context: context,
              state: state,
              child: const WaterPurchaseScreen(),
            ),
          ),
          GoRoute(
            path: '/employees',
            name: 'employees',
            pageBuilder: (context, state) => _buildAnimatedPage(
              context: context,
              state: state,
              child: const EmployeeScreen(),
            ),
          ),
          GoRoute(
            path: '/salary',
            name: 'salary',
            pageBuilder: (context, state) => _buildAnimatedPage(
              context: context,
              state: state,
              child: const SalaryScreen(),
            ),
          ),
          GoRoute(
            path: '/expenses',
            name: 'expenses',
            pageBuilder: (context, state) => _buildAnimatedPage(
              context: context,
              state: state,
              child: const ExpenseScreen(),
            ),
          ),
          GoRoute(
            path: '/payments',
            name: 'payments',
            pageBuilder: (context, state) => _buildAnimatedPage(
              context: context,
              state: state,
              child: const PaymentScreen(),
            ),
          ),
          GoRoute(
            path: '/reports',
            name: 'reports',
            pageBuilder: (context, state) => _buildAnimatedPage(
              context: context,
              state: state,
              child: const ReportScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => _buildAnimatedPage(
              context: context,
              state: state,
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}
