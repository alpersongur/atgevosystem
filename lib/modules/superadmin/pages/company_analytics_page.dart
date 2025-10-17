import 'package:flutter/material.dart';

import '../services/company_analytics_service.dart';

class CompanyAnalyticsPage extends StatefulWidget {
  const CompanyAnalyticsPage({super.key});

  static const routeName = '/superadmin/company-analytics';

  @override
  State<CompanyAnalyticsPage> createState() => _CompanyAnalyticsPageState();
}

class _CompanyAnalyticsPageState extends State<CompanyAnalyticsPage> {
  final _service = CompanyAnalyticsService.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _companies = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.getAllCompaniesUsage();
      setState(() => _companies = result);
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
        title: const Text('Şirket Analitikleri'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _companies.isEmpty
          ? const Center(child: Text('Analiz edilecek şirket bulunmuyor.'))
          : Column(
              children: [
                Expanded(child: _buildDataTable(context)),
                _buildSummarySection(),
              ],
            ),
    );
  }

  Widget _buildDataTable(BuildContext context) {
    final columns = <DataColumn>[
      const DataColumn(label: Text('Şirket')),
      const DataColumn(label: Text('Kullanıcılar')),
      const DataColumn(label: Text('Modüller')),
      const DataColumn(label: Text('En Son Güncelleme')),
      const DataColumn(label: Text('Aksiyonlar')),
    ];

    final rows = _companies.map((company) {
      final usage = Map<String, dynamic>.from(company['usage'] as Map? ?? {});
      final users = usage['users'] ?? '-';
      final modules = usage['modules'] ?? '-';
      final lastUpdated = usage['updated_at'] ?? '-';

      return DataRow(
        cells: [
          DataCell(Text(company['name']?.toString() ?? 'Adsız')),
          DataCell(Text(users.toString())),
          DataCell(Text(modules.toString())),
          DataCell(Text(lastUpdated.toString())),
          DataCell(
            TextButton(
              onPressed: () => _openDetailModal(context, company),
              child: const Text('Detay'),
            ),
          ),
        ],
      );
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(columns: columns, rows: rows),
    );
  }

  Widget _buildSummarySection() {
    final totalUsers = _companies.fold<int>(0, (sum, company) {
      final usage = Map<String, dynamic>.from(company['usage'] as Map? ?? {});
      final users = usage['users'] as int? ?? 0;
      return sum + users;
    });

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Genel Özet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text('Toplam Kullanıcı Sayısı: $totalUsers'),
          ],
        ),
      ),
    );
  }

  Future<void> _openDetailModal(
    BuildContext context,
    Map<String, dynamic> company,
  ) async {
    final usage = Map<String, dynamic>.from(company['usage'] as Map? ?? {});
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                company['name']?.toString() ?? 'Şirket',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ...usage.entries.map(
                (entry) => ListTile(
                  title: Text(entry.key.toUpperCase()),
                  trailing: Text(entry.value.toString()),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Kapat'),
              ),
            ],
          ),
        );
      },
    );
  }
}
