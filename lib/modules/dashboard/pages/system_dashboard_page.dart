import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atgevosystem/modules/crm/pages/crm_dashboard_page.dart';
import 'package:atgevosystem/modules/dashboard/services/system_dashboard_service.dart';
import 'package:atgevosystem/modules/dashboard/widgets/activity_log_list.dart';
import 'package:atgevosystem/modules/dashboard/widgets/kpi_card.dart';
import 'package:atgevosystem/modules/dashboard/widgets/line_chart_widget.dart';
import 'package:atgevosystem/modules/dashboard/widgets/pie_chart_widget.dart';
import 'package:atgevosystem/modules/finance/pages/finance_dashboard_page.dart';
import 'package:atgevosystem/modules/production/pages/production_dashboard_page.dart';
import 'package:atgevosystem/modules/purchasing/pages/purchasing_dashboard_page.dart';
import 'package:atgevosystem/services/auth_service.dart';

class SystemDashboardPage extends StatefulWidget {
  const SystemDashboardPage({super.key});

  static const routeName = '/dashboard/system';

  @override
  State<SystemDashboardPage> createState() => _SystemDashboardPageState();
}

class _SystemDashboardPageState extends State<SystemDashboardPage> {
  static const Duration _cacheDuration = Duration(minutes: 5);

  final SystemDashboardService _service = SystemDashboardService.instance;

  DashboardFilter _filter = const DashboardFilter();
  Future<DashboardSnapshot>? _dashboardFuture;
  DashboardSnapshot? _latestSnapshot;

  Timer? _refreshTimer;
  bool _companiesLoading = false;
  List<_CompanyOption> _companyOptions = const [];

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadData();
    _loadCompanies();
    _scheduleAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _scheduleAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_cacheDuration, (_) {
      _refreshData(forceRemote: true, silent: true);
    });
  }

  Future<DashboardSnapshot> _loadData({bool forceRemote = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _cacheKeyForFilter(_filter);

    if (!forceRemote) {
      final cached = _readSnapshotFromCache(prefs, cacheKey);
      if (cached != null) {
        final isFresh =
            DateTime.now().difference(cached.generatedAt) <= _cacheDuration;
        if (isFresh) {
          _latestSnapshot = cached;
          return cached;
        }
      }
    }

    final snapshot = await _service.getDashboardSnapshot(_filter);
    await _writeSnapshotToCache(prefs, cacheKey, snapshot);
    _latestSnapshot = snapshot;
    return snapshot;
  }

  Future<void> _refreshData({
    bool forceRemote = false,
    bool silent = false,
  }) async {
    final future = _loadData(forceRemote: forceRemote);
    if (!silent) {
      setState(() {
        _dashboardFuture = future;
      });
    } else {
      _dashboardFuture = future;
      setState(() {});
    }
    await future;
  }

  Future<void> _loadCompanies() async {
    setState(() {
      _companiesLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('companies')
          .orderBy('company_name')
          .get();
      final options = snapshot.docs
          .map(
            (doc) => _CompanyOption(
              id: doc.id,
              name:
                  (doc.data()['company_name'] as String? ??
                          doc.data()['name'] as String? ??
                          'İsimsiz Firma')
                      .trim(),
            ),
          )
          .toList(growable: false);
      setState(() {
        _companyOptions = options;
        _companiesLoading = false;
      });
    } catch (_) {
      setState(() {
        _companiesLoading = false;
      });
    }
  }

  String _cacheKeyForFilter(DashboardFilter filter) {
    final companyPart = filter.companyId == null || filter.companyId!.isEmpty
        ? 'all'
        : filter.companyId;
    return 'system_dashboard_${filter.range.name}_$companyPart';
  }

  DashboardSnapshot? _readSnapshotFromCache(
    SharedPreferences prefs,
    String key,
  ) {
    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return DashboardSnapshot.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeSnapshotToCache(
    SharedPreferences prefs,
    String key,
    DashboardSnapshot snapshot,
  ) async {
    await prefs.setString(key, jsonEncode(snapshot.toJson()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Genel Sistem Panosu'),
        actions: [
          if ((_latestSnapshot?.lowStockAlerts ?? 0) > 0)
            _buildAlertsAction(context, _latestSnapshot!.lowStockAlerts),
          IconButton(
            onPressed: _latestSnapshot == null
                ? null
                : () => _exportAsPdf(context),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Raporu PDF olarak indir',
          ),
        ],
      ),
      body: FutureBuilder<DashboardSnapshot>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error);
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('Dashboard verileri bulunamadı.'));
          }

          _latestSnapshot = data;

          return RefreshIndicator(
            onRefresh: () => _refreshData(forceRemote: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterRow(),
                  const SizedBox(height: 24),
                  _buildKpiSection(context, data),
                  const SizedBox(height: 24),
                  _buildChartsSection(context, data),
                  const SizedBox(height: 24),
                  _buildLogsSection(context),
                  const SizedBox(height: 24),
                  _buildQuickAccessSection(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Dashboard verileri yüklenirken hata oluştu.\n$error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _refreshData(forceRemote: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    final theme = Theme.of(context);

    Widget buildRangeDropdown() {
      return DropdownButton<DashboardRange>(
        value: _filter.range,
        icon: const Icon(Icons.arrow_drop_down),
        underline: const SizedBox.shrink(),
        onChanged: (value) {
          if (value == null || value == _filter.range) return;
          setState(() {
            _filter = _filter.copyWith(range: value);
          });
          _scheduleAutoRefresh();
          _refreshData();
        },
        items: DashboardRange.values
            .map(
              (range) => DropdownMenuItem(
                value: range,
                child: Text(_rangeLabel(range)),
              ),
            )
            .toList(growable: false),
      );
    }

    Widget buildCompanyDropdown() {
      if (_companiesLoading) {
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      }

      final items = <DropdownMenuItem<String?>>[
        const DropdownMenuItem(value: null, child: Text('Tüm Firmalar')),
        ..._companyOptions.map(
          (option) =>
              DropdownMenuItem(value: option.id, child: Text(option.name)),
        ),
      ];

      return DropdownButton<String?>(
        value: _filter.companyId,
        icon: const Icon(Icons.arrow_drop_down),
        underline: const SizedBox.shrink(),
        onChanged: (value) {
          if (value == _filter.companyId) return;
          setState(() {
            _filter = _filter.copyWith(companyId: value);
          });
          _scheduleAutoRefresh();
          _refreshData();
        },
        items: items,
      );
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Wrap(
          spacing: 24,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Zaman Aralığı',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                buildRangeDropdown(),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.domain_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Firma',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                buildCompanyDropdown(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiSection(BuildContext context, DashboardSnapshot snapshot) {
    final summary = snapshot.summary;
    final role = AuthService.instance.currentUserRole?.toLowerCase();
    final visibleTypes = _visibleKpiTypesForRole(role);
    final configs = _buildKpiConfigs(summary)
        .where((config) => visibleTypes.contains(config.type))
        .toList(growable: false);

    if (configs.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Bu rol için gösterilecek KPI bulunmuyor.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final columns = maxWidth >= 1080
            ? 3
            : maxWidth >= 720
            ? 2
            : 1;
        final itemWidth = (maxWidth - (columns - 1) * 16) / columns;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: configs
              .map(
                (config) => SizedBox(
                  width: itemWidth,
                  child: KpiCard(
                    title: config.title,
                    value: config.value,
                    icon: config.icon,
                    color: config.color,
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildChartsSection(BuildContext context, DashboardSnapshot data) {
    final role = AuthService.instance.currentUserRole?.toLowerCase();
    final visibleTypes = _visibleKpiTypesForRole(role);

    final showFinanceCharts = visibleTypes.intersection({
      _KpiType.outstandingInvoices,
      _KpiType.salesTotal,
    }).isNotEmpty;
    final showOperationalCharts = visibleTypes.intersection({
      _KpiType.quotes,
      _KpiType.productionOrders,
      _KpiType.shipments,
    }).isNotEmpty;

    final cards = <Widget>[];

    if (showFinanceCharts) {
      final series = data.series;
      final labels = series.map((point) => point.label).toList(growable: false);
      final salesValues = series
          .map((point) => point.sales)
          .toList(growable: false);
      final paymentValues = series
          .map((point) => point.collection)
          .toList(growable: false);

      cards.add(
        _DashboardCard(
          title: 'Satış & Tahsilat (${_rangeLabel(_filter.range)})',
          child: DashboardLineChart(
            salesData: salesValues,
            paymentData: paymentValues,
            labels: labels,
            height: 280,
          ),
        ),
      );
    }

    if (showOperationalCharts) {
      final summary = data.summary;
      final workloadData = <String, double>{};
      if (visibleTypes.contains(_KpiType.quotes)) {
        workloadData['Teklifler'] =
            (summary['openQuotes'] as num?)?.toDouble() ?? 0;
      }
      if (visibleTypes.contains(_KpiType.productionOrders)) {
        workloadData['Üretim'] =
            (summary['activeProductionOrders'] as num?)?.toDouble() ?? 0;
      }
      if (visibleTypes.contains(_KpiType.shipments)) {
        workloadData['Sevkiyat'] =
            (summary['pendingShipments'] as num?)?.toDouble() ?? 0;
      }

      if (workloadData.values.any((value) => value > 0)) {
        cards.add(
          _DashboardCard(
            title: 'Departman Bazlı İş Yükü',
            child: DashboardPieChart(data: workloadData, height: 240),
          ),
        );
      }
    }

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final isWide = maxWidth >= 1100;
        final cardWidth = isWide ? maxWidth / 2 - 12 : maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards
              .map((card) => SizedBox(width: cardWidth, child: card))
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildLogsSection(BuildContext context) {
    return const _DashboardCard(
      title: 'Son 10 İşlem',
      child: ActivityLogList(limit: 10),
    );
  }

  Widget _buildQuickAccessSection(BuildContext context) {
    final role = AuthService.instance.currentUserRole?.toLowerCase();
    final entries = _quickAccessConfigs
        .where(
          (config) =>
              role != null && config.allowedRoles.contains(role.toLowerCase()),
        )
        .toList(growable: false);

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return _DashboardCard(
      title: 'Hızlı Erişim',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: entries
            .map(
              (config) => _QuickAccessButton(
                label: config.label,
                icon: config.icon,
                color: config.color,
                onTap: () => Navigator.of(context).pushNamed(config.routeName),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Set<_KpiType> _visibleKpiTypesForRole(String? role) {
    switch (role) {
      case 'sales':
        return {_KpiType.customers, _KpiType.quotes};
      case 'production':
        return {
          _KpiType.productionOrders,
          _KpiType.shipments,
          _KpiType.inventoryValue,
        };
      case 'accounting':
        return {_KpiType.outstandingInvoices, _KpiType.salesTotal};
      case 'superadmin':
        return _allKpiTypes;
      default:
        return _allKpiTypes;
    }
  }

  List<_KpiConfig> _buildKpiConfigs(Map<String, dynamic> summary) {
    final numberFormatter = NumberFormat.decimalPattern('tr_TR');
    final currencyFormatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 0,
    );

    return [
      _KpiConfig(
        type: _KpiType.customers,
        title: 'Toplam Müşteri',
        value: numberFormatter.format(summary['totalCustomers'] ?? 0),
        icon: Icons.people_outline,
        color: Colors.indigo,
      ),
      _KpiConfig(
        type: _KpiType.quotes,
        title: 'Açık Teklif',
        value: numberFormatter.format(summary['openQuotes'] ?? 0),
        icon: Icons.assignment_outlined,
        color: Colors.blue,
      ),
      _KpiConfig(
        type: _KpiType.productionOrders,
        title: 'Aktif Üretim Emri',
        value: numberFormatter.format(summary['activeProductionOrders'] ?? 0),
        icon: Icons.precision_manufacturing_outlined,
        color: Colors.deepPurple,
      ),
      _KpiConfig(
        type: _KpiType.shipments,
        title: 'Bekleyen Sevkiyat',
        value: numberFormatter.format(summary['pendingShipments'] ?? 0),
        icon: Icons.local_shipping_outlined,
        color: Colors.orange,
      ),
      _KpiConfig(
        type: _KpiType.outstandingInvoices,
        title: 'Tahsil Edilmemiş Fatura',
        value: currencyFormatter.format(
          (summary['outstandingInvoices'] as num?)?.toDouble() ?? 0,
        ),
        icon: Icons.receipt_long_outlined,
        color: Colors.redAccent,
      ),
      _KpiConfig(
        type: _KpiType.inventoryValue,
        title: 'Stok Değeri',
        value: currencyFormatter.format(
          (summary['totalInventoryValue'] as num?)?.toDouble() ?? 0,
        ),
        icon: Icons.inventory_2_outlined,
        color: Colors.teal,
      ),
      _KpiConfig(
        type: _KpiType.salesTotal,
        title: 'Satış Toplamı',
        value: currencyFormatter.format(
          (summary['rangeSalesTotal'] as num?)?.toDouble() ?? 0,
        ),
        icon: Icons.trending_up_outlined,
        color: Colors.green,
      ),
    ];
  }

  String _rangeLabel(DashboardRange range) {
    switch (range) {
      case DashboardRange.last7Days:
        return 'Son 7 gün';
      case DashboardRange.last30Days:
        return 'Son 30 gün';
      case DashboardRange.last6Months:
        return 'Son 6 ay';
    }
  }

  Widget _buildAlertsAction(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          IconButton(
            icon: const Icon(Icons.warning_amber_outlined),
            tooltip: 'Kritik stok uyarıları',
            onPressed: () => _showCriticalInfo(context, count),
          ),
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCriticalInfo(BuildContext context, int count) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kritik Uyarılar'),
        content: Text(
          count > 1
              ? '$count envanter kalemi minimum stok seviyesinin altında.'
              : 'Bir envanter kalemi minimum stok seviyesinin altında.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAsPdf(BuildContext context) async {
    final snapshot = _latestSnapshot;
    if (snapshot == null) return;

    final doc = pw.Document();
    final dateFormatter = DateFormat('dd MMMM yyyy HH:mm', 'tr_TR');
    final numberFormatter = NumberFormat.decimalPattern('tr_TR');
    final currencyFormatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    );
    final role = AuthService.instance.currentUserRole?.toLowerCase();
    final visibleTypes = _visibleKpiTypesForRole(role);
    final kpiConfigs = _buildKpiConfigs(snapshot.summary)
        .where((config) => visibleTypes.contains(config.type))
        .toList(growable: false);

    final companyName = _companyOptions
        .firstWhere(
          (option) => option.id == _filter.companyId,
          orElse: () => _CompanyOption(
            id: '',
            name: _filter.companyId == null ? 'Tüm Firmalar' : 'Belirtilmemiş',
          ),
        )
        .name;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            'Genel Sistem Panosu',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Oluşturulma: ${dateFormatter.format(snapshot.generatedAt)}'),
          pw.Text('Zaman Aralığı: ${_rangeLabel(_filter.range)}'),
          pw.Text('Firma: $companyName'),
          pw.SizedBox(height: 16),
          pw.Text(
            'Özet KPI\'lar',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (kpiConfigs.isEmpty)
            pw.Text('Bu rol için gösterilecek KPI bulunmuyor.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Başlık', 'Değer'],
              data: kpiConfigs
                  .map((config) => [config.title, config.value])
                  .toList(growable: false),
            ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Satış & Tahsilat Trend',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (snapshot.series.isEmpty)
            pw.Text('Veri bulunamadı.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Dönem', 'Satış', 'Tahsilat'],
              data: snapshot.series
                  .map(
                    (point) => [
                      point.label,
                      currencyFormatter.format(point.sales),
                      currencyFormatter.format(point.collection),
                    ],
                  )
                  .toList(growable: false),
            ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Özet Bilgiler',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
            },
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey600),
            children: [
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Toplam Tahsilat'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      currencyFormatter.format(
                        (snapshot.summary['rangeCollectionTotal'] as num?)
                                ?.toDouble() ??
                            0,
                      ),
                    ),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Kritik Stok Adedi'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      numberFormatter.format(snapshot.lowStockAlerts),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }
}

class _CompanyOption {
  const _CompanyOption({required this.id, required this.name});

  final String id;
  final String name;
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

enum _KpiType {
  customers,
  quotes,
  productionOrders,
  shipments,
  outstandingInvoices,
  inventoryValue,
  salesTotal,
}

const Set<_KpiType> _allKpiTypes = {
  _KpiType.customers,
  _KpiType.quotes,
  _KpiType.productionOrders,
  _KpiType.shipments,
  _KpiType.outstandingInvoices,
  _KpiType.inventoryValue,
  _KpiType.salesTotal,
};

class _KpiConfig {
  const _KpiConfig({
    required this.type,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final _KpiType type;
  final String title;
  final String value;
  final IconData icon;
  final Color color;
}

class _QuickAccessConfig {
  const _QuickAccessConfig({
    required this.label,
    required this.icon,
    required this.color,
    required this.routeName,
    required this.allowedRoles,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String routeName;
  final List<String> allowedRoles;
}

const List<_QuickAccessConfig> _quickAccessConfigs = [
  _QuickAccessConfig(
    label: 'CRM',
    icon: Icons.hub_outlined,
    color: Colors.indigo,
    routeName: CrmDashboardPage.routeName,
    allowedRoles: ['admin', 'sales', 'production', 'accounting', 'superadmin'],
  ),
  _QuickAccessConfig(
    label: 'Üretim',
    icon: Icons.precision_manufacturing_outlined,
    color: Colors.deepPurple,
    routeName: ProductionDashboardPage.routeName,
    allowedRoles: ['admin', 'sales', 'production', 'superadmin'],
  ),
  _QuickAccessConfig(
    label: 'Satınalma',
    icon: Icons.shopping_cart_checkout_outlined,
    color: Colors.orange,
    routeName: PurchasingDashboardPage.routeName,
    allowedRoles: ['admin', 'purchasing', 'superadmin'],
  ),
  _QuickAccessConfig(
    label: 'Finans',
    icon: Icons.assessment_outlined,
    color: Colors.green,
    routeName: FinanceDashboardPage.routeName,
    allowedRoles: ['admin', 'accounting', 'superadmin'],
  ),
];

class _QuickAccessButton extends StatelessWidget {
  const _QuickAccessButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      icon: Icon(icon),
      label: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
