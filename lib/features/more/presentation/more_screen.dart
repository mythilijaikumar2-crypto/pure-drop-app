import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../providers/app_providers.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isAdmin = user?.role == UserRole.admin;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Profile Card Header
          CustomCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    (user?.name ?? 'A').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Pure Drop Staff',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Role: ${user?.role.displayName ?? "Delivery Personnel"} • ${user?.phone ?? "9876543210"}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05),

          const SizedBox(height: 20),

          // Business Section (Admin Only)
          if (isAdmin) ...[
            _buildSectionHeader('Business', Icons.business_center),
            _buildMoreSection(context, [
              const _MoreItem(
                title: 'Dashboard',
                subtitle: 'Business analytics & financial KPIs',
                icon: Icons.dashboard_outlined,
                iconColor: AppColors.primary,
                route: '/dashboard',
              ),
              const _MoreItem(
                title: 'Reports',
                subtitle: 'Sales, expense & P&L reports',
                icon: Icons.bar_chart_outlined,
                iconColor: AppColors.success,
                route: '/reports',
              ),
            ]),
            const SizedBox(height: 20),
          ],

          // Inventory Section
          _buildSectionHeader('Inventory & Can Stock', Icons.inventory_2),
          _buildMoreSection(context, [
            const _MoreItem(
              title: 'Inventory Stock',
              subtitle: 'Filled, empty & customer cans count',
              icon: Icons.inventory_2_outlined,
              iconColor: AppColors.filledCans,
              route: '/inventory',
            ),
            if (isAdmin)
              const _MoreItem(
                title: 'Water Purchase',
                subtitle: 'Supplier purchases & invoices',
                icon: Icons.water_drop_outlined,
                iconColor: AppColors.primaryDark,
                route: '/water-purchase',
              ),
          ]),

          const SizedBox(height: 20),

          // Finance Section
          _buildSectionHeader('Finance & Expenses', Icons.account_balance_wallet),
          _buildMoreSection(context, [
            const _MoreItem(
              title: 'Income & Payments',
              subtitle: 'Customer payments & collections',
              icon: Icons.payments_outlined,
              iconColor: AppColors.success,
              route: '/payments',
            ),
            const _MoreItem(
              title: 'Delivery Expenses',
              subtitle: 'Log fuel & route expenses',
              icon: Icons.receipt_long_outlined,
              iconColor: AppColors.error,
              route: '/expenses',
            ),
            if (isAdmin)
              const _MoreItem(
                title: 'Salary Payroll',
                subtitle: 'Staff payroll & monthly salaries',
                icon: Icons.badge_outlined,
                iconColor: AppColors.warning,
                route: '/salary',
              ),
          ]),

          const SizedBox(height: 20),

          // Staff Section (Admin Only)
          if (isAdmin) ...[
            _buildSectionHeader('Staff & HR', Icons.groups),
            _buildMoreSection(context, [
              const _MoreItem(
                title: 'Employees',
                subtitle: 'Manage drivers & staff members',
                icon: Icons.people_outline,
                iconColor: AppColors.info,
                route: '/employees',
              ),
            ]),
            const SizedBox(height: 20),
          ],

          // System Section
          _buildSectionHeader('System & Account', Icons.settings),
          _buildMoreSection(context, [
            if (isAdmin)
              const _MoreItem(
                title: 'Settings',
                subtitle: 'Local storage & Firebase config',
                icon: Icons.settings_outlined,
                iconColor: AppColors.textSecondary,
                route: '/settings',
              ),
            _MoreItem(
              title: 'Logout',
              subtitle: 'Sign out of your active session',
              icon: Icons.logout,
              iconColor: AppColors.error,
              onTap: () {
                ref.read(authProvider.notifier).logout();
                context.go('/auth');
              },
            ),
          ]),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreSection(BuildContext context, List<_MoreItem> items) {
    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 20),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  item.subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                onTap: () {
                  if (item.onTap != null) {
                    item.onTap!();
                  } else if (item.route != null) {
                    context.go(item.route!);
                  }
                },
              ),
              if (!isLast) const Divider(height: 1, indent: 60),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MoreItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String? route;
  final VoidCallback? onTap;

  const _MoreItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.route,
    this.onTap,
  });
}
