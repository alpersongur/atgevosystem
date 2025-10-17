import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/dashboard_service.dart';
import '../services/module_service.dart';

class SuperadminDashboardPage extends StatefulWidget {
  const SuperadminDashboardPage({super.key});

  static const routeName = '/superadmin/dashboard';

  @override
  State<SuperadminDashboardPage> createState() =>
      _SuperadminDashboardPageState();
}

class _SuperadminDashboardPageState extends State<SuperadminDashboardPage> {
  int _userCount = 0;
  int _moduleCount = 0;
  int _permissionCount = 0;
  Map<String, int> _roleDistribution = {};
  bool _isLoading = true;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _modulesSubscription;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _modules = [];

  @override
  void initState() {
    super.initState();
    _loadKpis();
    _modulesSubscription = ModuleService.instance.getModules().listen((
      snapshot,
    ) {
      setState(() {
        _modules = snapshot.docs;
      });
    });
  }

  @override
  void dispose() {
    _modulesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadKpis() async {
    setState(() => _isLoading = true);
    try {
      final service = DashboardService.instance;
      final results = await Future.wait([
        service.getUserCount(),
        service.getModuleCount(),
        service.getPermissionCount(),
        service.getRoleDistribution(),
      ]);

      setState(() {
        _userCount = results[0] as int;
        _moduleCount = results[1] as int;
        _permissionCount = results[2] as int;
        _roleDistribution = results[3] as Map<String, int>;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Süper Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: _loadKpis,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadKpis,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildKpiRow(context),
                    const SizedBox(height: 24),
                    _buildActionButtons(context),
                    const SizedBox(height: 24),
                    _buildModuleTable(),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildRoleDistributionChart()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildPermissionSummary()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildRecentLogs(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildKpiRow(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _KpiCard(title: 'Toplam Kullanıcı', value: _userCount.toString()),
        _KpiCard(title: 'Aktif Modül', value: _moduleCount.toString()),
        _KpiCard(title: 'İzin Setleri', value: _permissionCount.toString()),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pushNamed('/admin/users'),
          icon: const Icon(Icons.manage_accounts),
          label: const Text('Kullanıcı Yönetimi'),
        ),
        FilledButton.icon(
          onPressed: () =>
              Navigator.of(context).pushNamed('/admin/permissions'),
          icon: const Icon(Icons.security),
          label: const Text('İzinler'),
        ),
        FilledButton.icon(
          onPressed: () =>
              Navigator.of(context).pushNamed('/superadmin/modules'),
          icon: const Icon(Icons.apps),
          label: const Text('Modüller'),
        ),
      ],
    );
  }

  Widget _buildModuleTable() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Modül Aktivasyon Durumu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Modül')),
                  DataColumn(label: Text('Kod')),
                  DataColumn(label: Text('Açıklama')),
                  DataColumn(label: Text('Aktif')),
                ],
                rows: _modules.map((doc) {
                  final data = doc.data();
                  final name = data['name'] as String? ?? 'Adsız';
                  final code = data['code'] as String? ?? '-';
                  final description = data['description'] as String? ?? '';
                  final isActive = data['active'] == true;

                  return DataRow(
                    cells: [
                      DataCell(Text(name)),
                      DataCell(Text(code)),
                      DataCell(Text(description)),
                      DataCell(
                        Switch(
                          value: isActive,
                          onChanged: (value) => ModuleService.instance
                              .updateModuleStatus(doc.id, value),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleDistributionChart() {
    if (_roleDistribution.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Rol dağılımı verisi bulunmuyor.'),
        ),
      );
    }

    final total = _roleDistribution.values.fold<int>(
      0,
      (acc, value) => acc + value,
    );
    int colorIndex = 0;
    final colors = [
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
    ];

    final sections = _roleDistribution.entries.map((entry) {
      final percentage = total == 0 ? 0 : entry.value / total * 100;
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      return PieChartSectionData(
        value: entry.value.toDouble(),
        color: color,
        title: '${entry.key}\n${percentage.toStringAsFixed(1)}%',
        titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rol Dağılımı',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'İzin Matrisi Özeti',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bu bölüm, her modül için rol bazlı izinleri özetlemek üzere geliştirilebilir.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLogs() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: DashboardService.instance.getRecentLogs(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Loglar yüklenirken hata oluştu\n${snapshot.error}'),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Son log kaydı bulunmuyor.'),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Son Loglar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...docs.map((doc) {
                  final data = doc.data();
                  final message =
                      data['message'] as String? ?? 'Log mesajı yok';
                  final timestamp = data['timestamp'];
                  DateTime? time;
                  if (timestamp is Timestamp) {
                    time = timestamp.toDate();
                  }
                  final formatted = time == null
                      ? '---'
                      : '${time.day}.${time.month}.${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(message),
                    subtitle: Text(formatted),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
