import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../models/delivery_model.dart';
import '../../../providers/app_providers.dart';

class EmployeeDashboardScreen extends ConsumerWidget {
  const EmployeeDashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getCurrentShift() {
    final hour = DateTime.now().hour;
    return (hour >= 6 && hour < 14) ? 'Morning Shift' : 'Evening Shift';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authState = ref.watch(authProvider);
    final user = authState.user;
    final empName = user?.name ?? 'Delivery Staff';
    final empId = user?.employeeId.isNotEmpty == true ? user!.employeeId : 'PDAEMP-001';

    final deliveries = ref.watch(deliveryProvider);
    final expenses = ref.watch(expenseProvider);
    final payments = ref.watch(paymentProvider);

    // Filter deliveries assigned to this driver
    final currentUid = user?.id ?? '';
    final isDriver = user?.role == UserRole.deliveryBoy;
    final driverDeliveries = isDriver
        ? deliveries.where((d) => d.employeeId == currentUid || d.employeeId == empId).toList()
        : deliveries;

    // Metrics calculations
    final totalOrders = driverDeliveries.length;
    final deliveredList = driverDeliveries.where((d) => d.deliveryStatus == 'delivered').toList();
    final deliveredCount = deliveredList.length;
    final pendingList = driverDeliveries.where((d) => d.deliveryStatus == 'pending' || d.deliveryStatus == 'assigned').toList();
    final pendingCount = pendingList.length;
    final skippedCount = driverDeliveries.where((d) => d.deliveryStatus == 'skipped').length;
    final cancelledList = driverDeliveries.where((d) => d.deliveryStatus == 'cancelled').toList();
    final cancelledCount = cancelledList.length;

    final amountCollected = deliveredList.fold(0.0, (sum, d) => sum + d.totalAmount);
    final pendingAmount = driverDeliveries
        .where((d) => d.deliveryStatus != 'delivered' && d.deliveryStatus != 'cancelled')
        .fold(0.0, (sum, d) => sum + d.totalAmount);
    final emptyCansCount = driverDeliveries.fold(0, (sum, d) => sum + d.emptyCansCollected);
    final damagedCansCount = driverDeliveries.fold(0, (sum, d) => sum + d.damagedCansReported);

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayExpenses = expenses
        .where((e) => DateFormat('yyyy-MM-dd').format(e.date) == todayStr)
        .fold(0.0, (sum, e) => sum + e.amount);

    final morningDeliveries = driverDeliveries.where((d) => d.deliverySlot.toLowerCase() == 'morning').length;
    final eveningDeliveries = driverDeliveries.where((d) => d.deliverySlot.toLowerCase() == 'evening').length;

    // Recent activity items
    final lastDelivered = deliveredList.isNotEmpty ? deliveredList.first : null;
    final lastCancelled = cancelledList.isNotEmpty ? cancelledList.first : null;
    final lastPayment = payments.isNotEmpty ? payments.first : null;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.read(deliveryProvider.notifier).refresh();
            ref.read(customerProvider.notifier).refresh();
            ref.read(expenseProvider.notifier).refresh();
            ref.read(paymentProvider.notifier).refresh();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Profile & Greeting Box
                _buildHeaderCard(
                  context,
                  greeting: _getGreeting(),
                  empName: empName,
                  empId: empId,
                  shift: _getCurrentShift(),
                  dateStr: DateFormat('EEEE, MMM d, yyyy').format(DateTime.now()),
                ),
                const SizedBox(height: 20),

                // Section Title: Quick Stats
                Text(
                  'Today\'s Delivery Overview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // 10 Summary Metric Cards Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.6,
                      children: [
                        _buildMetricCard(
                          context,
                          title: 'Today\'s Orders',
                          value: '$totalOrders',
                          icon: Icons.shopping_bag_outlined,
                          color: Colors.blue,
                          subtitle: 'Assigned Today',
                        ),
                        _buildMetricCard(
                          context,
                          title: 'Delivered',
                          value: '$deliveredCount',
                          icon: Icons.check_circle_outline,
                          color: AppColors.success,
                          subtitle: '$deliveredCount Completed',
                        ),
                        _buildMetricCard(
                          context,
                          title: 'Pending',
                          value: '$pendingCount',
                          icon: Icons.schedule,
                          color: AppColors.primary,
                          subtitle: '$pendingCount Remaining',
                        ),
                        _buildMetricCard(
                          context,
                          title: 'Skipped',
                          value: '$skippedCount',
                          icon: Icons.skip_next_outlined,
                          color: Colors.amber.shade800,
                          subtitle: 'Skipped Today',
                        ),
                        _buildMetricCard(
                          context,
                          title: 'Cancelled',
                          value: '$cancelledCount',
                          icon: Icons.cancel_outlined,
                          color: AppColors.error,
                          subtitle: 'Orders Cancelled',
                        ),
                        _buildMetricCard(
                          context,
                          title: 'Collected',
                          value: AppFormatters.formatCurrency(amountCollected),
                          icon: Icons.payments_outlined,
                          color: Colors.teal,
                          subtitle: 'Cash & UPI',
                        ),
                        _buildMetricCard(
                          context,
                          title: 'Pending Amount',
                          value: AppFormatters.formatCurrency(pendingAmount),
                          icon: Icons.account_balance_wallet_outlined,
                          color: Colors.deepOrange,
                          subtitle: 'To Collect',
                        ),
                        _buildMetricCard(
                          context,
                          title: 'Empty Cans',
                          value: '$emptyCansCount',
                          icon: Icons.water_drop_outlined,
                          color: Colors.cyan,
                          subtitle: 'Cans Received',
                        ),
                        _buildMetricCard(
                          context,
                          title: 'Damaged Cans',
                          value: '$damagedCansCount',
                          icon: Icons.warning_amber_outlined,
                          color: Colors.redAccent,
                          subtitle: 'Cans Reported',
                        ),
                        _buildMetricCard(
                          context,
                          title: 'Expenses',
                          value: AppFormatters.formatCurrency(todayExpenses),
                          icon: Icons.receipt_long_outlined,
                          color: Colors.purple,
                          subtitle: 'Spent Today',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Quick Actions Grid
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildActionButton(
                      context,
                      label: 'Deliveries',
                      icon: Icons.local_shipping,
                      color: AppColors.primary,
                      onTap: () => context.go('/delivery'),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context,
                      label: 'Orders',
                      icon: Icons.inventory_2,
                      color: Colors.blue,
                      onTap: () => context.go('/orders'),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context,
                      label: 'Payments',
                      icon: Icons.payment,
                      color: Colors.teal,
                      onTap: () => context.go('/payments'),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context,
                      label: 'Expenses',
                      icon: Icons.receipt_long,
                      color: Colors.purple,
                      onTap: () => context.go('/expenses'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Today's Shift Schedule Card
                _buildScheduleCard(
                  context,
                  total: totalOrders,
                  morningCount: morningDeliveries,
                  eveningCount: eveningDeliveries,
                  delivered: deliveredCount,
                ),
                const SizedBox(height: 20),

                // Recent Activity Timeline Card
                _buildRecentActivityCard(
                  context,
                  lastDelivered: lastDelivered,
                  lastCancelled: lastCancelled,
                  lastPayment: lastPayment,
                ),
                const SizedBox(height: 20),

                // Today's Executive Summary Card
                _buildDaySummaryCard(
                  context,
                  completed: deliveredCount,
                  remaining: pendingCount,
                  collected: amountCollected,
                  pendingDues: pendingAmount,
                  emptyCans: emptyCansCount,
                  damagedCans: damagedCansCount,
                  expenses: todayExpenses,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context, {
    required String greeting,
    required String empName,
    required String empId,
    required String shift,
    required String dateStr,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  empName.isNotEmpty ? empName[0].toUpperCase() : 'D',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting,',
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                    Text(
                      empName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  shift,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.badge_outlined, size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text('ID: $empId', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, val, child) {
              return Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.85), fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(
    BuildContext context, {
    required int total,
    required int morningCount,
    required int eveningCount,
    required int delivered,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = total > 0 ? (delivered / total).clamp(0.0, 1.0) : 0.0;

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Today\'s Delivery Schedule', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text('${(progress * 100).toInt()}% Done', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                children: [
                  const Icon(Icons.wb_sunny_outlined, size: 18, color: Colors.amber),
                  const SizedBox(width: 6),
                  Text('Morning Slot: ', style: theme.textTheme.bodySmall),
                  Text('$morningCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Container(width: 1, height: 16, color: Colors.grey.shade300),
              Row(
                children: [
                  const Icon(Icons.nights_stay_outlined, size: 18, color: Colors.indigo),
                  const SizedBox(width: 6),
                  Text('Evening Slot: ', style: theme.textTheme.bodySmall),
                  Text('$eveningCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard(
    BuildContext context, {
    required DeliveryModel? lastDelivered,
    required DeliveryModel? lastCancelled,
    required dynamic lastPayment,
  }) {
    final theme = Theme.of(context);

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Activity', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (lastDelivered != null)
            _buildActivityRow(
              context,
              title: 'Delivered to ${lastDelivered.customerName}',
              time: DateFormat('hh:mm a').format(lastDelivered.updatedAt),
              icon: Icons.check_circle,
              color: AppColors.success,
            ),
          if (lastPayment != null) ...[
            const Divider(height: 16),
            _buildActivityRow(
              context,
              title: 'Payment Collected: ${AppFormatters.formatCurrency(lastPayment.amount)}',
              time: DateFormat('hh:mm a').format(lastPayment.date),
              icon: Icons.payments,
              color: Colors.teal,
            ),
          ],
          if (lastCancelled != null) ...[
            const Divider(height: 16),
            _buildActivityRow(
              context,
              title: 'Cancelled order for ${lastCancelled.customerName}',
              time: DateFormat('hh:mm a').format(lastCancelled.updatedAt),
              icon: Icons.cancel,
              color: AppColors.error,
            ),
          ],
          if (lastDelivered == null && lastPayment == null && lastCancelled == null)
            Text('No activity recorded today yet.', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildActivityRow(
    BuildContext context, {
    required String title,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(radius: 14, backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, size: 16, color: color)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        ),
        Text(time, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _buildDaySummaryCard(
    BuildContext context, {
    required int completed,
    required int remaining,
    required double collected,
    required double pendingDues,
    required int emptyCans,
    required int damagedCans,
    required double expenses,
  }) {
    final theme = Theme.of(context);

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today\'s Executive Summary', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryCol('Completed', '$completed Tasks', AppColors.success),
              _buildSummaryCol('Remaining', '$remaining Tasks', AppColors.primary),
              _buildSummaryCol('Collected', AppFormatters.formatCurrency(collected), Colors.teal),
              _buildSummaryCol('Expenses', AppFormatters.formatCurrency(expenses), Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCol(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
