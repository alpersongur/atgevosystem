import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/responsive.dart';
import '../../crm/services/customer_service.dart';
import '../models/aging_buckets_model.dart';
import '../models/finance_summary_model.dart';
import '../models/invoice_model.dart';
import '../models/monthly_point_model.dart';
import '../models/top_customer_model.dart';
import '../services/finance_dashboard_service.dart';

class FinanceDashboardPage extends StatefulWidget {
  const FinanceDashboardPage({super.key});

  static const routeName = '/finance/dashboard';

  @override
  State<FinanceDashboardPage> createState() => _FinanceDashboardPageState();
}

class _FinanceDashboardPageState extends State<FinanceDashboardPage> {
  late Future<_DashboardData> _future;
  final NumberFormat _currencyFormat = NumberFormat.compactCurrency(
    locale: 'tr_TR',
    symbol: '₺',
  );
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_DashboardData> _loadData() async {
    final service = FinanceDashboardService.instance;
    final now = DateTime.now();
    final last30 = now.subtract(const Duration(days: 30));

    final totalSummaryFuture = service.getSummary();
    final last30SummaryFuture = service.getSummary(from: last30, to: now);
    final monthlyFuture = service.getMonthlySeries(12);
    final currencyFuture = service.getCurrencyBreakdown();
    final agingFuture = service.getAgingBuckets();
    final topCustomersFuture = service.getTopCustomers(limit: 10);
    final overdueFuture = service.getOverdueInvoices();

    await Future.wait([
      totalSummaryFuture,
      last30SummaryFuture,
      monthlyFuture,
      currencyFuture,
      agingFuture,
      topCustomersFuture,
      overdueFuture,
    ]);

    final totalSummary = await totalSummaryFuture;
    final last30Summary = await last30SummaryFuture;
    final monthlySeries = await monthlyFuture;
    final currencyBreakdown = await currencyFuture;
    final agingBuckets = await agingFuture;
    final topCustomersRaw = await topCustomersFuture;
    final overdueInvoices = await overdueFuture;

    final customerIds = {
      ...topCustomersRaw.map((e) => e.customerId),
      ...overdueInvoices.map((e) => e.customerId),
    }..removeWhere((id) => id.isEmpty);

    final customerNames = <String, String>{};
    await Future.wait(
      customerIds.map((id) async {
        final customer = await CustomerService.instance.getCustomerById(id);
        if (customer != null) {
          customerNames[id] = customer.companyName;
        }
      }),
    );

    final topCustomers = topCustomersRaw
        .map(
          (customer) => customer.copyWith(
            customerName: customerNames[customer.customerId],
          ),
        )
        .toList(growable: false);

    return _DashboardData(
      totalSummary: totalSummary,
      last30Summary: last30Summary,
      monthlySeries: monthlySeries,
      currencyBreakdown: currencyBreakdown,
      agingBuckets: agingBuckets,
      topCustomers: topCustomers,
      overdueInvoices: overdueInvoices,
      customerNames: customerNames,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadData();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finance Dashboard')),
      body: FutureBuilder<_DashboardData>(
        future: _future,
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

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('Dashboard verileri bulunamadı.'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Finance Dashboard',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildKpiSection(data),
                  const SizedBox(height: 24),
                  _buildChartsSection(data),
                  const SizedBox(height: 24),
                  _buildTablesSection(data),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiSection(_DashboardData data) {
    final tiles = [
      _KpiTile(
        title: 'Toplam Fatura Tutarı',
        total: data.totalSummary.invoiced,
        last30: data.last30Summary.invoiced,
        formatter: _currencyFormat,
      ),
      _KpiTile(
        title: 'Toplam Tahsilat',
        total: data.totalSummary.collected,
        last30: data.last30Summary.collected,
        formatter: _currencyFormat,
      ),
      _KpiTile(
        title: 'Bakiye',
        total: data.totalSummary.outstanding,
        last30: data.last30Summary.outstanding,
        formatter: _currencyFormat,
      ),
      _KpiTile(
        title: 'DSO (Gün)',
        total: data.totalSummary.dso,
        last30: data.last30Summary.dso,
        formatter: NumberFormat.decimalPattern('tr_TR'),
        suffix: ' gün',
      ),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: tiles
          .map(
            (tile) => SizedBox(
              width: min(MediaQuery.of(context).size.width / 2 - 32, 320),
              child: _KpiCard(tile: tile),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildChartsSection(_DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grafikler',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildCard(
              width: _chartWidth(context),
              title: 'Aylık Fatura ve Tahsilat (son 12 ay)',
              child: SizedBox(
                height: 260,
                child: data.monthlySeries.isEmpty
                    ? const Center(child: Text('Veri yok'))
                    : LineChart(_buildMonthlyChartData(data.monthlySeries)),
              ),
            ),
            _buildCard(
              width: _chartWidth(context),
              title: 'Para Birimine Göre Dağılım',
              child: SizedBox(
                height: 260,
                child: data.currencyBreakdown.isEmpty
                    ? const Center(child: Text('Veri yok'))
                    : PieChart(_buildCurrencyPieData(data.currencyBreakdown)),
              ),
            ),
            _buildCard(
              width: _chartWidth(context),
              title: 'Alacak Yaşlandırma',
              child: SizedBox(
                height: 260,
                child:
                    (data.agingBuckets.b0_30 +
                            data.agingBuckets.b31_60 +
                            data.agingBuckets.b61_90 +
                            data.agingBuckets.b90p) ==
                        0
                    ? const Center(child: Text('Veri yok'))
                    : BarChart(_buildAgingBarData(data.agingBuckets)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTablesSection(_DashboardData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final device =
            ResponsiveBreakpoints.sizeForWidth(constraints.maxWidth);

        final header = Text(
          'Tablolar',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        );

        if (device == DeviceSize.phone) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              const SizedBox(height: 12),
              _buildCard(
                title: 'En Çok Ciro Yapan 10 Müşteri',
                child: data.topCustomers.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Veri bulunamadı.'),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: data.topCustomers.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final customer = data.topCustomers[index];
                          final name = customer.customerName ??
                              data.customerNames[customer.customerId] ??
                              customer.customerId;
                          return ListTile(
                            leading: CircleAvatar(child: Text('${index + 1}')),
                            title: Text(name),
                            subtitle: Text(
                              _currencyFormat.format(customer.total),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              _buildCard(
                title: 'Vadesi Geçmiş Faturalar',
                child: data.overdueInvoices.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Vadesi geçmiş fatura bulunmuyor.'),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: data.overdueInvoices.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final invoice = data.overdueInvoices[index];
                          final customer =
                              data.customerNames[invoice.customerId] ??
                                  invoice.customerId;
                          final issue = invoice.issueDate != null
                              ? _dateFormat.format(invoice.issueDate!)
                              : '—';
                          final due = invoice.dueDate != null
                              ? _dateFormat.format(invoice.dueDate!)
                              : '—';
                          return ListTile(
                            leading: const Icon(Icons.receipt_long_outlined),
                            title: Text(invoice.invoiceNo),
                            subtitle: Text(
                              '$customer\nFatura: $issue • Vade: $due',
                            ),
                            isThreeLine: true,
                            trailing: Text(
                              _currencyFormat.format(invoice.grandTotal),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: 12),
            _buildCard(
              title: 'En Çok Ciro Yapan 10 Müşteri',
              child: data.topCustomers.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Veri bulunamadı.'),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Müşteri')),
                          DataColumn(label: Text('Toplam Fatura')),
                        ],
                        rows: data.topCustomers
                            .map(
                              (customer) => DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      customer.customerName ??
                                          data.customerNames[
                                              customer.customerId] ??
                                          customer.customerId,
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      _currencyFormat.format(customer.total),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'Vadesi Geçmiş Faturalar',
              child: data.overdueInvoices.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Vadesi geçmiş fatura bulunmuyor.'),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Fatura No')),
                          DataColumn(label: Text('Müşteri')),
                          DataColumn(label: Text('Fatura Tarihi')),
                          DataColumn(label: Text('Vade Tarihi')),
                          DataColumn(label: Text('Tutar')),
                          DataColumn(label: Text('Durum')),
                        ],
                        rows: data.overdueInvoices
                            .map(
                              (invoice) => DataRow(
                                cells: [
                                  DataCell(Text(invoice.invoiceNo)),
                                  DataCell(
                                    Text(
                                      data.customerNames[invoice.customerId] ??
                                          invoice.customerId,
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      invoice.issueDate != null
                                          ? _dateFormat.format(
                                              invoice.issueDate!,
                                            )
                                          : '—',
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      invoice.dueDate != null
                                          ? _dateFormat.format(
                                              invoice.dueDate!,
                                            )
                                          : '—',
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      _currencyFormat
                                          .format(invoice.grandTotal),
                                    ),
                                  ),
                                  DataCell(
                                    Text(invoice.status.toUpperCase()),
                                  ),
                                ],
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  double _chartWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1200) {
      return (screenWidth - 24 * 2 - 16 * 2) / 2;
    }
    return screenWidth - 48;
  }

  Widget _buildCard({
    required String title,
    required Widget child,
    double? width,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }

  LineChartData _buildMonthlyChartData(List<MonthlyPoint> data) {
    final spotsInvoiced = <FlSpot>[];
    final spotsCollected = <FlSpot>[];
    double maxY = 0;

    for (var i = 0; i < data.length; i++) {
      final point = data[i];
      spotsInvoiced.add(FlSpot(i.toDouble(), point.invoiced));
      spotsCollected.add(FlSpot(i.toDouble(), point.collected));
      maxY = max(maxY, max(point.invoiced, point.collected));
    }

    final titles = {
      for (var i = 0; i < data.length; i++)
        i.toDouble(): _formatMonthLabel(data[i].ym),
    };

    return LineChartData(
      minX: 0,
      maxX: data.length.toDouble() - 1,
      minY: 0,
      maxY: maxY == 0 ? 1 : maxY * 1.2,
      lineBarsData: [
        LineChartBarData(
          spots: spotsInvoiced,
          isCurved: true,
          color: Colors.indigo,
          barWidth: 3,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: spotsCollected,
          isCurved: true,
          color: Colors.green,
          barWidth: 3,
          dotData: const FlDotData(show: false),
        ),
      ],
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, _) {
              final label = titles[value] ?? '';
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, _) => Text(
              _currencyFormat.format(value),
              style: const TextStyle(fontSize: 10),
            ),
            reservedSize: 60,
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(
        show: true,
        border: const Border(
          left: BorderSide(color: Colors.black12),
          bottom: BorderSide(color: Colors.black12),
        ),
      ),
    );
  }

  PieChartData _buildCurrencyPieData(Map<String, double> data) {
    final total = data.values.fold<double>(0, (sum, value) => sum + value);
    final colors = <Color>[
      Colors.indigo,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.blueGrey,
    ];

    final sections = <PieChartSectionData>[];
    var index = 0;
    data.forEach((currency, amount) {
      final percentage = total == 0 ? 0 : (amount / total) * 100;
      sections.add(
        PieChartSectionData(
          value: amount,
          color: colors[index % colors.length],
          title: '${currency.toUpperCase()}\n${percentage.toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );
      index++;
    });

    return PieChartData(
      sections: sections,
      sectionsSpace: 2,
      centerSpaceRadius: 32,
    );
  }

  BarChartData _buildAgingBarData(AgingBuckets buckets) {
    final values = [
      buckets.b0_30,
      buckets.b31_60,
      buckets.b61_90,
      buckets.b90p,
    ];
    final maxY = values.fold<double>(0, max) * 1.2 + 1;

    final groups = [
      _buildBarGroup(0, buckets.b0_30),
      _buildBarGroup(1, buckets.b31_60),
      _buildBarGroup(2, buckets.b61_90),
      _buildBarGroup(3, buckets.b90p),
    ];

    return BarChartData(
      maxY: maxY,
      barGroups: groups,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, _) {
              switch (value.toInt()) {
                case 0:
                  return const Text('0-30');
                case 1:
                  return const Text('31-60');
                case 2:
                  return const Text('61-90');
                case 3:
                  return const Text('90+');
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (value, _) => Text(
              _currencyFormat.format(value),
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: const Border(
          left: BorderSide(color: Colors.black12),
          bottom: BorderSide(color: Colors.black12),
        ),
      ),
      gridData: const FlGridData(show: true, drawVerticalLine: false),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double value) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          width: 24,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          color: Colors.indigo,
        ),
      ],
    );
  }

  String _formatMonthLabel(String ym) {
    try {
      final parts = ym.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final date = DateTime(year, month);
      return DateFormat('MMM yy', 'tr_TR').format(date);
    } catch (_) {
      return ym;
    }
  }
}

class _DashboardData {
  const _DashboardData({
    required this.totalSummary,
    required this.last30Summary,
    required this.monthlySeries,
    required this.currencyBreakdown,
    required this.agingBuckets,
    required this.topCustomers,
    required this.overdueInvoices,
    required this.customerNames,
  });

  final FinanceSummary totalSummary;
  final FinanceSummary last30Summary;
  final List<MonthlyPoint> monthlySeries;
  final Map<String, double> currencyBreakdown;
  final AgingBuckets agingBuckets;
  final List<TopCustomer> topCustomers;
  final List<InvoiceModel> overdueInvoices;
  final Map<String, String> customerNames;
}

class _KpiTile {
  const _KpiTile({
    required this.title,
    required this.total,
    required this.last30,
    required this.formatter,
    this.suffix,
  });

  final String title;
  final double total;
  final double last30;
  final NumberFormat formatter;
  final String? suffix;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.tile});

  final _KpiTile tile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tile.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _formatValue(tile.total),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Son 30 Gün: ${_formatValue(tile.last30)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _formatValue(double value) {
    final formatted = value.isFinite ? tile.formatter.format(value) : '—';
    if (tile.suffix != null) {
      return '$formatted${tile.suffix}';
    }
    return formatted;
  }
}
