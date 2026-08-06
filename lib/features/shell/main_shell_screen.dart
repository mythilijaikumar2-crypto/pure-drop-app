import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_enums.dart';
import '../../core/widgets/role_badge.dart';
import '../../core/widgets/water_ripple_effect.dart';
import '../../providers/app_providers.dart';

class MainShellScreen extends ConsumerWidget {
  final Widget child;

  const MainShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isAdmin = user?.role == UserRole.admin || user?.role == UserRole.superAdmin;

    final orders = ref.watch(orderProvider);
    final pendingOrdersCount = orders.where((o) => o.status == OrderStatus.pending).length;
    final activeDeliveriesCount = orders.where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled).length;

    final String currentLocation = GoRouterState.of(context).uri.toString();

    // 5 Main Bottom Navigation Tabs according to specification
    final bottomNavItems = isAdmin
        ? [
            const _NavItem(
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard,
              label: 'Dashboard',
              route: '/dashboard',
            ),
            const _NavItem(
              icon: Icons.people_outline,
              activeIcon: Icons.people,
              label: 'Customers',
              route: '/customers',
            ),
            _NavItem(
              icon: Icons.inventory_2_outlined,
              activeIcon: Icons.inventory_2,
              label: 'Orders',
              route: '/orders',
              badgeCount: pendingOrdersCount,
            ),
            _NavItem(
              icon: Icons.local_shipping_outlined,
              activeIcon: Icons.local_shipping,
              label: 'Delivery',
              route: '/delivery',
              badgeCount: activeDeliveriesCount,
            ),
            const _NavItem(
              icon: Icons.menu,
              activeIcon: Icons.menu_open,
              label: 'More',
              route: '/more',
            ),
          ]
        : [
            const _NavItem(
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard,
              label: 'Dashboard',
              route: '/dashboard',
            ),
            _NavItem(
              icon: Icons.local_shipping_outlined,
              activeIcon: Icons.local_shipping,
              label: 'Delivery',
              route: '/delivery',
              badgeCount: activeDeliveriesCount,
            ),
            _NavItem(
              icon: Icons.inventory_2_outlined,
              activeIcon: Icons.inventory_2,
              label: 'Orders',
              route: '/orders',
              badgeCount: pendingOrdersCount,
            ),
            const _NavItem(
              icon: Icons.people_outline,
              activeIcon: Icons.people,
              label: 'Customers',
              route: '/customers',
            ),
            const _NavItem(
              icon: Icons.menu,
              activeIcon: Icons.menu_open,
              label: 'More',
              route: '/more',
            ),
          ];

    final isWideScreen = MediaQuery.of(context).size.width >= 700;
    final currentIndex = _getSelectedIndex(currentLocation, bottomNavItems);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset(
              'assets/Vector Only.png',
              width: 42,
              height: 42,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isAdmin ? 'Pure Drop Aqua Admin' : 'Pure Drop Aqua Driver',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
      drawer: null,
      body: Row(
        children: [
          if (isWideScreen)
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) => context.go(bottomNavItems[index].route),
              labelType: NavigationRailLabelType.all,
              destinations: bottomNavItems.map((item) {
                Widget iconWidget = Icon(item.icon);
                Widget selectedIconWidget = Icon(item.activeIcon, color: AppColors.primary);

                if (item.badgeCount > 0) {
                  iconWidget = Badge.count(count: item.badgeCount, child: iconWidget);
                  selectedIconWidget = Badge.count(count: item.badgeCount, child: selectedIconWidget);
                }

                return NavigationRailDestination(
                  icon: iconWidget,
                  selectedIcon: selectedIconWidget,
                  label: Text(item.label),
                );
              }).toList(),
            ),
          Expanded(child: WaterRippleEffect(child: child)),
        ],
      ),
      bottomNavigationBar: isWideScreen
          ? null
          : _AnimatedBottomNavBar(
              selectedIndex: currentIndex,
              items: bottomNavItems,
              onTap: (index) => context.go(bottomNavItems[index].route),
            ),
    );
  }

  int _getSelectedIndex(String currentRoute, List<_NavItem> items) {
    final index = items.indexWhere((element) => element.route == currentRoute);
    return index >= 0 ? index : 0;
  }
}

class _AnimatedBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _AnimatedBottomNavBar({
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = index == selectedIndex;

          Widget iconWidget = Icon(
            isSelected ? item.activeIcon : item.icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            size: 22,
          );

          if (item.badgeCount > 0) {
            iconWidget = Badge.count(
              count: item.badgeCount,
              backgroundColor: AppColors.error,
              textColor: Colors.white,
              child: iconWidget,
            );
          }

          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onTap(index),
                borderRadius: BorderRadius.circular(18),
                splashColor: AppColors.primaryLight.withValues(alpha: 0.3),
                highlightColor: Colors.transparent,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.fastOutSlowIn,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        scale: isSelected ? 1.12 : 1.0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutBack,
                        child: iconWidget,
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        style: TextStyle(
                          fontSize: isSelected ? 12 : 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        ),
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    this.badgeCount = 0,
  });
}
