import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/responsive.dart';
import '../../monitoring/services/monitoring_service.dart';
import '../widgets/alert_list_widget.dart';
import '../widgets/metric_card.dart';
import '../widgets/trend_chart_widget.dart';

class MonitoringDashboardPage extends StatefulWidget {
  const MonitoringDashboardPage({super.key});

  static const routeName = '/monitoring/dashboard';

  @override
  State<MonitoringDashboardPage> createState() => _MonitoringDashboardPageState();
}

class _MonitoringDashboardPageState extends State<MonitoringDashboardPage> {
  final MonitoringService _service = MonitoringService.instance;
  late Future<_MonitoringData> _future;
  final DateFormat _dayFormat = DateFormat('dd MMM', 'tr_TR');

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_MonitoringData> _loadData() async {
    final metrics = await _service.fetchRealtimeMetrics();
    final snapshots = await _service.fetchDailySnapshots(days: 7);
    return _MonitoringData(metrics: metrics, snapshots: snapshots);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistem Sağlığı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _future = _loadData();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<_MonitoringData>(
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
                  'Sistem metrikleri alınırken hata oluştu.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('Metrik verisi bulunamadı.'));
          }

          final device = ResponsiveBreakpoints.of(context);
          final isPhone = device == DeviceSize.phone;
          final alerts = _buildAlerts(data.metrics);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Özet Metrikler',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                _buildMetricGrid(data.metrics, isPhone),
                const SizedBox(height: 32),
                Text(
                  'Trendler',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                _buildTrendSection(data.snapshots, isPhone),
                const SizedBox(height: 32),
                Text(
                  'Uyarılar',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: AlertListWidget(alerts: alerts),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Son Hata Kayıtları',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Card(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _service.watchRecentErrors(limit: 10),
                    builder: (context, logSnapshot) {
                      if (logSnapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 120,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final logs = logSnapshot.data ?? const [];
                      if (logs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Son 24 saatte hata kaydı bulunmuyor.'),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: logs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          final message = log['message'] as String? ?? 'Hata';
                          final module = log['module'] as String? ?? 'sistem';
                          final timestamp = log['timestamp'];
                          final date = timestamp is Timestamp
                              ? timestamp.toDate()
                              : DateTime.tryParse(timestamp?.toString() ?? '');
                          final dateLabel =
                              date != null ? DateFormat('dd MMM HH:mm', 'tr_TR').format(date) : '-';
                          return ListTile(
                            leading: const Icon(Icons.error_outline, color: Colors.redAccent),
                            title: Text(message),
                            subtitle: Text('$module • $dateLabel'),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricGrid(MonitoringRealtimeMetrics metrics, bool isPhone) {
    final cards = [
      MetricCard(
        title: 'Günlük Firestore İşlemleri',
        value:
            '${(metrics.firestoreReads + metrics.firestoreWrites + metrics.firestoreDeletes).toStringAsFixed(0)} işlem',
        icon: Icons.storage_outlined,
        threshold: 80000,
        warningValue: metrics.firestoreReads + metrics.firestoreWrites,
      ),
      MetricCard(
        title: 'Cloud Function Hata Sayısı',
        value: metrics.functionsErrors.toStringAsFixed(0),
        icon: Icons.bug_report_outlined,
        threshold: 50,
        warningValue: metrics.functionsErrors,
      ),
      MetricCard(
        title: 'Storage Kullanımı',
        value: '${metrics.storageMb.toStringAsFixed(1)} MB',
        icon: Icons.cloud_outlined,
        threshold: 8000,
        warningValue: metrics.storageMb,
      ),
      MetricCard(
        title: 'Aktif Kullanıcılar',
        value: metrics.activeUsers.toStringAsFixed(0),
        icon: Icons.people_alt_outlined,
      ),
      MetricCard(
        title: 'Son Deploy Durumu',
        value: metrics.hostingStatus,
        icon: Icons.cloud_done_outlined,
      ),
    ];

    if (isPhone) {
      return Column(
        children: cards
            .map((card) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: card,
                ))
            .toList(),
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: cards
          .map(
            (card) => SizedBox(
              width: 240,
              child: card,
            ),
          )
          .toList(),
    );
  }

  Widget _buildTrendSection(List<MonitoringSnapshot> snapshots, bool isPhone) {
    if (snapshots.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Son 7 gün için trend verisi bulunamadı.'),
        ),
      );
    }

    final labels = snapshots
        .map((snapshot) {
          final date = snapshot.timestamp ?? DateTime.now();
          return _dayFormat.format(date);
        })
        .toList(growable: false);

    final readSpots = <FlSpot>[];
    final writeSpots = <FlSpot>[];
    final errorBars = <BarChartGroupData>[];

    for (var i = 0; i < snapshots.length; i++) {
      final snap = snapshots[i];
      readSpots.add(FlSpot(i.toDouble(), snap.reads));
      writeSpots.add(FlSpot(i.toDouble(), snap.writes));
      errorBars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: snap.errors,
              color: Colors.redAccent,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Firestore Reads',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TrendChartWidget.line(
                  labels: labels,
                  series: readSpots,
                  valueSuffix: '',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Firestore Writes',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TrendChartWidget.line(
                  labels: labels,
                  series: writeSpots,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Function Hata Trendleri',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TrendChartWidget.bar(
                  labels: labels,
                  barGroups: errorBars,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<AlertItem> _buildAlerts(MonitoringRealtimeMetrics metrics) {
    const firestoreThreshold = 100000.0; // örnek değer
    const storageThreshold = 10240.0; // ~10 GB

    final alerts = <AlertItem>[];

    final usage = metrics.firestoreReads + metrics.firestoreWrites;
    if (usage >= firestoreThreshold * 0.8) {
      alerts.add(
        const AlertItem(
          title: 'Firestore kullanımına dikkat',
          message: 'Günlük read/write sayısı %80 eşiğini geçti.',
          severity: AlertSeverity.warning,
        ),
      );
    }

    if (metrics.storageMb >= storageThreshold * 0.8) {
      alerts.add(
        AlertItem(
          title: 'Depolama kullanım uyarısı',
          message:
              'Storage kullanımı ${metrics.storageMb.toStringAsFixed(0)} MB seviyesine ulaştı.',
          severity: AlertSeverity.warning,
        ),
      );
    }

    if (metrics.functionsErrors >= 50) {
      alerts.add(
        const AlertItem(
          title: 'Fonksiyon hata artışı',
          message: 'Son ölçümde 50+ hata kaydedildi.',
          severity: AlertSeverity.critical,
        ),
      );
    }

    if (alerts.isEmpty) {
      alerts.add(
        const AlertItem(
          title: 'Sistem normal',
          message: 'Şu an için kritik uyarı bulunmuyor.',
          severity: AlertSeverity.info,
        ),
      );
    }

    return alerts;
  }
}

class _MonitoringData {
  const _MonitoringData({
    required this.metrics,
    required this.snapshots,
  });

  final MonitoringRealtimeMetrics metrics;
  final List<MonitoringSnapshot> snapshots;
}
