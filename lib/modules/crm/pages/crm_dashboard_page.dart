import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/customer_model.dart';
import '../services/customer_service.dart';
import 'customer_detail_page.dart';

class CrmDashboardPage extends StatelessWidget {
  const CrmDashboardPage({super.key});

  static const routeName = '/crm/dashboard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CRM Dashboard')),
      body: StreamBuilder<List<CustomerModel>>(
        stream: CustomerService().getCustomers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Veriler yüklenirken bir hata oluştu.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final customers = snapshot.data ?? <CustomerModel>[];
          final metrics = _DashboardMetrics.fromCustomers(customers);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CRM Dashboard',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _SummaryMetrics(metrics: metrics),
                const SizedBox(height: 24),
                _SectionCard(
                  title: 'Müşteri Tür Dağılımı',
                  child: SizedBox(
                    height: 260,
                    child: _CustomerTypePieChart(metrics: metrics),
                  ),
                ),
                const SizedBox(height: 24),
                _SectionCard(
                  title: 'Aylara Göre Yeni Müşteri',
                  child: SizedBox(
                    height: 280,
                    child: _NewCustomersBarChart(metrics: metrics),
                  ),
                ),
                const SizedBox(height: 24),
                _SectionCard(
                  title: 'Müşteri Büyümesi',
                  child: SizedBox(
                    height: 280,
                    child: _CustomerGrowthLineChart(metrics: metrics),
                  ),
                ),
                const SizedBox(height: 24),
                _RecentCustomersSection(customers: customers),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryMetrics extends StatelessWidget {
  const _SummaryMetrics({required this.metrics});

  final _DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryCard(
        title: 'Toplam Müşteri',
        value: metrics.totalCustomers.toString(),
      ),
      _SummaryCard(
        title: 'Son 30 Günde Yeni',
        value: metrics.newCustomersLast30.toString(),
      ),
      _SummaryCard(
        title: 'Kurumsal / Bireysel',
        value:
            '${metrics.corporateCustomers}/${metrics.individualCustomers} (${metrics.corporateShare.toStringAsFixed(0)}% / ${metrics.individualShare.toStringAsFixed(0)}%)',
      ),
      _SummaryCard(
        title: 'Notların Ortalama Uzunluğu',
        value: metrics.averageNotesLength.toStringAsFixed(1),
        unit: 'karakter',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final cardWidth = maxWidth > 900
            ? (maxWidth - 48) / 4
            : (maxWidth - 24) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards
              .map(
                (card) =>
                    SizedBox(width: cardWidth.clamp(220, 360), child: card),
              )
              .toList(),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.value, this.unit});

  final String title;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (unit != null)
                  Text(unit!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerTypePieChart extends StatelessWidget {
  const _CustomerTypePieChart({required this.metrics});

  final _DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final total = metrics.totalCustomers;
    if (total == 0) {
      return const Center(child: Text('Henüz müşteri verisi bulunmuyor.'));
    }

    final sections = [
      PieChartSectionData(
        color: Colors.indigo,
        value: metrics.corporateCustomers.toDouble(),
        title: 'Kurumsal\n${metrics.corporateShare.toStringAsFixed(0)}%',
        radius: 90,
        titleStyle: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.white),
      ),
      PieChartSectionData(
        color: Colors.teal,
        value: metrics.individualCustomers.toDouble(),
        title: 'Bireysel\n${metrics.individualShare.toStringAsFixed(0)}%',
        radius: 90,
        titleStyle: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.white),
      ),
    ];

    return PieChart(
      PieChartData(sections: sections, sectionsSpace: 4, centerSpaceRadius: 40),
    );
  }
}

class _NewCustomersBarChart extends StatelessWidget {
  const _NewCustomersBarChart({required this.metrics});

  final _DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final months = metrics.lastSixMonths;
    final values = metrics.newCustomersByMonth;

    if (months.isEmpty) {
      return const Center(child: Text('Grafik için yeterli veri yok.'));
    }

    return BarChart(
      BarChartData(
        maxY:
            (values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b))
                .toDouble() +
            1,
        barGroups: [
          for (var i = 0; i < months.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i].toDouble(),
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.indigo,
                  width: 18,
                ),
              ],
            ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= months.length) {
                  return const SizedBox.shrink();
                }
                final label = DateFormat('MMM').format(months[index]);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(label),
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
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(show: true, horizontalInterval: 1),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _CustomerGrowthLineChart extends StatelessWidget {
  const _CustomerGrowthLineChart({required this.metrics});

  final _DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final months = metrics.lastSixMonths;
    final cumulative = metrics.cumulativeCustomersByMonth;

    if (months.isEmpty) {
      return const Center(child: Text('Grafik için yeterli veri yok.'));
    }

    final spots = [
      for (var i = 0; i < months.length; i++)
        FlSpot(i.toDouble(), cumulative[i].toDouble()),
    ];

    return LineChart(
      LineChartData(
        minY: 0,
        maxY:
            (cumulative.isEmpty
                    ? 0
                    : cumulative.reduce((a, b) => a > b ? a : b))
                .toDouble() +
            1,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= months.length) {
                  return const SizedBox.shrink();
                }
                final label = DateFormat('MMM').format(months[index]);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(label),
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
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(show: true, horizontalInterval: 1),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.teal,
            barWidth: 4,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.teal.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentCustomersSection extends StatelessWidget {
  const _RecentCustomersSection({required this.customers});

  final List<CustomerModel> customers;

  @override
  Widget build(BuildContext context) {
    if (customers.isEmpty) {
      return const _SectionCard(
        title: 'Son Eklenen Müşteriler',
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Henüz müşteri kaydı bulunmuyor.'),
        ),
      );
    }

    final sorted = customers.where((c) => c.createdAt != null).toList()
      ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

    final recent = sorted.take(5).toList();
    final dateFormat = DateFormat('dd.MM.yyyy');

    return _SectionCard(
      title: 'Son Eklenen Müşteriler',
      child: Column(
        children: [
          for (final customer in recent)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(customer.companyName),
              subtitle: Text(
                '${customer.city ?? 'Şehir bilinmiyor'} • ${dateFormat.format(customer.createdAt!)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CustomerDetailPage(customerId: customer.id),
                  ),
                );
              },
            ),
        ],
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
      elevation: 1,
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
    required this.totalCustomers,
    required this.newCustomersLast30,
    required this.corporateCustomers,
    required this.individualCustomers,
    required this.averageNotesLength,
    required this.lastSixMonths,
    required this.newCustomersByMonth,
    required this.cumulativeCustomersByMonth,
  });

  factory _DashboardMetrics.fromCustomers(List<CustomerModel> customers) {
    final total = customers.length;
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 30));

    final newCustomers = customers.where((customer) {
      final created = customer.createdAt;
      return created != null && created.isAfter(cutoff);
    }).length;

    final corporate = customers
        .where((c) => (c.taxNumber ?? '').isNotEmpty)
        .length;
    final individual = total - corporate;

    final noteLengths = customers
        .map((c) => (c.notes ?? '').trim())
        .where((note) => note.isNotEmpty)
        .map((note) => note.length)
        .toList();
    final avgNotes = noteLengths.isEmpty
        ? 0.0
        : noteLengths.reduce((a, b) => a + b) / noteLengths.length;

    final months = _generateLastSixMonths(now);
    final newCounts = List.generate(months.length, (_) => 0);

    for (final customer in customers) {
      final created = customer.createdAt;
      if (created == null) continue;
      final monthStart = DateTime(created.year, created.month, 1);
      final index = months.indexOf(monthStart);
      if (index >= 0) {
        newCounts[index] += 1;
      }
    }

    var running = 0;
    final cumulative = <int>[];
    for (final count in newCounts) {
      running += count;
      cumulative.add(running);
    }

    return _DashboardMetrics(
      totalCustomers: total,
      newCustomersLast30: newCustomers,
      corporateCustomers: corporate,
      individualCustomers: individual,
      averageNotesLength: avgNotes,
      lastSixMonths: months,
      newCustomersByMonth: newCounts,
      cumulativeCustomersByMonth: cumulative,
    );
  }

  final int totalCustomers;
  final int newCustomersLast30;
  final int corporateCustomers;
  final int individualCustomers;
  final double averageNotesLength;
  final List<DateTime> lastSixMonths;
  final List<int> newCustomersByMonth;
  final List<int> cumulativeCustomersByMonth;

  double get corporateShare =>
      totalCustomers == 0 ? 0 : (corporateCustomers / totalCustomers) * 100;

  double get individualShare =>
      totalCustomers == 0 ? 0 : (individualCustomers / totalCustomers) * 100;

  static List<DateTime> _generateLastSixMonths(DateTime reference) {
    final list = <DateTime>[];
    for (var i = 5; i >= 0; i--) {
      final date = DateTime(reference.year, reference.month - i, 1);
      list.add(DateTime(date.year, date.month, 1));
    }
    return list;
  }
}
