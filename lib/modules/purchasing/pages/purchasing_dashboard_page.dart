import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/responsive.dart';
import '../models/bill_model.dart';
import '../models/purchase_order_model.dart';
import '../models/purchasing_dashboard_models.dart';
import '../services/purchasing_dashboard_service.dart';

class PurchasingDashboardPage extends StatefulWidget {
  const PurchasingDashboardPage({super.key});

  static const routeName = '/purchasing/dashboard';

  @override
  State<PurchasingDashboardPage> createState() =>
      _PurchasingDashboardPageState();
}

class _PurchasingDashboardPageState extends State<PurchasingDashboardPage> {
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
    final service = PurchasingDashboardService.instance;

    final summaryFuture = service.getSummary();
    final statusFuture = service.getStatusDistribution();
    final delayedFuture = service.getDelayedPOs();
    final supplierPerfFuture = service.getSupplierPerformance();
    final monthlySpendFuture = service.getMonthlySpend(monthsBack: 6);
    final billsFuture = service.getRecentBills(limit: 10);

    await Future.wait([
      summaryFuture,
      statusFuture,
      delayedFuture,
      supplierPerfFuture,
      monthlySpendFuture,
      billsFuture,
    ]);

    final summary = await summaryFuture;
    final statusDistribution = await statusFuture;
    final delayedOrders = await delayedFuture;
    final supplierPerformance = await supplierPerfFuture;
    final monthlySpend = await monthlySpendFuture;
    final recentBills = await billsFuture;

    final supplierIds = <String>{
      ...delayedOrders.map((e) => e.supplierId),
      ...supplierPerformance.map((e) => e.supplierId),
      ...recentBills.map((e) => e.supplierId),
    }..removeWhere((id) => id.isEmpty);

    final supplierNames = await service.getSupplierNames(supplierIds);

    final enrichedPerformance = supplierPerformance
        .map(
          (entry) => entry.copyWith(
            supplierName: supplierNames[entry.supplierId] ?? entry.supplierName,
          ),
        )
        .toList(growable: false);

    return _DashboardData(
      summary: summary,
      statusDistribution: statusDistribution,
      delayedOrders: delayedOrders,
      supplierPerformance: enrichedPerformance,
      monthlySpend: monthlySpend,
      recentBills: recentBills,
      supplierNames: supplierNames,
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
      appBar: AppBar(title: const Text('Satınalma Kontrol Paneli')),
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
                  'Kontrol paneli verileri yüklenirken hata oluştu.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(
              child: Text('Kontrol paneli verileri bulunamadı.'),
            );
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
                    'Satınalma Kontrol Paneli',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildKPISection(data),
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

  Widget _buildKPISection(_DashboardData data) {
    final summary = data.summary;
    final tiles = [
      _KpiTile(
        title: 'Toplam PO',
        value: summary.totalPOs.toString(),
        subtitle: 'Sistemdeki tüm PO sayısı',
      ),
      _KpiTile(
        title: 'Açık PO',
        value: summary.openPOs.toString(),
        subtitle: 'İşlemde olan emirler',
      ),
      _KpiTile(
        title: 'Geciken PO',
        value: summary.delayedPOs.toString(),
        subtitle: 'Bugüne kadar geciken',
      ),
      _KpiTile(
        title: 'Ort. Teslim Süresi',
        value: '${summary.avgLeadTimeDays.toStringAsFixed(1)} gün',
        subtitle: 'PO oluşturma → teslim',
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
    final statusDistribution = data.statusDistribution;
    final supplierPerformance = data.supplierPerformance;
    final monthlySpend = data.monthlySpend;

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
              title: 'PO Durum Dağılımı',
              width: _chartWidth(context),
              child: SizedBox(
                height: 260,
                child: statusDistribution.isEmpty
                    ? const Center(child: Text('Veri yok'))
                    : PieChart(_buildStatusPieData(statusDistribution)),
              ),
            ),
            _buildCard(
              title: 'Tedarikçi Performansı (On-Time vs Geç)',
              width: _chartWidth(context),
              child: SizedBox(
                height: 260,
                child: supplierPerformance.isEmpty
                    ? const Center(child: Text('Veri yok'))
                    : BarChart(_buildSupplierBarData(supplierPerformance)),
              ),
            ),
            _buildCard(
              title: 'Aylık Harcama (Son 6 Ay)',
              width: _chartWidth(context),
              child: SizedBox(
                height: 260,
                child: monthlySpend.isEmpty
                    ? const Center(child: Text('Veri yok'))
                    : LineChart(_buildMonthlySpendChart(monthlySpend)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTablesSection(_DashboardData data) {
    final delayedOrders = data.delayedOrders;
    final recentBills = data.recentBills;

    return LayoutBuilder(
      builder: (context, constraints) {
        final device = ResponsiveBreakpoints.sizeForWidth(constraints.maxWidth);

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
                title: 'Geciken Satınalma Emirleri',
                child: delayedOrders.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Geciken satınalma emri bulunmuyor.'),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: delayedOrders.length,
                        separatorBuilder: (context, _) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final order = delayedOrders[index];
                          final supplier =
                              data.supplierNames[order.supplierId] ??
                              order.supplierId;
                          final expected = order.expectedDate != null
                              ? _dateFormat.format(order.expectedDate!)
                              : '—';
                          return ListTile(
                            leading: const Icon(Icons.assignment_late_outlined),
                            title: Text(order.poNumber),
                            subtitle: Text(
                              'Tedarikçi: $supplier\nBeklenen: $expected',
                            ),
                            isThreeLine: true,
                            trailing: Text(order.status.toUpperCase()),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              _buildCard(
                title: 'Son 10 Tedarikçi Faturası',
                child: recentBills.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Fatura kaydı bulunmuyor.'),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentBills.length,
                        separatorBuilder: (context, _) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final bill = recentBills[index];
                          final supplier =
                              data.supplierNames[bill.supplierId] ??
                              bill.supplierId;
                          final date = bill.issueDate != null
                              ? _dateFormat.format(bill.issueDate!)
                              : '—';
                          return ListTile(
                            leading: const Icon(Icons.receipt_long_outlined),
                            title: Text(bill.billNo),
                            subtitle: Text(
                              'Tedarikçi: $supplier\nTarih: $date',
                            ),
                            isThreeLine: true,
                            trailing: Text(
                              _currencyFormat.format(bill.grandTotal),
                              style: Theme.of(context).textTheme.titleMedium
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
              title: 'Geciken Satınalma Emirleri',
              child: delayedOrders.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Geciken satınalma emri bulunmuyor.'),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('PO No')),
                          DataColumn(label: Text('Tedarikçi')),
                          DataColumn(label: Text('Beklenen Tarih')),
                          DataColumn(label: Text('Durum')),
                        ],
                        rows: delayedOrders
                            .map(
                              (order) => DataRow(
                                cells: [
                                  DataCell(Text(order.poNumber)),
                                  DataCell(
                                    Text(
                                      data.supplierNames[order.supplierId] ??
                                          order.supplierId,
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      order.expectedDate != null
                                          ? _dateFormat.format(
                                              order.expectedDate!,
                                            )
                                          : '—',
                                    ),
                                  ),
                                  DataCell(Text(order.status.toUpperCase())),
                                ],
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'Son 10 Tedarikçi Faturası',
              child: recentBills.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Fatura kaydı bulunmuyor.'),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Fatura No')),
                          DataColumn(label: Text('Tedarikçi')),
                          DataColumn(label: Text('Tarih')),
                          DataColumn(label: Text('Tutar')),
                          DataColumn(label: Text('Durum')),
                        ],
                        rows: recentBills
                            .map(
                              (bill) => DataRow(
                                cells: [
                                  DataCell(Text(bill.billNo)),
                                  DataCell(
                                    Text(
                                      data.supplierNames[bill.supplierId] ??
                                          bill.supplierId,
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      bill.issueDate != null
                                          ? _dateFormat.format(bill.issueDate!)
                                          : '—',
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      _currencyFormat.format(bill.grandTotal),
                                    ),
                                  ),
                                  DataCell(Text(bill.status.toUpperCase())),
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
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) {
      return (width - 48 - 16 * 2) / 2;
    }
    return width - 48;
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

  PieChartData _buildStatusPieData(Map<String, int> data) {
    final total = data.values.fold<int>(0, (sum, value) => sum + value);
    final colors = [
      Colors.indigo,
      Colors.orange,
      Colors.green,
      Colors.redAccent,
      Colors.blueGrey,
      Colors.purple,
    ];
    final sections = <PieChartSectionData>[];
    var index = 0;
    data.forEach((status, count) {
      if (count <= 0) return;
      final percentage = total == 0 ? 0 : (count / total) * 100;
      sections.add(
        PieChartSectionData(
          value: count.toDouble(),
          color: colors[index % colors.length],
          title: '${status.toUpperCase()}\n${percentage.toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
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

  BarChartData _buildSupplierBarData(List<SupplierPerformance> entries) {
    final groups = <BarChartGroupData>[];
    var maxY = 0.0;
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      maxY = max(maxY, max(entry.onTime.toDouble(), entry.late.toDouble()));
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: entry.onTime.toDouble(),
              color: Colors.green,
              width: 14,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: entry.late.toDouble(),
              color: Colors.redAccent,
              width: 14,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
          barsSpace: 6,
        ),
      );
    }

    return BarChartData(
      maxY: maxY == 0 ? 1 : maxY * 1.2,
      barGroups: groups,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            getTitlesWidget: (value, _) {
              if (value < 0 || value >= entries.length) {
                return const SizedBox.shrink();
              }
              final label =
                  entries[value.toInt()].supplierName ??
                  entries[value.toInt()].supplierId;
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 28),
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

  LineChartData _buildMonthlySpendChart(List<MonthlySpendPoint> points) {
    final spots = <FlSpot>[];
    var maxY = 0.0;
    for (var i = 0; i < points.length; i++) {
      final value = points[i].total;
      maxY = max(maxY, value);
      spots.add(FlSpot(i.toDouble(), value));
    }

    return LineChartData(
      minX: 0,
      maxX: points.length.toDouble() - 1,
      minY: 0,
      maxY: maxY == 0 ? 1 : maxY * 1.2,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.indigo,
          barWidth: 3,
          dotData: const FlDotData(show: true),
        ),
      ],
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            getTitlesWidget: (value, _) {
              if (value < 0 || value >= points.length) {
                return const SizedBox.shrink();
              }
              final label = points[value.toInt()].ym;
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(label, style: const TextStyle(fontSize: 11)),
              );
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
}

class _DashboardData {
  const _DashboardData({
    required this.summary,
    required this.statusDistribution,
    required this.delayedOrders,
    required this.supplierPerformance,
    required this.monthlySpend,
    required this.recentBills,
    required this.supplierNames,
  });

  final PurchasingSummary summary;
  final Map<String, int> statusDistribution;
  final List<PurchaseOrderModel> delayedOrders;
  final List<SupplierPerformance> supplierPerformance;
  final List<MonthlySpendPoint> monthlySpend;
  final List<BillModel> recentBills;
  final Map<String, String> supplierNames;
}

class _KpiTile {
  const _KpiTile({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;
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
              tile.value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(tile.subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
