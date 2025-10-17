import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../crm/models/customer_model.dart';
import '../../crm/quotes/models/quote_model.dart';
import '../../crm/quotes/services/quote_service.dart';
import '../../crm/services/customer_service.dart';
import '../models/production_order_model.dart';
import '../services/production_service.dart';
import '../widgets/production_card.dart';
import 'production_detail_page.dart';

class ProductionDashboardPage extends StatelessWidget {
  const ProductionDashboardPage({super.key});

  static const routeName = '/production/dashboard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Üretim Takip Paneli')),
      body: StreamBuilder<List<ProductionOrderModel>>(
        stream: ProductionService.instance.getOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Üretim verileri yüklenirken hata oluştu.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final orders = snapshot.data ?? <ProductionOrderModel>[];
          final metrics = _DashboardMetrics.fromOrders(orders);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Üretim Takip Paneli',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _StatusSummary(metrics: metrics),
                const SizedBox(height: 24),
                _ChartSection(metrics: metrics),
                const SizedBox(height: 24),
                _RecentOrdersSection(orders: orders),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusSummary extends StatelessWidget {
  const _StatusSummary({required this.metrics});

  final _DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryCard(
        label: 'Beklemede',
        value: metrics.waiting.toString(),
        color: Colors.grey.shade200,
        accent: Colors.grey.shade700,
      ),
      _SummaryCard(
        label: 'Üretimde',
        value: metrics.inProgress.toString(),
        color: Colors.blue.shade50,
        accent: Colors.blue.shade700,
      ),
      _SummaryCard(
        label: 'Kalite Kontrol',
        value: metrics.qualityCheck.toString(),
        color: Colors.amber.shade50,
        accent: Colors.amber.shade800,
      ),
      _SummaryCard(
        label: 'Tamamlandı',
        value: metrics.completed.toString(),
        color: Colors.green.shade50,
        accent: Colors.green.shade700,
      ),
      _SummaryCard(
        label: 'Sevk Edildi',
        value: metrics.shipped.toString(),
        color: Colors.teal.shade50,
        accent: Colors.teal.shade700,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final cardsPerRow = maxWidth > 1100
            ? 5
            : maxWidth > 900
            ? 4
            : maxWidth > 600
            ? 3
            : 2;
        final cardWidth = (maxWidth - (16 * (cardsPerRow - 1))) / cardsPerRow;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards
              .map(
                (card) =>
                    SizedBox(width: cardWidth.clamp(200, 280), child: card),
              )
              .toList(),
        );
      },
    );
  }
}

class _ChartSection extends StatelessWidget {
  const _ChartSection({required this.metrics});

  final _DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final children = [
          Expanded(
            child: _SectionCard(
              title: 'Duruma Göre Dağılım',
              child: SizedBox(
                height: 260,
                child: _StatusPieChart(metrics: metrics),
              ),
            ),
          ),
          const SizedBox(width: 16, height: 16),
          Expanded(
            child: _SectionCard(
              title: 'Haftalık Üretim Durumu',
              child: SizedBox(
                height: 260,
                child: _CompletionBarChart(metrics: metrics),
              ),
            ),
          ),
        ];

        return isWide ? Row(children: children) : Column(children: children);
      },
    );
  }
}

class _StatusPieChart extends StatelessWidget {
  const _StatusPieChart({required this.metrics});

  final _DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final total = metrics.total;
    if (total == 0) {
      return const Center(child: Text('Gösterilecek veri bulunamadı.'));
    }

    final sections = [
      _pieSection(
        value: metrics.waiting,
        color: Colors.grey.shade400,
        label: 'Beklemede',
      ),
      _pieSection(
        value: metrics.inProgress,
        color: Colors.blue.shade400,
        label: 'Üretimde',
      ),
      _pieSection(
        value: metrics.qualityCheck,
        color: Colors.amber.shade600,
        label: 'Kalite',
      ),
      _pieSection(
        value: metrics.completed,
        color: Colors.green.shade400,
        label: 'Tamamlandı',
      ),
      _pieSection(
        value: metrics.shipped,
        color: Colors.teal.shade400,
        label: 'Sevk',
      ),
    ].where((section) => section.value > 0).toList();

    return PieChart(
      PieChartData(sections: sections, sectionsSpace: 2, centerSpaceRadius: 32),
    );
  }

  PieChartSectionData _pieSection({
    required int value,
    required Color color,
    required String label,
  }) {
    final total = metrics.total.toDouble();
    final percent = total == 0 ? 0 : (value / total) * 100;
    return PieChartSectionData(
      value: value.toDouble(),
      color: color,
      title: '${percent.toStringAsFixed(0)}%',
      titleStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }
}

class _CompletionBarChart extends StatelessWidget {
  const _CompletionBarChart({required this.metrics});

  final _DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final bars = metrics.weeklyTrend;
    if (bars.isEmpty) {
      return const Center(child: Text('Trend grafiği için veri bulunamadı.'));
    }

    return BarChart(
      BarChartData(
        groupsSpace: 16,
        maxY:
            (bars
                .map(
                  (e) =>
                      e.completed > e.inProgress ? e.completed : e.inProgress,
                )
                .fold<int>(
                  0,
                  (prev, element) => element > prev ? element : prev,
                )
                .toDouble()) +
            1,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= bars.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(bars[index].label),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, _) => Text(value.toInt().toString()),
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        barGroups: [
          for (var i = 0; i < bars.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: bars[i].completed.toDouble(),
                  width: 14,
                  color: Colors.green.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: bars[i].inProgress.toDouble(),
                  width: 14,
                  color: Colors.blue.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true, horizontalInterval: 1),
      ),
    );
  }
}

class _RecentOrdersSection extends StatelessWidget {
  const _RecentOrdersSection({required this.orders});

  final List<ProductionOrderModel> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const _SectionCard(
        title: 'Son Üretim Talimatları',
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Henüz üretim talimatı bulunmuyor.'),
        ),
      );
    }

    final sorted = List.of(orders)
      ..sort(
        (a, b) => (b.updatedAt ?? b.createdAt ?? DateTime.now()).compareTo(
          a.updatedAt ?? a.createdAt ?? DateTime.now(),
        ),
      );
    final recent = sorted.take(10).toList(growable: false);

    return StreamBuilder<List<CustomerModel>>(
      stream: CustomerService.instance.getCustomers(),
      builder: (context, customerSnapshot) {
        final customerMap = {
          for (final customer in customerSnapshot.data ?? [])
            customer.id: customer.companyName,
        };

        return StreamBuilder<List<QuoteModel>>(
          stream: QuoteService().getQuotes(),
          builder: (context, quoteSnapshot) {
            final quoteMap = {
              for (final quote in quoteSnapshot.data ?? [])
                quote.id: quote.quoteNumber,
            };
            final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

            return _SectionCard(
              title: 'Son Üretim Talimatları',
              child: Column(
                children: [
                  for (final order in recent)
                    ListTile(
                      leading: ProductionStatusChip(status: order.status),
                      title: Text(quoteMap[order.quoteId] ?? order.quoteId),
                      subtitle: Text(
                        '${customerMap[order.customerId] ?? 'Müşteri'} • ${dateFormat.format(order.updatedAt ?? order.createdAt ?? DateTime.now())}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductionDetailPage(orderId: order.id),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.accent,
  });

  final String label;
  final String value;
  final Color color;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _DashboardMetrics {
  _DashboardMetrics({
    required this.total,
    required this.waiting,
    required this.inProgress,
    required this.qualityCheck,
    required this.completed,
    required this.shipped,
    required this.weeklyTrend,
  });

  factory _DashboardMetrics.fromOrders(List<ProductionOrderModel> orders) {
    final counts = <String, int>{
      'waiting': 0,
      'in_progress': 0,
      'quality_check': 0,
      'completed': 0,
      'shipped': 0,
    };

    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day - now.weekday + 1);
    final trendBuckets = List.generate(
      7,
      (index) =>
          DateTime(weekStart.year, weekStart.month, weekStart.day + index),
    );
    final trendData = [
      for (final day in trendBuckets)
        _TrendPoint(
          label: DateFormat('E', 'tr_TR').format(day),
          completed: 0,
          inProgress: 0,
        ),
    ];

    for (final order in orders) {
      counts.update(order.status, (value) => value + 1, ifAbsent: () => 1);

      final updated = order.updatedAt ?? order.createdAt;
      if (updated != null) {
        final index = updated.difference(weekStart).inDays;
        if (index >= 0 && index < trendData.length) {
          if (order.status == 'completed' || order.status == 'shipped') {
            trendData[index] = trendData[index].copyWith(
              completed: trendData[index].completed + 1,
            );
          }
          if (order.status == 'in_progress') {
            trendData[index] = trendData[index].copyWith(
              inProgress: trendData[index].inProgress + 1,
            );
          }
        }
      }
    }

    return _DashboardMetrics(
      total: orders.length,
      waiting: counts['waiting'] ?? 0,
      inProgress: counts['in_progress'] ?? 0,
      qualityCheck: counts['quality_check'] ?? 0,
      completed: counts['completed'] ?? 0,
      shipped: counts['shipped'] ?? 0,
      weeklyTrend: trendData,
    );
  }

  final int total;
  final int waiting;
  final int inProgress;
  final int qualityCheck;
  final int completed;
  final int shipped;
  final List<_TrendPoint> weeklyTrend;
}

class _TrendPoint {
  const _TrendPoint({
    required this.label,
    required this.completed,
    required this.inProgress,
  });

  final String label;
  final int completed;
  final int inProgress;

  _TrendPoint copyWith({int? completed, int? inProgress}) => _TrendPoint(
    label: label,
    completed: completed ?? this.completed,
    inProgress: inProgress ?? this.inProgress,
  );
}
