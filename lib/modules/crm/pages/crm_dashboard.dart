import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/activity_service.dart';
import '../services/customer_service.dart';
import '../services/lead_service.dart';
import '../services/quote_service.dart';

class CrmDashboardPage extends StatelessWidget {
  const CrmDashboardPage({super.key});

  static const routeName = '/crm/dashboard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRM Dashboard'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _SummarySection(),
              SizedBox(height: 24),
              _MonthlyLeadsChart(),
              SizedBox(height: 24),
              _RecentActivitiesSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.instance.getCustomers(),
      builder: (context, customerSnapshot) {
        if (customerSnapshot.hasError) {
          return _ErrorCard(message: 'Müşteri verileri yüklenemedi.');
        }

        if (customerSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final totalCustomers = customerSnapshot.data?.docs.length ?? 0;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: QuoteService.instance.getQuotes(),
          builder: (context, quoteSnapshot) {
            if (quoteSnapshot.hasError) {
              return _ErrorCard(message: 'Teklif verileri yüklenemedi.');
            }

            if (quoteSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final quotes = quoteSnapshot.data?.docs ?? [];
            final totalQuotes = quotes.length;
            final convertedQuotes = quotes.where((doc) {
              final status =
                  (doc.data()['status'] as String?)?.toLowerCase().trim() ?? '';
              return status == 'approved' ||
                  status == 'accepted' ||
                  status == 'won';
            }).length;
            final conversionRate =
                totalQuotes == 0 ? 0.0 : convertedQuotes / totalQuotes;

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: LeadService.instance.getLeads(),
              builder: (context, leadSnapshot) {
                if (leadSnapshot.hasError) {
                  return _ErrorCard(message: 'Lead verileri yüklenemedi.');
                }

                if (leadSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final totalLeads = leadSnapshot.data?.docs.length ?? 0;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _DashboardCard(
                      title: 'Toplam Müşteri',
                      value: totalCustomers.toString(),
                      icon: Icons.people_alt_outlined,
                      color: Colors.indigo,
                    ),
                    _DashboardCard(
                      title: 'Toplam Teklif',
                      value: totalQuotes.toString(),
                      icon: Icons.description_outlined,
                      color: Colors.teal,
                      subtitle:
                          'Dönüşüm: ${(conversionRate * 100).toStringAsFixed(1)}%',
                    ),
                    _DashboardCard(
                      title: 'Toplam Lead',
                      value: totalLeads.toString(),
                      icon: Icons.trending_up_outlined,
                      color: Colors.deepOrange,
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _MonthlyLeadsChart extends StatelessWidget {
  const _MonthlyLeadsChart();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Aylık Yeni Lead Grafiği',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Son 6 ay',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: LeadService.instance.getLeads(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Grafik verileri yüklenemedi.'),
                    );
                  }

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final now = DateTime.now();
                  final months = List.generate(
                    6,
                    (index) =>
                        DateTime(now.year, now.month - (5 - index), 1),
                  );
                  final monthLabels = months
                      .map((date) => DateFormat('MMM', 'tr_TR').format(date))
                      .toList();

                  final counts = <String, int>{};
                  for (final doc in docs) {
                    final timestamp = doc.data()['created_at'];
                    if (timestamp is! Timestamp) continue;
                    final date = timestamp.toDate();
                    final monthStart = DateTime(date.year, date.month, 1);
                    final key =
                        '${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}';
                    counts[key] = (counts[key] ?? 0) + 1;
                  }

                  final values = months
                      .map(
                        (date) => counts[
                                '${date.year}-${date.month.toString().padLeft(2, '0')}'] ??
                            0,
                      )
                      .toList();

                  final maxValue =
                      values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b).toDouble();
                  if (values.every((element) => element == 0)) {
                    return const Center(
                      child: Text('Henüz lead verisi bulunmuyor.'),
                    );
                  }

                  final barGroups = List.generate(values.length, (index) {
                    final value = values[index].toDouble();
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: value,
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.indigo,
                        ),
                      ],
                    );
                  });

                  return BarChart(
                    BarChartData(
                      barGroups: barGroups,
                      maxY: maxValue == 0 ? 1 : maxValue + 1,
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final label = monthLabels[groupIndex];
                            return BarTooltipItem(
                              '$label\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                TextSpan(
                                  text: rod.toY.toStringAsFixed(0),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            interval: (maxValue / 4).clamp(1, double.infinity),
                            getTitlesWidget: (value, meta) {
                              if (value % 1 != 0) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                value.toStringAsFixed(0),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= monthLabels.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  monthLabels[index],
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivitiesSection extends StatelessWidget {
  const _RecentActivitiesSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Son Aktiviteler',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: ActivityService.instance.recentActivities(limit: 10),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Aktiviteler yüklenemedi.'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Henüz aktivite bulunmuyor.'),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final type = (data['type'] as String?) ?? 'note';
                    final description =
                        (data['description'] as String?) ?? '';
                    final timestamp = data['timestamp'];
                    final userId = (data['user_id'] as String?) ?? '-';

                    DateTime? time;
                    if (timestamp is Timestamp) {
                      time = timestamp.toDate();
                    }
                    final formattedDate = time == null
                        ? 'Tarih yok'
                        : DateFormat('dd.MM.yyyy HH:mm').format(time);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _activityColor(type),
                        child: Icon(
                          _activityIcon(type),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(description.isEmpty
                          ? 'Açıklama yok'
                          : description),
                      subtitle: Text('$formattedDate • Kullanıcı: $userId'),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'call':
        return Icons.call;
      case 'visit':
        return Icons.location_on_outlined;
      case 'mail':
        return Icons.mail_outline;
      default:
        return Icons.notes;
    }
  }

  Color _activityColor(String type) {
    switch (type) {
      case 'call':
        return Colors.green;
      case 'visit':
        return Colors.blue;
      case 'mail':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(icon, color: color),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
