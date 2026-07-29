import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_enums.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/role_badge.dart';
import '../../providers/app_providers.dart';

class MainShellScreen extends ConsumerWidget {
  final Widget child;

  const MainShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isAdmin = user?.role == UserRole.admin;

    final String currentLocation = GoRouterState.of(context).uri.toString();

    // Define navigation items based on role
    final navItems = isAdmin
        ? const [
            _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard', route: '/dashboard'),
            _NavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Customers', route: '/customers'),
            _NavItem(icon: Icons.shopping_bag_outlined, activeIcon: Icons.shopping_bag, label: 'Orders', route: '/orders'),
            _NavItem(icon: Icons.local_shipping_outlined, activeIcon: Icons.local_shipping, label: 'Delivery', route: '/delivery'),
            _NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Inventory', route: '/inventory'),
            _NavItem(icon: Icons.water_drop_outlined, activeIcon: Icons.water_drop, label: 'Water Purchase', route: '/water-purchase'),
            _NavItem(icon: Icons.badge_outlined, activeIcon: Icons.badge, label: 'Employees', route: '/employees'),
            _NavItem(icon: Icons.payments_outlined, activeIcon: Icons.payments, label: 'Salary', route: '/salary'),
            _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Expenses', route: '/expenses'),
            _NavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: 'Payments', route: '/payments'),
            _NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Reports', route: '/reports'),
            _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings', route: '/settings'),
          ]
        : const [
            _NavItem(icon: Icons.today_outlined, activeIcon: Icons.today, label: "Today's Deliveries", route: '/delivery'),
            _NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Van Stock', route: '/inventory'),
            _NavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Customers', route: '/customers'),
            _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings', route: '/settings'),
          ];

    final isWideScreen = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(size: 30),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user?.name ?? 'Guest',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: PopupMenuButton<UserRole>(
              tooltip: 'Switch User Role',
              child: RoleBadge(role: user?.role ?? UserRole.admin),
              onSelected: (role) {
                ref.read(authProvider.notifier).switchRole(role);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Switched role to ${role.displayName}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: UserRole.admin,
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings, size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Switch to Admin'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: UserRole.deliveryBoy,
                  child: Row(
                    children: [
                      Icon(Icons.delivery_dining, size: 18, color: AppColors.info),
                      SizedBox(width: 8),
                      Text('Switch to Delivery Boy'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: isWideScreen
          ? null
          : Drawer(
              child: Column(
                children: [
                  UserAccountsDrawerHeader(
                    decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                    currentAccountPicture: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.water_drop, color: AppColors.primary, size: 36),
                    ),
                    accountName: Text(user?.name ?? 'Pure Drop Aqua', style: const TextStyle(fontWeight: FontWeight.bold)),
                    accountEmail: Text('Role: ${user?.role.displayName}', style: const TextStyle(color: Colors.white70)),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: navItems.length,
                      itemBuilder: (context, index) {
                        final item = navItems[index];
                        final isSelected = currentLocation == item.route;
                        return ListTile(
                          leading: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          ),
                          title: Text(
                            item.label,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                          selected: isSelected,
                          selectedTileColor: AppColors.primaryLight.withValues(alpha: 0.5),
                          onTap: () {
                            Navigator.pop(context);
                            context.go(item.route);
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.error),
                    title: const Text('Logout', style: TextStyle(color: AppColors.error)),
                    onTap: () {
                      ref.read(authProvider.notifier).logout();
                      context.go('/auth');
                    },
                  ),
                ],
              ),
            ),
      body: Row(
        children: [
          if (isWideScreen)
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  primary: false,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: NavigationRail(
                        selectedIndex: _getSelectedIndex(currentLocation, navItems),
                        onDestinationSelected: (index) {
                          context.go(navItems[index].route);
                        },
                        labelType: NavigationRailLabelType.all,
                        destinations: navItems.map((item) {
                          return NavigationRailDestination(
                            icon: Icon(item.icon),
                            selectedIcon: Icon(item.activeIcon, color: AppColors.primary),
                            label: Text(item.label),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: isWideScreen || navItems.length > 5
          ? null
          : BottomNavigationBar(
              currentIndex: _getSelectedIndex(currentLocation, navItems),
              onTap: (index) => context.go(navItems[index].route),
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textSecondary,
              items: navItems.map((item) {
                return BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  activeIcon: Icon(item.activeIcon),
                  label: item.label,
                );
              }).toList(),
            ),
    );
  }

  int _getSelectedIndex(String currentRoute, List<_NavItem> items) {
    final index = items.indexWhere((element) => element.route == currentRoute);
    return index >= 0 ? index : 0;
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}
