import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_card.dart';
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
          // Header Welcome Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${user?.name ?? "Admin"} 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAdmin
                            ? 'Overview of your water distribution business today'
                            : "Here are your assigned deliveries for today",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.water_drop, color: Colors.white, size: 32),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

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
                      icon: Icons.shopping_bag_outlined,
                      color: AppColors.primary,
                    ),
                    _KpiCard(
                      title: 'Revenue Today',
                      value: AppFormatters.formatCompactCurrency(metrics.todayRevenue),
                      icon: Icons.currency_rupee,
                      color: AppColors.success,
                    ),
                    _KpiCard(
                      title: 'Total Expenses',
                      value: AppFormatters.formatCompactCurrency(metrics.totalExpenses),
                      icon: Icons.receipt_long,
                      color: AppColors.error,
                    ),
                    _KpiCard(
                      title: 'Net Profit',
                      value: AppFormatters.formatCompactCurrency(metrics.netProfit),
                      icon: Icons.account_balance_wallet,
                      color: metrics.netProfit >= 0 ? AppColors.success : AppColors.error,
                    ),
                    _KpiCard(
                      title: 'Filled Cans',
                      value: metrics.filledCans.toString(),
                      icon: Icons.water_drop,
                      color: AppColors.filledCans,
                    ),
                    _KpiCard(
                      title: 'Empty Cans',
                      value: metrics.emptyCans.toString(),
                      icon: Icons.crop_portrait,
                      color: AppColors.emptyCans,
                    ),
                    _KpiCard(
                      title: 'Damaged Cans',
                      value: metrics.damagedCans.toString(),
                      icon: Icons.warning_amber,
                      color: AppColors.damagedCans,
                    ),
                    _KpiCard(
                      title: 'Customer Can Balance',
                      value: metrics.customerBalanceCans.toString(),
                      icon: Icons.people_outline,
                      color: AppColors.customerBalance,
                    ),
                    _KpiCard(
                      title: 'Pending Dues',
                      value: AppFormatters.formatCompactCurrency(metrics.pendingPaymentsTotal),
                      icon: Icons.pending_actions,
                      color: AppColors.warning,
                    ),
                    _KpiCard(
                      title: 'Deliveries Done',
                      value: metrics.completedDeliveriesCount.toString(),
                      icon: Icons.task_alt,
                      color: AppColors.info,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;

              final cardRevenue = CustomCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Revenue vs Expense Trend',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: const [
                                FlSpot(1, 1200),
                                FlSpot(2, 1900),
                                FlSpot(3, 1500),
                                FlSpot(4, 2800),
                                FlSpot(5, 3200),
                              ],
                              isCurved: true,
                              color: AppColors.primary,
                              barWidth: 3,
                            ),
                            LineChartBarData(
                              spots: const [
                                FlSpot(1, 400),
                                FlSpot(2, 600),
                                FlSpot(3, 800),
                                FlSpot(4, 500),
                                FlSpot(5, 1100),
                              ],
                              isCurved: true,
                              color: AppColors.error,
                              barWidth: 3,
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
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutQuad).fadeIn();
  }
}
