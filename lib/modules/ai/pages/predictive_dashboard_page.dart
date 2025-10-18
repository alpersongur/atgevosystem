import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/responsive.dart';
import '../models/analytics_models.dart';
import '../services/analytics_service.dart';

class PredictiveDashboardPage extends StatefulWidget {
  const PredictiveDashboardPage({super.key});

  static const routeName = '/ai/predictive-dashboard';

  @override
  State<PredictiveDashboardPage> createState() =>
      _PredictiveDashboardPageState();
}

class _PredictiveDashboardPageState extends State<PredictiveDashboardPage> {
  final AnalyticsService _service = AnalyticsService.instance;
  late Future<PredictiveAnalyticsResult> _future;
  final DateFormat _monthFormat = DateFormat('MMM yy');
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: Intl.defaultLocale ?? 'tr_TR',
    symbol: '₺',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _future = _service.loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tahmin & Analitik'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _future = _service.loadAnalytics();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<PredictiveAnalyticsResult>(
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
                  'Analitik verileri yüklenirken hata oluştu.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final result = snapshot.data;
          if (result == null) {
            return const Center(child: Text('Analitik verisi bulunamadı.'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final device = ResponsiveBreakpoints.sizeForWidth(
                constraints.maxWidth,
              );
              final isPhone = device == DeviceSize.phone;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Özet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryCards(result, isPhone),
                    const SizedBox(height: 24),
                    Text(
                      'Satış Tahmini',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSalesForecastChart(result.salesForecast),
                    const SizedBox(height: 24),
                    Text(
                      'Üretim Yükü Tahmini',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildProductionForecastChart(result.productionForecast),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(PredictiveAnalyticsResult result, bool isPhone) {
    final nextSales = _currencyFormat.format(
      result.salesForecast.nextMonthEstimate,
    );
    final inventoryRisk = result.inventoryRisk;
    final highRiskText = inventoryRisk.hasRisk
        ? '${inventoryRisk.highRiskItemId} (Stok ${inventoryRisk.remainingQuantity.toStringAsFixed(0)} / Min ${inventoryRisk.minStock.toStringAsFixed(0)})'
        : 'Belirgin risk yok';

    final cards = [
      _QuickInfoCard(
        title: 'Tahmini Satış (Gelecek Ay)',
        subtitle: nextSales,
        icon: Icons.trending_up_outlined,
        color: Colors.indigo,
      ),
      _QuickInfoCard(
        title: 'Stok Riski Yüksek Ürün',
        subtitle: highRiskText,
        icon: Icons.inventory_2_outlined,
        color: Colors.deepOrange,
      ),
      _QuickInfoCard(
        title: 'Üretim Yükü Tahmini',
        subtitle:
            '${result.productionForecast.forecast.isNotEmpty ? result.productionForecast.forecast.first.value.toStringAsFixed(1) : '—'} emir',
        icon: Icons.precision_manufacturing_outlined,
        color: Colors.teal,
      ),
    ];

    if (isPhone) {
      return Column(
        children: cards
            .map(
              (card) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: card,
              ),
            )
            .toList(growable: false),
      );
    }

    return Row(
      children: cards
          .map(
            (card) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: card,
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildSalesForecastChart(SalesForecast forecast) {
    if (forecast.history.isEmpty) {
      return const _ChartPlaceholder(
        message: 'Yeterli satış verisi bulunamadı.',
      );
    }

    final labels = [
      ...forecast.history,
      ...forecast.forecast,
    ].map((point) => _monthFormat.format(point.period)).toList(growable: false);

    final historySpots = <FlSpot>[];
    final forecastSpots = <FlSpot>[];

    for (var i = 0; i < forecast.history.length; i++) {
      historySpots.add(FlSpot(i.toDouble(), forecast.history[i].value));
    }
    for (var i = 0; i < forecast.forecast.length; i++) {
      final x = (forecast.history.length + i).toDouble();
      final point = forecast.forecast[i];
      forecastSpots.add(FlSpot(x, point.value));
    }

    return _ForecastChart(
      labels: labels,
      historySpots: historySpots,
      forecastSpots: forecastSpots,
      intervals: forecast.intervals,
      valueSuffix: ' ₺',
    );
  }

  Widget _buildProductionForecastChart(ProductionForecast forecast) {
    if (forecast.history.isEmpty) {
      return const _ChartPlaceholder(
        message: 'Yeterli üretim verisi bulunamadı.',
      );
    }

    final labels = [
      ...forecast.history,
      ...forecast.forecast,
    ].map((point) => _monthFormat.format(point.period)).toList(growable: false);

    final historySpots = <FlSpot>[];
    final forecastSpots = <FlSpot>[];

    for (var i = 0; i < forecast.history.length; i++) {
      historySpots.add(FlSpot(i.toDouble(), forecast.history[i].value));
    }

    for (var i = 0; i < forecast.forecast.length; i++) {
      final x = (forecast.history.length + i).toDouble();
      final point = forecast.forecast[i];
      forecastSpots.add(FlSpot(x, point.value));
    }

    return _ForecastChart(
      labels: labels,
      historySpots: historySpots,
      forecastSpots: forecastSpots,
      intervals: forecast.intervals,
      valueSuffix: ' emir',
    );
  }
}

class _QuickInfoCard extends StatelessWidget {
  const _QuickInfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForecastChart extends StatelessWidget {
  const _ForecastChart({
    required this.labels,
    required this.historySpots,
    required this.forecastSpots,
    required this.intervals,
    this.valueSuffix = '',
  });

  final List<String> labels;
  final List<FlSpot> historySpots;
  final List<FlSpot> forecastSpots;
  final List<ForecastInterval> intervals;
  final String valueSuffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalLength = labels.length;

    final bars = <LineChartBarData>[
      LineChartBarData(
        spots: historySpots,
        isCurved: true,
        color: Colors.indigo,
        barWidth: 3,
        dotData: const FlDotData(show: false),
      ),
      LineChartBarData(
        spots: forecastSpots,
        isCurved: true,
        color: Colors.indigoAccent,
        barWidth: 3,
        dashArray: const [6, 4],
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(
          show: true,
          color: Colors.indigoAccent.withValues(alpha: 0.08),
        ),
      ),
    ];
    if (intervals.isNotEmpty && forecastSpots.isNotEmpty) {
      final upperLine = LineChartBarData(
        spots: List<FlSpot>.generate(forecastSpots.length, (index) {
          final spot = forecastSpots[index];
          final interval = intervals.length > index
              ? intervals[index]
              : ForecastInterval(lower: spot.y * 0.9, upper: spot.y * 1.1);
          return FlSpot(spot.x, interval.upper);
        }),
        isCurved: true,
        color: Colors.indigo.withValues(alpha: 0.3),
        barWidth: 1.5,
        dashArray: const [4, 4],
        dotData: const FlDotData(show: false),
      );
      final lowerLine = LineChartBarData(
        spots: List<FlSpot>.generate(forecastSpots.length, (index) {
          final spot = forecastSpots[index];
          final interval = intervals.length > index
              ? intervals[index]
              : ForecastInterval(lower: spot.y * 0.9, upper: spot.y * 1.1);
          return FlSpot(spot.x, interval.lower);
        }),
        isCurved: true,
        color: Colors.indigo.withValues(alpha: 0.3),
        barWidth: 1.5,
        dashArray: const [4, 4],
        dotData: const FlDotData(show: false),
      );
      bars.add(lowerLine);
      bars.add(upperLine);
    }

    return SizedBox(
      height: 280,
      child: LineChart(
        LineChartData(
          minY: 0,
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              strokeWidth: 1,
            ),
            drawVerticalLine: false,
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, _) => Text(
                  value.toStringAsFixed(0) + valueSuffix,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= totalLength) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[index],
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  final label = index >= 0 && index < labels.length
                      ? labels[index]
                      : '';
                  return LineTooltipItem(
                    '$label\n${spot.y.toStringAsFixed(1)}$valueSuffix',
                    theme.textTheme.bodyMedium ??
                        const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: bars,
        ),
      ),
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Center(
        child: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
        ),
      ),
    );
  }
}
