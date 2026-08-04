import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/animated_counter_text.dart';
import '../../../providers/app_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardMetricsProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isAdmin = user?.role == UserRole.admin;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Welcome Banner - Premium Redesign
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A2540), Color(0xFF1DAEFF), Color(0xFF0077B6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1DAEFF).withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background Ambient Glow Circle
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                Positioned(
                  right: 80,
                  bottom: -40,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Live Date & Sync Status Chip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00E676),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${AppFormatters.formatDate(DateTime.now())} • Live Sync',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Welcome Greeting Title
                            Text(
                              'Welcome back, ${user?.name ?? "Admin"} 👋',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Subtitle Description
                            Text(
                              isAdmin
                                  ? 'Real-time overview of your water distribution business'
                                  : "Here are your assigned deliveries for today",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Animated Floating Logo Graphic
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                        ),
                        child: Image.asset(
                          'assets/Vector Only.png',
                          width: 44,
                          height: 44,
                          fit: BoxFit.contain,
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat(reverse: true))
                          .slideY(
                            begin: -0.08,
                            end: 0.08,
                            duration: 1800.ms,
                            curve: Curves.easeInOut,
                          ),
                    ],
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .slideY(begin: -0.1, duration: 500.ms, curve: Curves.easeOutCubic)
              .shimmer(delay: 600.ms, duration: 1000.ms, color: Colors.white.withValues(alpha: 0.15)),

          const SizedBox(height: 24),

          if (isAdmin) ...[
            // KPI Grid Cards
            const Text(
              'Key Performance Indicators',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 1100
                    ? 5
                    : constraints.maxWidth > 700
                        ? 3
                        : 2;
                final childAspectRatio = crossAxisCount >= 5
                    ? 1.3
                    : crossAxisCount == 3
                        ? 1.25
                        : 1.15;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: childAspectRatio,
                  children: [
                    _KpiCard(
                      title: "Today's Orders",
                      value: metrics.todayOrdersCount.toString(),
                      numericValue: metrics.todayOrdersCount.toDouble(),
                      icon: Icons.shopping_bag_outlined,
                      color: AppColors.primary,
                      onTap: () => _showTodaysOrdersModal(context, ref),
                    ),
                    _KpiCard(
                      title: 'Revenue Today',
                      value: AppFormatters.formatCompactCurrency(metrics.todayRevenue),
                      numericValue: metrics.todayRevenue,
                      isCurrency: true,
                      icon: Icons.currency_rupee,
                      color: AppColors.success,
                      onTap: () => context.go('/orders'),
                    ),
                    _KpiCard(
                      title: 'Total Income',
                      value: AppFormatters.formatCompactCurrency(metrics.totalIncome),
                      numericValue: metrics.totalIncome,
                      isCurrency: true,
                      icon: Icons.account_balance,
                      color: AppColors.primaryDark,
                      onTap: () => context.go('/payments'),
                    ),
                    _KpiCard(
                      title: 'Total Expenses',
                      value: AppFormatters.formatCompactCurrency(metrics.totalExpenses),
                      numericValue: metrics.totalExpenses,
                      isCurrency: true,
                      icon: Icons.receipt_long,
                      color: AppColors.error,
                      onTap: () => context.go('/expenses'),
                    ),
                    _KpiCard(
                      title: 'Pending Dues',
                      value: AppFormatters.formatCompactCurrency(metrics.pendingPaymentsTotal),
                      numericValue: metrics.pendingPaymentsTotal,
                      isCurrency: true,
                      icon: Icons.pending_actions,
                      color: AppColors.warning,
                      onTap: () => context.go('/customers'),
                    ),
                    _KpiCard(
                      title: 'Net Profit',
                      value: AppFormatters.formatCompactCurrency(metrics.netProfit),
                      numericValue: metrics.netProfit,
                      isCurrency: true,
                      icon: Icons.account_balance_wallet,
                      color: metrics.netProfit >= 0 ? AppColors.success : AppColors.error,
                      onTap: () => context.go('/reports'),
                    ),
                    _KpiCard(
                      title: 'Delivery Done',
                      value: metrics.completedDeliveriesCount.toString(),
                      numericValue: metrics.completedDeliveriesCount.toDouble(),
                      icon: Icons.task_alt,
                      color: AppColors.info,
                      onTap: () => context.go('/delivery'),
                    ),
                    _KpiCard(
                      title: 'Customer Can Balance',
                      value: metrics.customerBalanceCans.toString(),
                      numericValue: metrics.customerBalanceCans.toDouble(),
                      icon: Icons.people_outline,
                      color: AppColors.customerBalance,
                      onTap: () => context.go('/customers'),
                    ),
                    _KpiCard(
                      title: 'Damaged Cans',
                      value: metrics.damagedCans.toString(),
                      numericValue: metrics.damagedCans.toDouble(),
                      icon: Icons.warning_amber,
                      color: AppColors.damagedCans,
                      onTap: () => context.go('/inventory'),
                    ),
                    _KpiCard(
                      title: 'Filled Cans',
                      value: metrics.filledCans.toString(),
                      numericValue: metrics.filledCans.toDouble(),
                      icon: Icons.water_drop,
                      color: AppColors.filledCans,
                      onTap: () => context.go('/inventory'),
                    ),
                    _KpiCard(
                      title: 'Empty Cans',
                      value: metrics.emptyCans.toString(),
                      numericValue: metrics.emptyCans.toDouble(),
                      icon: Icons.crop_portrait,
                      color: AppColors.emptyCans,
                      onTap: () => context.go('/inventory'),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;

              final revenueSpots = metrics.dailyTrends
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.revenue))
                  .toList();

              final expenseSpots = metrics.dailyTrends
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.expense))
                  .toList();

              final cardRevenue = CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Revenue vs Expense (7 Days)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Container(width: 8, height: 8, color: AppColors.primary),
                            const SizedBox(width: 4),
                            const Text('Revenue', style: TextStyle(fontSize: 10)),
                            const SizedBox(width: 8),
                            Container(width: 8, height: 8, color: AppColors.error),
                            const SizedBox(width: 4),
                            const Text('Expense', style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx >= 0 && idx < metrics.dailyTrends.length) {
                                    return Text(
                                      metrics.dailyTrends[idx].dayLabel,
                                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: revenueSpots.isEmpty ? [const FlSpot(0, 0)] : revenueSpots,
                              isCurved: true,
                              color: AppColors.primary,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.primary.withValues(alpha: 0.1),
                              ),
                            ),
                            LineChartBarData(
                              spots: expenseSpots.isEmpty ? [const FlSpot(0, 0)] : expenseSpots,
                              isCurved: true,
                              color: AppColors.error,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.error.withValues(alpha: 0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );

              final cardDistribution = CustomCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Can Distribution',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: metrics.filledCans.toDouble(),
                              color: AppColors.filledCans,
                              title: 'Filled',
                              radius: 40,
                              titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            PieChartSectionData(
                              value: metrics.emptyCans.toDouble(),
                              color: AppColors.emptyCans,
                              title: 'Empty',
                              radius: 40,
                              titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            PieChartSectionData(
                              value: metrics.customerBalanceCans.toDouble(),
                              color: AppColors.customerBalance,
                              title: 'Cust',
                              radius: 40,
                              titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    cardRevenue,
                    const SizedBox(height: 16),
                    cardDistribution,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: cardRevenue),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: cardDistribution),
                ],
              );
            },
          ),
          ] else ...[
            // Delivery Boy View Shortcuts & Card
            CustomCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.delivery_dining, size: 64, color: AppColors.primary),
                  const SizedBox(height: 12),
                  const Text(
                    "Ready for Deliveries Today?",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You have ${metrics.todayOrdersCount} orders assigned to your route.",
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/delivery'),
                    icon: const Icon(Icons.navigation),
                    label: const Text("Open Delivery Checklist"),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showTodaysOrdersModal(BuildContext context, WidgetRef ref) {
    final orders = ref.read(orderProvider);
    final today = DateTime.now();
    bool isToday(DateTime d) =>
        d.year == today.year && d.month == today.month && d.day == today.day;

    final todayOrders = orders.where((o) => isToday(o.createdAt)).toList();
    final totalCans = todayOrders.fold<int>(0, (sum, o) => sum + o.quantity);
    final totalRevenue = todayOrders.fold<double>(0.0, (sum, o) => sum + o.totalAmount);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modal Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's Orders Details",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          AppFormatters.formatDate(DateTime.now()),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Summary Stats Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Total Orders', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text('${todayOrders.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                    Container(height: 24, width: 1, color: AppColors.textSecondary.withValues(alpha: 0.2)),
                    Column(
                      children: [
                        const Text('Total Cans', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text('$totalCans Cans', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.filledCans)),
                      ],
                    ),
                    Container(height: 24, width: 1, color: AppColors.textSecondary.withValues(alpha: 0.2)),
                    Column(
                      children: [
                        const Text('Total Value', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(AppFormatters.formatCurrency(totalRevenue), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Orders List
              Expanded(
                child: todayOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 54, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            const Text(
                              'No orders placed today yet.',
                              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: todayOrders.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final order = todayOrders[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: Text(
                                '${order.quantity}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                            title: Text(
                              order.customerName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              '${order.quantity} Cans • ₹${order.unitPrice}/can • Driver: ${order.assignedDriverName ?? "Unassigned"}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  AppFormatters.formatCurrency(order.totalAmount),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: order.status == OrderStatus.delivered
                                        ? AppColors.success.withValues(alpha: 0.15)
                                        : AppColors.warning.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    order.status.displayName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: order.status == OrderStatus.delivered
                                          ? AppColors.success
                                          : AppColors.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/orders');
                  },
                  icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                  label: const Text('View All Orders Page', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final double? numericValue;
  final bool isCurrency;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.title,
    required this.value,
    this.numericValue,
    this.isCurrency = false,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: CustomCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: numericValue != null
                  ? AnimatedCounterText(
                      value: numericValue!,
                      isCurrency: isCurrency,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    )
                  : Text(
                      value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutQuad).fadeIn();
  }
}
