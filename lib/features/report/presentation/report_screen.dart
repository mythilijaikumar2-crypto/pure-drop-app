import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../providers/app_providers.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  Future<void> _exportPdfReport(BuildContext context, WidgetRef ref) async {
    final metrics = ref.read(dashboardMetricsProvider);
    final orders = ref.read(orderProvider);
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(AppConstants.appName, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Report Date: ${AppFormatters.formatDate(DateTime.now())}'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text('EXECUTIVE SUMMARY & METRICS STATEMENT', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 12),
                pw.TableHelper.fromTextArray(
                  headers: ['Metric', 'Value'],
                  data: [
                    ["Today's Revenue", AppFormatters.formatCurrency(metrics.todayRevenue)],
                    ['Total Expenses', AppFormatters.formatCurrency(metrics.totalExpenses)],
                    ['Net Profit', AppFormatters.formatCurrency(metrics.netProfit)],
                    ['Customer Pending Dues', AppFormatters.formatCurrency(metrics.pendingPaymentsTotal)],
                    ['Filled Cans Available', metrics.filledCans.toString()],
                    ['Customer Can Balance', metrics.customerBalanceCans.toString()],
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Text('RECENT ORDERS SUMMARY', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  headers: ['Order ID', 'Customer', 'Qty', 'Amount', 'Status'],
                  data: orders.take(10).map((o) {
                    return [o.id, o.customerName, '${o.quantity}', AppFormatters.formatCurrency(o.totalAmount), o.status.displayName];
                  }).toList(),
                ),
                pw.Spacer(),
                pw.Divider(),
                pw.Center(child: pw.Text('Pure Drop Aqua System - Generated Automatically')),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardMetricsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 450;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Business Analytics & PDF Export',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    CustomButton(
                      label: 'Export PDF',
                      icon: Icons.picture_as_pdf,
                      onPressed: () => _exportPdfReport(context, ref),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Business Analytics & PDF Export',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CustomButton(
                    label: 'Export PDF',
                    icon: Icons.picture_as_pdf,
                    width: 140,
                    onPressed: () => _exportPdfReport(context, ref),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Summary Cards Row
          Row(
            children: [
              Expanded(
                child: CustomCard(
                  backgroundColor: AppColors.successLight,
                  child: Column(
                    children: [
                      const Text('Today Revenue', style: TextStyle(color: AppColors.success), maxLines: 1, overflow: TextOverflow.ellipsis),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          AppFormatters.formatCompactCurrency(metrics.todayRevenue),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomCard(
                  backgroundColor: AppColors.errorLight,
                  child: Column(
                    children: [
                      const Text('Total Expenses', style: TextStyle(color: AppColors.error), maxLines: 1, overflow: TextOverflow.ellipsis),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          AppFormatters.formatCompactCurrency(metrics.totalExpenses),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomCard(
                  backgroundColor: AppColors.primaryLight,
                  child: Column(
                    children: [
                      const Text('Net Profit', style: TextStyle(color: AppColors.primaryDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          AppFormatters.formatCompactCurrency(metrics.netProfit),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Detailed Bar Chart
          CustomCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Revenue vs Expense Comparison (Past 7 Days)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < metrics.dailyTrends.length) {
                                return Text(metrics.dailyTrends[idx].dayLabel, style: const TextStyle(fontSize: 11));
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(metrics.dailyTrends.length, (i) {
                        final item = metrics.dailyTrends[i];
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(toY: item.revenue > 0 ? item.revenue : 50, color: AppColors.primary, width: 12),
                            BarChartRodData(toY: item.expense > 0 ? item.expense : 30, color: AppColors.error, width: 12),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
